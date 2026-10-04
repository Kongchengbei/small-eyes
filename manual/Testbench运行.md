# Testbench 运行入口

普通 `make` 仍打开 menuconfig。运行 `sim/` 中的 testbench：

```sh
make all=tb_Hcsrrun
make all=tb_Hcsr.svrun
make tb_Hcsrrun
make all=tb_npu_service run
make sim-list
```

`all=` 选择器支持文件基本名、`.sv/.v` 后缀、可选 `sim/` 前缀及末尾 `run`；testbench 的顶层模块名应与文件基本名相同。只编译所选 testbench，不将其他 testbench 混作顶层。脚本自动加入 CPU、SoC、JTAG RTL、相机仿真模型和所需 BRAM 时钟替身；cache SRAM 使用行为模型，不同时编译厂商封装。

默认使用 Verilator（需要 C++ 编译器和 GNU Make），启用 timing 仿真和断言检查。编译日志保留全部警告，错误会返回非零状态并显示日志尾部。可选 Icarus，但它不支持部分现有 testbench 的 SystemVerilog 写法；这类测试应使用默认 Verilator。

```sh
make all=tb_Hcsrrun SIMULATOR=iverilog
make all=tb_preprocess_stereorun SIM_FLAGS='-GW=640 -GH=480'
make all=tb_camera_stereo_firmwarerun SIM_PROGRAM=path/to/firmware.hex SIM_ARGS='+UART_PIN=0 +LONG_RUN'
make all=tb_Htoprun SIM_PROGRAM=path/to/program.hex SIM_ARGS='+TIMEOUT=200000'
```

`SIM_PROGRAM` 传递 `+PROGRAM=`，应提供该 testbench 要求的 `$readmemh` 文本镜像，不是直接传入原始 BIN。也可通过 `SIM_ARGS='+PROGRAM=... ...'` 指定，但不能与 `SIM_PROGRAM` 重复。`SIM_ARGS`、`SIM_FLAGS` 按空白拆分，不执行 shell 表达式；带空格的镜像路径请使用 `SIM_PROGRAM`。

参数：`SIM_JOBS=2` 为 Verilator 编译并行数；`SIM_TIMEOUT=120` 为运行阶段墙钟超时秒数；`SIM_BUILD_ONLY=1` 仅编译。参数变化会重新生成仿真程序，C++ 构建可复用未变化的对象文件。产物和日志位于 `build/sim/<testbench>/<simulator>/`。

CPU/固件测试需要先准备正确的程序镜像，脚本不会自动构建或替换固件。历史 `tb_coremark`、`tb_coremark_probe` 硬编码了旧的 `../source/soc/coremark.dat` 路径；若缺失则给出提示，可改用 `tb_Htop` 的 `+COREMARK` 模式并传入匹配的镜像。提供运行入口不等于所有历史 testbench 已通过当前 RTL 回归，具体功能仍以各测试输出为准。
