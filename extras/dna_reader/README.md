# PCILeech FPGA DNA Reader / PCILeech FPGA DNA 读取器

English | [中文](#中文文档)

---

## English Documentation

### Overview

This project implements FPGA DNA reading functionality for PCILeech, allowing host software to retrieve the unique 57-bit device identifier from Xilinx 7-series FPGAs via PCIe.

### Core Files

#### 1. pcileech_fifo.sv - FIFO Controller with DNA Register Mapping

The FIFO controller manages command and data transfer between the PCIe interface and internal modules. It has been extended to expose DNA values through the register space.

**Key Modifications:**

```systemverilog
// Extended read-only register space from 320 to 384 bits
wire [383:0] ro;

// DNA reader module instantiation
wire [56:0] dna_value;
wire dna_ready;

dna_reader i_dna_reader(
    .clk        ( clk        ),
    .rst        ( rst        ),
    .dna_value  ( dna_value  ),
    .dna_ready  ( dna_ready  )
);

// DNA register mapping
assign ro[351:320] = dna_value[31:0];   // +0x28: DNA[31:0]
assign ro[376:352] = dna_value[56:32];  // +0x2C: DNA[56:32]
assign ro[377] = dna_ready;             // +0x2F: DNA_READY flag
```

**Register Map:**

| Address | Bits | Description |
|---------|------|-------------|
| 0x0028  | 32   | DNA[31:0] - Lower 32 bits |
| 0x002C  | 25   | DNA[56:32] - Upper 25 bits |
| 0x002F  | 1    | DNA_READY - Ready flag |

#### 2. pcileech_fifo_dna.sv - DNA Reader Module

This module interfaces with the Xilinx DNA_PORT primitive to read the unique device identifier.

**Implementation:**

```systemverilog
DNA_PORT #(
    .SIM_DNA_VALUE(57'h0)
) dna_port_inst (
    .DOUT(dna_dout),
    .CLK(clk),
    .DIN(1'b0),
    .READ(dna_read),
    .SHIFT(dna_shift)
);
```

**State Machine:**

The module uses a simple state machine that automatically reads the DNA value after reset:

1. **IDLE** - Wait for reset to complete
2. **READ** - Assert READ signal to DNA_PORT
3. **SHIFT** - Shift out 57 bits serially
4. **DONE** - Set dna_ready flag

The DNA value is available immediately after FPGA configuration and remains stable.

#### 3. xilinx_dna_final.cpp - Host Communication Tool

The host-side application reads DNA values from the FPGA through PCILeech's register interface.

**Usage:**

```bash
xilinx_dna_final.exe
```

**Output Example:**

```
DNA = 000000110010010011001000000100101110111000011011010000101100 (0x00624c812ee1685c)
```

**Key Functions:**

- Opens PCILeech device handle
- Reads DNA registers at offsets 0x28 and 0x2C
- Combines 32-bit and 25-bit values into 57-bit DNA
- Displays result in binary and hexadecimal format

### Communication Flow

```
Host PC                    FPGA
   |                         |
   |-- Read Reg 0x28 ------->|
   |<----- DNA[31:0] --------|
   |                         |
   |-- Read Reg 0x2C ------->|
   |<----- DNA[56:32] -------|
   |                         |
   |-- Read Reg 0x2F ------->|
   |<----- DNA_READY --------|
```

### Building

**FPGA Firmware:**

1. Open Vivado project
2. Ensure pcileech_fifo.sv and pcileech_fifo_dna.sv are included
3. Synthesize and implement
4. Generate bitstream

**Host Tool (Windows with Visual Studio 2022):**

The host communication program is intentionally minimal - a single C++ file (`xilinx_dna_final.cpp`) that can be easily compiled with Visual Studio 2022.

**Visual Studio 2022 Compilation:**

1. Create a new **Console App** project in Visual Studio 2022
2. Add `xilinx_dna_final.cpp` to the project
3. Configure project settings:
   - Set **Configuration Type** to `Application (.exe)`
   - Add PCILeech library include paths and linker dependencies
4. Build the project to generate `xilinx_dna_final.exe`

**Minimal Program Design:**
- The entire program fits in one C++ file for simplicity
- No complex dependencies beyond PCILeech library
- Direct register access for maximum efficiency
- Lightweight and easy to integrate into existing projects

---

## 中文文档

### 概述

本项目为 PCILeech 实现了 FPGA DNA 读取功能，允许上位机软件通过 PCIe 接口获取 Xilinx 7 系列 FPGA 的唯一 57 位设备标识符。

### 核心文件

#### 1. pcileech_fifo.sv - 带 DNA 寄存器映射的 FIFO 控制器

FIFO 控制器管理 PCIe 接口与内部模块之间的命令和数据传输。已扩展以通过寄存器空间暴露 DNA 值。

**关键修改：**

```systemverilog
// 将只读寄存器空间从 320 位扩展到 384 位
wire [383:0] ro;

// DNA 读取模块实例化
wire [56:0] dna_value;
wire dna_ready;

dna_reader i_dna_reader(
    .clk        ( clk        ),
    .rst        ( rst        ),
    .dna_value  ( dna_value  ),
    .dna_ready  ( dna_ready  )
);

// DNA 寄存器映射
assign ro[351:320] = dna_value[31:0];   // +0x28: DNA[31:0]
assign ro[376:352] = dna_value[56:32];  // +0x2C: DNA[56:32]
assign ro[377] = dna_ready;             // +0x2F: DNA 就绪标志
```

**寄存器映射：**

| 地址   | 位宽 | 描述 |
|--------|------|------|
| 0x0028 | 32   | DNA[31:0] - 低 32 位 |
| 0x002C | 25   | DNA[56:32] - 高 25 位 |
| 0x002F | 1    | DNA_READY - 就绪标志 |

#### 2. pcileech_fifo_dna.sv - DNA 读取模块

该模块与 Xilinx DNA_PORT 原语接口，读取唯一设备标识符。

**实现：**

```systemverilog
DNA_PORT #(
    .SIM_DNA_VALUE(57'h0)
) dna_port_inst (
    .DOUT(dna_dout),
    .CLK(clk),
    .DIN(1'b0),
    .READ(dna_read),
    .SHIFT(dna_shift)
);
```

**状态机：**

模块使用简单的状态机，在复位后自动读取 DNA 值：

1. **IDLE** - 等待复位完成
2. **READ** - 向 DNA_PORT 发送 READ 信号
3. **SHIFT** - 串行移出 57 位数据
4. **DONE** - 设置 dna_ready 标志

DNA 值在 FPGA 配置后立即可用且保持稳定。

#### 3. xilinx_dna_final.cpp - 上位机通讯工具

上位机应用程序通过 PCILeech 的寄存器接口从 FPGA 读取 DNA 值。

**使用方法：**

```bash
xilinx_dna_final.exe
```

**输出示例：**

```
DNA = 000000110010010011001000000100101110111000011011010000101100 (0x00624c812ee1685c)
```

**关键功能：**

- 打开 PCILeech 设备句柄
- 读取偏移 0x28 和 0x2C 的 DNA 寄存器
- 将 32 位和 25 位值组合成 57 位 DNA
- 以二进制和十六进制格式显示结果

### 通讯流程

```
上位机                     FPGA
   |                         |
   |-- 读取寄存器 0x28 ----->|
   |<----- DNA[31:0] --------|
   |                         |
   |-- 读取寄存器 0x2C ----->|
   |<----- DNA[56:32] -------|
   |                         |
   |-- 读取寄存器 0x2F ----->|
   |<----- DNA_READY --------|
```

### 编译

**FPGA 固件：**

1. 打开 Vivado 项目
2. 确保包含 pcileech_fifo.sv 和 pcileech_fifo_dna.sv
3. 综合和实现
4. 生成比特流

**上位机工具（Windows + Visual Studio 2022）：**

上位机通讯程序设计得非常精简 - 仅一个 C++ 文件 (`xilinx_dna_final.cpp`)，可使用 Visual Studio 2022 轻松编译。

**Visual Studio 2022 编译步骤：**

1. 在 Visual Studio 2022 中创建新的 **控制台应用** 项目
2. 将 `xilinx_dna_final.cpp` 添加到项目中
3. 配置项目设置：
   - 设置 **配置类型** 为 `应用程序 (.exe)`
   - 添加 PCILeech 库的包含路径和链接器依赖项
4. 构建项目生成 `xilinx_dna_final.exe`

**精简程序设计特点：**
- 整个程序仅一个 C++ 文件，简洁明了
- 除 PCILeech 库外无复杂依赖
- 直接寄存器访问，效率最大化
- 轻量级，易于集成到现有项目中

### 参考资料

- [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga)
- [Xilinx 7 Series Configuration Guide (UG470)](https://www.xilinx.com/support/documentation/user_guides/ug470_7Series_Config.pdf)
