"""核对 96×96 INT8 转换金样，只依赖 numpy。

    python3 check_int8_96.py                                   用本程序自己的算法重算 int8/ 下全部张量，逐字节比对
    python3 check_int8_96.py 仓库/tools/rgb565_to_int8_reference.py   另把 inputs/ 下每张小图交给该程序转换，与 int8/ 逐字节比对
    python3 check_int8_96.py --dut 目录                          比对硬件或仿真导出的结果：目录下放 名字_96_int8.bin（36,864 字节），有几张比几张

打印 PASS 或 FAIL；不一致时列出第一处不同的字节位置（字节号、像素行列、通道）。
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
N = 96


def convert(small):
    px = np.frombuffer(small, "<u2").astype(np.uint16)
    r5, g6, b5 = px >> 11, (px >> 5) & 63, px & 31
    out = np.zeros((px.size, 4), np.uint8)
    out[:, 0] = (((r5 << 3) | (r5 >> 2)) - 128) & 0xFF
    out[:, 1] = (((g6 << 2) | (g6 >> 4)) - 128) & 0xFF
    out[:, 2] = (((b5 << 3) | (b5 >> 2)) - 128) & 0xFF
    return out.tobytes()


def hex_beats(b):
    return [b[i:i + 32][::-1].hex() for i in range(0, len(b), 32)]


def first_diff(a, b):
    if len(a) != len(b):
        return f"长度 {len(a)} 与 {len(b)} 不同"
    k = int(np.flatnonzero(np.frombuffer(a, np.uint8) != np.frombuffer(b, np.uint8))[0])
    return f"第 {k} 字节（第 {k // 4 // N} 行第 {k // 4 % N} 列，通道 {'RGB0'[k % 4]}）：期望 0x{b[k]:02X}，得到 0x{a[k]:02X}"


def main():
    args = sys.argv[1:]
    names = sorted(p.name[:-len("_96.bin")] for p in (HERE / "inputs").glob("*_96.bin"))
    bad, n = [], 0
    if args and args[0] == "--dut":
        d = Path(args[1])
        for name in names:
            f = d / f"{name}_96_int8.bin"
            if f.exists():
                n += 1
                want = (HERE / "int8" / f"{name}_96_int8.bin").read_bytes()
                got = f.read_bytes()
                if got != want:
                    bad.append(f"{name}：{first_diff(got, want)}")
    else:
        tool = Path(args[0]) if args else None
        for name in names:
            n += 1
            small = (HERE / "inputs" / f"{name}_96.bin").read_bytes()
            want = (HERE / "int8" / f"{name}_96_int8.bin").read_bytes()
            if len(small) != N * N * 2 or hex_beats(small) != (HERE / "inputs" / f"{name}_96.hex").read_text().split():
                bad.append(f"{name}：小图 .bin 与 .hex 不一致")
            if hex_beats(want) != (HERE / "int8" / f"{name}_96_int8.hex").read_text().split():
                bad.append(f"{name}：张量 .bin 与 .hex 不一致")
            got = convert(small)
            if got != want:
                bad.append(f"{name}（本程序）：{first_diff(got, want)}")
            if tool:
                with tempfile.TemporaryDirectory() as t:
                    o = Path(t) / "out.int8"
                    r = subprocess.run([sys.executable, str(tool), str(HERE / "inputs" / f"{name}_96.bin"), str(o)], capture_output=True, text=True)
                    got = o.read_bytes() if r.returncode == 0 and o.exists() else b""
                if got != want:
                    bad.append(f"{name}（{tool.name}）：{first_diff(got, want) if got else '运行失败 ' + r.stderr.strip()[-200:]}")
    for b in bad:
        print("不一致：", b)
    ok = n > 0 and not bad
    print(f"核对 {n} 张，{len(bad)} 处不一致：{'PASS' if ok else 'FAIL'}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
