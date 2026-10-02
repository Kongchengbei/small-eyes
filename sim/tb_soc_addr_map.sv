`timescale 1ns / 1ps
`include "soc_addr_map.vh"

// 地址映射的静态回归。它不实例化 SoC，只检查映射段没有重叠、没有越界，
// 使后续添加 NPU RTL 时能够尽早发现地址常量被误改。
module tb_soc_addr_map;
    task check_equal;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (actual !== expected)
                $fatal(1, "%0s: actual=%08x expected=%08x", name, actual, expected);
        end
    endtask

    initial begin
        // DDR 全区恰好由普通 CPU 区和 NPU 共享区首尾相接地覆盖。
        check_equal(`SOC_DDR_BASE + `SOC_DDR_BYTES, `SOC_DDR_END, "DDR end");
        check_equal(`SOC_CPU_CACHED_DDR_BASE, `SOC_DDR_BASE, "CPU DDR base");
        check_equal(`SOC_CPU_CACHED_DDR_BASE + `SOC_CPU_CACHED_DDR_BYTES,
                    `SOC_CPU_CACHED_DDR_END, "CPU DDR end");
        check_equal(`SOC_CPU_CACHED_DDR_END, `SOC_NPU_SHARED_BASE,
                    "CPU/NPU boundary");
        check_equal(`SOC_NPU_SHARED_BASE + `SOC_NPU_SHARED_BYTES,
                    `SOC_NPU_SHARED_END, "NPU shared end");
        check_equal(`SOC_NPU_SHARED_END, `SOC_DDR_END, "NPU/DDR boundary");

        // NPU 的四类缓冲区连续且不重叠。
        check_equal(`SOC_NPU_INPUT_BASE, `SOC_NPU_SHARED_BASE, "NPU input base");
        check_equal(`SOC_NPU_INPUT_BASE + `SOC_NPU_INPUT_BYTES,
                    `SOC_NPU_INPUT_END, "NPU input end");
        check_equal(`SOC_NPU_INPUT_END, `SOC_NPU_WEIGHT_BASE, "input/weight boundary");
        check_equal(`SOC_NPU_WEIGHT_BASE + `SOC_NPU_WEIGHT_BYTES,
                    `SOC_NPU_WEIGHT_END, "NPU weight end");
        check_equal(`SOC_NPU_WEIGHT_END, `SOC_NPU_OUTPUT_BASE, "weight/output boundary");
        check_equal(`SOC_NPU_OUTPUT_BASE + `SOC_NPU_OUTPUT_BYTES,
                    `SOC_NPU_OUTPUT_END, "NPU output end");
        check_equal(`SOC_NPU_OUTPUT_END, `SOC_NPU_SCRATCH_BASE, "output/scratch boundary");
        check_equal(`SOC_NPU_SCRATCH_BASE + `SOC_NPU_SCRATCH_BYTES,
                    `SOC_NPU_SCRATCH_END, "NPU scratch end");
        check_equal(`SOC_NPU_SCRATCH_END, `SOC_NPU_SHARED_END, "NPU shared coverage");

        if ((`SOC_CAM1_BUFFER0_BASE < `SOC_NPU_INPUT_BASE) ||
            (`SOC_CAM1_BUFFER0_BASE + `SOC_CAM1_BUFFER_SLOT_BYTES > `SOC_CAM1_BUFFER1_BASE) ||
            (`SOC_CAM1_BUFFER1_BASE + `SOC_CAM1_BUFFER_SLOT_BYTES > `SOC_NPU_INPUT_END) ||
            (`SOC_CAM1_FRAME_BYTES > `SOC_CAM1_BUFFER_SLOT_BYTES) ||
            ((`SOC_CAM1_BUFFER0_BASE & 32'h1f) != 0) ||
            ((`SOC_CAM1_BUFFER1_BASE & 32'h1f) != 0))
            $fatal(1, "CAM1 frame buffers overlap or exceed the NPU input region");

        // 双目四槽不能互相重叠，并为后续小图输入保留剩余空间。
        if ((`SOC_CAM1_BUFFER1_BASE + `SOC_CAM1_BUFFER_SLOT_BYTES > `SOC_CAM2_BUFFER0_BASE) ||
            (`SOC_CAM2_BUFFER0_BASE + `SOC_CAM1_BUFFER_SLOT_BYTES > `SOC_CAM2_BUFFER1_BASE) ||
            (`SOC_CAM2_BUFFER1_BASE + `SOC_CAM1_BUFFER_SLOT_BYTES > `SOC_NPU_INPUT_END) ||
            ((`SOC_CAM2_BUFFER0_BASE & 32'h1f) != 0) ||
            ((`SOC_CAM2_BUFFER1_BASE & 32'h1f) != 0))
            $fatal(1, "Stereo camera buffers overlap or exceed the input region");
        check_equal(`SOC_CAM2_MMIO_BASE, `SOC_CAM1_MMIO_END, "CAM1/CAM2 boundary");
        check_equal(`SOC_CAM2_MMIO_BASE + `SOC_CAM2_MMIO_BYTES,
                    `SOC_CAM2_MMIO_END, "CAM2 MMIO end");
        if (`SOC_CAM2_MMIO_END > `SOC_FPIOA_BASE)
            $fatal(1, "CAM2 MMIO overlaps FPIOA");

        // NPU 的 256-bit AXI 数据区必须以 32 Byte 边界开始、结束。
        if (((`SOC_NPU_SHARED_BASE  & 32'h0000_001f) != 32'b0) ||
            ((`SOC_NPU_INPUT_BASE   & 32'h0000_001f) != 32'b0) ||
            ((`SOC_NPU_WEIGHT_BASE  & 32'h0000_001f) != 32'b0) ||
            ((`SOC_NPU_OUTPUT_BASE  & 32'h0000_001f) != 32'b0) ||
            ((`SOC_NPU_SCRATCH_BASE & 32'h0000_001f) != 32'b0))
            $fatal(1, "NPU DDR buffer base is not 32-byte aligned");

        // MMIO 子窗口不可越过总窗口，各外设寄存器也不能重叠。
        check_equal(`SOC_MMIO_BASE + `SOC_MMIO_BYTES, `SOC_MMIO_END, "MMIO end");
        check_equal(`SOC_UART0_END, `SOC_NPU_MMIO_BASE, "UART/NPU MMIO boundary");
        check_equal(`SOC_NPU_MMIO_END, `SOC_LED_ADDR, "NPU MMIO/LED boundary");
        check_equal(`SOC_CAM1_MMIO_BASE + `SOC_CAM1_MMIO_BYTES,
                    `SOC_CAM1_MMIO_END, "CAM1 MMIO end");
        if ((`SOC_NPU_MMIO_BASE < `SOC_MMIO_BASE) ||
            (`SOC_NPU_MMIO_END > `SOC_MMIO_END) ||
            (`SOC_CAM1_MMIO_BASE < (`SOC_LED_ADDR + 32'd4)) ||
            (`SOC_CAM1_MMIO_END > `SOC_FPIOA_BASE) ||
            (`SOC_FPIOA_BASE < `SOC_MMIO_BASE) ||
            (`SOC_FPIOA_END > `SOC_MMIO_END))
            $fatal(1, "MMIO sub-window is outside the MMIO window");

        $display("SOC_ADDR_MAP_PASS");
        $finish;
    end
endmodule
