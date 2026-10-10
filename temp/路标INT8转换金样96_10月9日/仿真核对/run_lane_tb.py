"""跑 tb_int8_lane.sv（zzx 的 Hrgb565_int8_lane 行为仿真）并逐项核对：
每张交付图像的 36,864 字节与金样逐字节比对；描述符各字段；位置分配和代次；归还（含 3 条非法归还）；
RGB565 bank 归还；空批次、非法批次、读错误注入后的处理；结束时各计数器。
    python3 run_lane_tb.py 仓库目录          （要 iverilog；仓库目录下要有 soc/Hrgb565_int8_lane.v 和 soc/soc_addr_map.vh）
运行时在本目录生成 in_b*.hex、tb_load.vh、tb.vvp、tb.log 和 out_b*.hex（交付的各张图像），打印 PASS 或 FAIL。"""
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PKG = HERE.parent
if len(sys.argv) < 2:
    sys.exit(__doc__)
REPO = Path(sys.argv[1])
golden = sorted(p.name[:-len("_96.bin")] for p in (PKG / "inputs").glob("frame_*_96.bin"))
BATCH = {   # 批号: (frame, bank, count, 小图名)
    1: (0x11, 0, 8, [f"e{k:02d}_allvalues" for k in range(1, 9)]),
    2: (0x22, 1, 8, golden[:8]),
    3: (0x33, 0, 0, []),
    4: (0x44, 1, 9, []),
    5: (0x55, 0, 3, ["c01_black", "c02_white", "c03_checker"]),
    6: (0x66, 1, 2, ["c04_color_bars", "c05_L1_max"]),
}
BANK_IDX = {0: 0, 1: 32768}         # 两个 bank 在读模型里的拍号起点（相差 1 MiB）

lines = ["task load_batch(input integer b);", "    begin", "        case (b)"]
for b, (_, bank, _, names) in BATCH.items():
    if not names:
        continue
    lines.append(f"            {b}: begin")
    for i, n in enumerate(names):
        src = PKG / "inputs" / f"{n}_96.hex"
        dst = HERE / f"in_b{b}_{i}.hex"
        dst.write_text(src.read_text())
        st = BANK_IDX[bank] + i * 1024
        lines.append(f'                $readmemh("{dst.name}", rmem, {st}, {st + 575});')
    lines.append("            end")
lines += ["            default: ;", "        endcase", "    end", "endtask", ""]
(HERE / "tb_load.vh").write_text("\n".join(lines))
for f in HERE.glob("out_b*.hex"):
    f.unlink()

subprocess.run(["iverilog", "-g2012", "-I", str(REPO / "soc"), "-o", str(HERE / "tb.vvp"),
                str(HERE / "tb_int8_lane.sv"), str(REPO / "soc" / "Hrgb565_int8_lane.v")], check=True, cwd=HERE)
subprocess.run(["vvp", "-n", "tb.vvp"], check=True, cwd=HERE, stdout=subprocess.DEVNULL)

log = (HERE / "tb.log").read_text().splitlines()
kv = lambda s: dict(re.findall(r"(\w+)=([0-9a-fA-FxX]+)", s))
bad = []
imgs = [kv(l) for l in log if l.startswith("IMG")]
rels = [kv(l) for l in log if l.startswith("REL")]
roirel = [kv(l) for l in log if l.startswith("ROIREL")]
stats = [kv(l) for l in log if l.startswith("STATS")]
bad += [l for l in log if l.startswith(("PROTO", "TIMEOUT"))]

# 位置分配模型：接收描述符时按位置号从小到大取空闲位置，每取一次代次加 1；交付后要正确归还才空出来
state, gen = [0] * 56, [0] * 56
alloc = {}
def allocate(b):
    _, _, n, _ = BATCH[b]
    free = [j for j in range(56) if state[j] == 0][:n]
    for j in free:
        state[j] = 1
        gen[j] += 1
    alloc[b] = [(j, gen[j]) for j in free]

def block_base(j):
    return 0xB880_0000 + (j // 14) * 0x8_0000 + (j % 14) * 36864

allocate(1)
for k in range(8):
    if k != 3:
        state[alloc[1][k][0]] = 0
allocate(2)
allocate(5)
allocate(6)

delivered = 0
for b, (frame, bank, n, names) in BATCH.items():
    got = [d for d in imgs if int(d["batch"]) == b]
    want_n = 1 if b == 6 else (n if n <= 8 else 0)
    if len(got) != want_n:
        bad.append(f"批 {b}：交付 {len(got)} 张，应为 {want_n}")
    for i, d in enumerate(got):
        j, g = alloc[b][i]
        exp = dict(frame=frame, index=i, count=n, camera=1, block=j // 14, position=j % 14, gen=g,
                   addr=block_base(j), w=96, h=96, bytes=36864)
        for key, v in exp.items():
            if int(d[key], 16 if key in ("frame", "addr") else 10) != v:
                bad.append(f"批 {b} 第 {i} 张 {key}={d[key]}，应为 {v:#x}" if key in ("frame", "addr") else f"批 {b} 第 {i} 张 {key}={d[key]}，应为 {v}")
        if d["box"].lower() != d["expbox"].lower() or d["color"] != d["expcolor"]:
            bad.append(f"批 {b} 第 {i} 张 box/color 与描述符不符")
        hx = [l.strip() for l in (HERE / f"out_b{b}_{i}.hex").read_text().splitlines() if l.strip() and not l.startswith("//")]
        data = b"".join(bytes.fromhex(x.rjust(64, "0"))[::-1] for x in hx)
        want = (PKG / "int8" / f"{names[i]}_96_int8.bin").read_bytes()
        if data != want:
            k = next((t for t in range(min(len(data), len(want))) if data[t] != want[t]), min(len(data), len(want)))
            bad.append(f"批 {b} 第 {i} 张（{names[i]}）数据不符：长度 {len(data)}，第一处不同在第 {k} 字节")
        delivered += 1

# RGB565 bank 归还：每批一次，bank、frame 对
for b, (frame, bank, n, _) in BATCH.items():
    r = [d for d in roirel if int(d["frame"], 16) == frame]
    if len(r) != 1 or int(r[0]["bank"]) != bank:
        bad.append(f"批 {b}：RGB565 bank 归还 {len(r)} 次（应 1 次，bank {bank}）")

s = stats[-1]
exp_final = dict(images_done=20, ddr_err=1, bad_release=3, failed=2, last_fail_frame=0x66, last_fail_index=1,
                 last_fail_cause=2, error=1, busy=0, protocol_errors=0,
                 used=sum(1 for x in state if x), peak=14)
state_after = state[:]
# 批 6 第 2 张失败后位置收回
state_after[alloc[6][1][0]] = 0
exp_final["used"] = sum(1 for x in state_after if x)
for key, v in exp_final.items():
    if int(s[key], 16 if key == "last_fail_frame" else 10) != v:
        bad.append(f"结束时 {key}={s[key]}，应为 {v}")
if int(stats[1]["bad_release"]) != 3 or int(stats[1]["used"]) != 1:
    bad.append(f"归还之后 bad_release={stats[1]['bad_release']} used={stats[1]['used']}，应为 3 和 1")

for x in bad:
    print("不一致：", x)
print(f"交付 {delivered} 张、逐字节比对 {delivered} 张；{len(bad)} 处不一致：{'PASS' if not bad else 'FAIL'}")
print(log[-2])
sys.exit(1 if bad else 0)
