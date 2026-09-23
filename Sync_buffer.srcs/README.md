# Three Synchronous Buffer Architectures on FPGA

## Overview

This project focuses on the **design, simulation, verification, and FPGA implementation of three different synchronous buffer architectures** using Verilog/SystemVerilog.

Rather than implementing a single FIFO, I developed an interactive FPGA system that allows the user to select between three different buffer architectures and observe their behavior using the onboard switches, push buttons, LEDs, and seven-segment displays of a **Xilinx Nexys A7 FPGA**.

The three architectures implemented are:

1. **1-Write / 1-Read Synchronous FIFO**
2. **16-bit Write / 8-bit Read Width-Conversion FIFO**
3. **Synchronous Stack Buffer (LIFO)**

# System Architecture

The overall system integrates three different synchronous buffer architectures into a single FPGA design. A system-level finite state machine (FSM) controls which buffer is active based on the user's selection.

The three buffer states are directly associated with the three buffer architectures:

* `STATE1` → `SYNC_BUFFER1` — 1-Write / 1-Read Synchronous FIFO
* `STATE2` → `SYNC_BUFFER2` — 16-bit Write / 8-bit Read Width-Conversion FIFO
* `STATE3` → `STACK_BUFFER` — Synchronous LIFO Stack

```text
                         ┌──────────────────────┐
                         │     FPGA Inputs      │
                         │                      │
                         │  Switches / Buttons  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ Debounce + Rising    │
                         │ Edge Detection       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │     System FSM       │
                         │                      │
                         │      IDLE            │
                         │        │             │
                         │      STATE1          │
                         │      STATE2          │
                         │      STATE3          │
                         └──────────┬───────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
     ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
     │     STATE1      │   │     STATE2      │   │     STATE3      │
     │       │         │   │       │         │   │       │         │
     │       ▼         │   │       ▼         │   │       ▼         │
     │  SYNC_BUFFER1   │   │  SYNC_BUFFER2   │   │   STACK_BUFFER  │
     │                 │   │                 │   │                 │
     │  1W / 1R FIFO   │   │  16W / 8R FIFO  │   │  LIFO Stack     │
     │                 │   │                 │   │                 │
     │ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
     │ │ FIFO        │ │   │ │ Width-Conv. │ │   │ │ Stack       │ │
     │ │ Controller  │ │   │ │ Controller  │ │   │ │ Controller  │ │
     │ └──────┬──────┘ │   │ └──────┬──────┘ │   │ └──────┬──────┘ │
     │        │        │   │        │         │   │       │        │
     │ ┌──────▼──────┐ │   │ ┌──────▼──────┐ │   │ ┌──────▼──────┐ │
     │ │ Register    │ │   │ │ Register    │ │   │ │ Stack       │ │
     │ │ File        │ │   │ │ File        │ │   │ │ Memory      │ │
     │ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
     └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
              │                     │                     │
              └─────────────────────┼─────────────────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ Output Data /        │
                         │ Occupancy Count      │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │   Binary-to-BCD      │
                         │      Converter       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ Seven-Segment Display│
                         └──────────────────────┘
```

### FSM Buffer Selection

The FSM controls the selection of the three buffer architectures. After the system starts, the user cycles through the selection states and chooses the desired buffer.

```text
                         ┌──────────┐
                         │   IDLE   │
                         │   "HI"   │
                         └────┬─────┘
                              │
                         Start Button
                              │
                              ▼
                         ┌──────────┐
                         │  STATE1  │──────────────► SYNC_BUFFER1
                         └────┬─────┘                1W / 1R FIFO
                              │
                         Next Selection
                              │
                              ▼
                         ┌──────────┐
                         │  STATE2  │──────────────► SYNC_BUFFER2
                         └────┬─────┘                16W / 8R FIFO
                              │
                         Next Selection
                              │
                              ▼
                         ┌──────────┐
                         │  STATE3  │──────────────► STACK_BUFFER
                         └──────────┘                LIFO Stack
```

Each FSM state therefore corresponds directly to one buffer implementation:

| FSM State | Buffer         | Architecture                   |
| --------- | -------------- | ------------------------------ |
| `STATE1`  | `SYNC_BUFFER1` | 1-Write / 1-Read FIFO          |
| `STATE2`  | `SYNC_BUFFER2` | 16-bit Write / 8-bit Read FIFO |
| `STATE3`  | `STACK_BUFFER` | LIFO Stack                     |

Once a state is selected, the corresponding buffer becomes the active data-storage architecture. The three buffers then share the system's input-conditioning and display circuitry.


# Three Buffer Implementations

## 1. 1-Write / 1-Read Synchronous FIFO

The first architecture is a conventional **synchronous FIFO (First-In, First-Out)**.

A FIFO follows the principle:

> The first value written into the buffer is the first value read from the buffer.

The FIFO uses separate read and write operations, with both operations synchronized to the same clock.

### FIFO Architecture

The FIFO was divided into two major components:

* **FIFO Controller**
* **Register File**

These components are combined by the top-level FIFO module.

```text
                 ┌─────────────────────────┐
                 │     FIFO Controller     │
                 │                         │
                 │ • Write Pointer         │
                 │ • Read Pointer          │
                 │ • Occupancy Counter     │
                 │ • Full / Empty Flags    │
                 └────────────┬────────────┘
                              │
                              │ Addresses
                              ▼
                 ┌─────────────────────────┐
                 │      Register File      │
                 │                         │
                 │   Memory Locations      │
                 │                         │
                 │  ┌───┬───┬───┬───┐     │
                 │  │   │   │   │   │     │
                 │  └───┴───┴───┴───┘     │
                 └────────────┬────────────┘
                              │
                              ▼
                         Read Data
```

### Memory Organization

The FIFO uses a memory structure consisting of **8 memory locations**, with each location storing **8 bits of data**.

```text
                8 × 8-bit Memory

        Address        Data
       ┌────────┬────────────┐
       │   0    │  8 bits    │
       ├────────┼────────────┤
       │   1    │  8 bits    │
       ├────────┼────────────┤
       │   2    │  8 bits    │
       ├────────┼────────────┤
       │   3    │  8 bits    │
       ├────────┼────────────┤
       │   4    │  8 bits    │
       ├────────┼────────────┤
       │   5    │  8 bits    │
       ├────────┼────────────┤
       │   6    │  8 bits    │
       ├────────┼────────────┤
       │   7    │  8 bits    │
       └────────┴────────────┘

       Total Capacity = 8 × 8 = 64 bits
```

Each memory location stores one **8-bit data word**, giving the FIFO a total storage capacity of **64 bits**.

The FIFO controller uses **3-bit read and write addresses** to select one of the eight memory locations. As the FIFO operates, the read and write pointers advance through the memory locations and wrap around when they reach the end of the buffer.

The occupancy counter tracks how many of the eight available memory locations currently contain valid FIFO entries.

For example:

```text
Empty FIFO:

[  ][  ][  ][  ][  ][  ][  ][  ]
 ↑
Read/Write Pointer


After writing 3 values:

[ A ][ B ][ C ][  ][  ][  ][  ][  ]
  ↑    ↑    ↑
 0    1    2

Occupancy = 3 / 8
```

This organization separates the **control logic** from the **storage**: the FIFO controller manages addresses and occupancy, while the register file provides the eight 8-bit memory locations.


### FIFO Controller

The **FIFO controller** is responsible for managing the state of the FIFO.

It keeps track of:

* Write address
* Read address
* Number of occupied entries
* Empty condition
* Full condition

When a valid write occurs, the controller increments the write pointer and updates the occupancy count.

When a valid read occurs, the controller increments the read pointer and decreases the occupancy count.

The controller also prevents invalid operations such as writing when the FIFO is full or reading when the FIFO is empty.

### Register File

The **register file** provides the actual storage for the FIFO.

The controller determines **where** data should be written or read, while the register file is responsible for **storing the data**.

During a write operation:

```text
Write Data
    │
    ▼
Register File
    │
    └──► Write Address
```

During a read operation:

```text
Read Address
     │
     ▼
Register File
     │
     ▼
Read Data
```

### Combining the Controller and Register File

The top-level FIFO module connects the two components together.

```text
                 Write Request
                       │
                       ▼
              ┌─────────────────┐
              │ FIFO Controller │
              └───────┬─────────┘
                      │
             Write Address
                      │
                      ▼
              ┌─────────────────┐
Write Data ──►│  Register File  │
              └───────┬─────────┘
                      │
                   Read Data
                      │
                      ▼
              FIFO Output
```

---

# 2. 16-bit Write / 8-bit Read FIFO

The second architecture builds on the standard FIFO by introducing **data-width conversion**.

This buffer accepts:

```text
16-bit input data
```

and produces:

```text
8-bit output data
```

A single 16-bit write therefore contains two 8-bit pieces of information.

```text
             16-bit Write
                  │
                  ▼
        ┌─────────────────────┐
        │                     │
        │    FIFO Storage     │
        │                     │
        │    16-bit Word      │
        │                     │
        └──────────┬──────────┘
                   │
             ┌─────┴─────┐
             │           │
             ▼           ▼
          8-bit         8-bit
          Data 1        Data 2
             │           │
             └─────┬─────┘
                   ▼
              Read Output
```

This required additional controller logic compared with the standard FIFO.

The design must keep track of the relationship between the number of **16-bit words written** and the number of **8-bit values read**.

For example:

```text
Write: 16'hABCD

Read 1 → 8'hCD
Read 2 → 8'hAB
```

The exact ordering is determined by the implementation's byte-selection logic.

This design introduced several additional RTL concepts:

* Data-width conversion
* Multiple read units per write
* Pointer management across different data granularities
* Capacity management
* More complex controller logic
* Maintaining correct data ordering

The width-conversion FIFO demonstrates how a buffer can act as an interface between two digital systems that operate using different data widths.

---

# 3. Synchronous Stack Buffer

The third architecture implements a **synchronous stack**, which follows the **LIFO (Last-In, First-Out)** principle.

Unlike a FIFO, where the oldest data is retrieved first, a stack retrieves the most recently written data first.

```text
Write 1 → 10
Write 2 → 20
Write 3 → 30

        ┌──────┐
        │  30  │ ← First Read
        ├──────┤
        │  20  │
        ├──────┤
        │  10  │
        └──────┘
```

Reading from the stack produces:

```text
Read → 30
Read → 20
Read → 10
```

The stack uses a pointer that represents the current top of the stack.

A write operation pushes data onto the stack and updates the pointer.

A read operation pops data from the top of the stack and updates the pointer in the opposite direction.

The stack implementation provided a useful comparison between:

* **FIFO:** First-In, First-Out
* **Stack:** Last-In, First-Out

Although both structures use memory for temporary storage, their control logic and access patterns are fundamentally different.

---

# Binary-to-BCD Conversion

The buffer produces binary values internally, including occupancy counts and read data.

To display these values on the FPGA's seven-segment displays, I implemented a **binary-to-BCD converter**.

An 8-bit binary value is converted into four individual BCD digits.

```text
             8-bit Binary
                  │
                  ▼
          ┌────────────────┐
          │    bin2bcd     │
          │    Converter   │
          └───────┬────────┘
                  │
        ┌─────────┼─────────┼─────────┼
        ▼         ▼         ▼         ▼
      BCD 3     BCD 2     BCD 1     BCD 0
        │         │         │         │
        └─────────┴─────────┴─────────┘
                         │
                         ▼
                Seven-Segment Mux
                         │
                         ▼
                  Display Output
```

The individual BCD digits are then passed to the seven-segment display multiplexer.

This allows binary values generated by the buffer architectures to be displayed as human-readable decimal numbers.

---

# Button Debouncing and Rising-Edge Detection

One of the most important differences between simulation and physical FPGA operation appeared during hardware testing.

During simulation, the testbench operates using a clock period of approximately:

```text
10 ns
```

A physical button press, however, occurs on a much slower human time scale, approximately:

```text
0.1 seconds
```

Therefore, a button can remain asserted for a very large number of FPGA clock cycles.

Without proper input conditioning, a single physical button press could be interpreted as many consecutive write or read operations.

For example:

```text
Physical Button Press
        │
        ▼
   Button remains HIGH
        │
        ├── Clock Cycle 1
        ├── Clock Cycle 2
        ├── Clock Cycle 3
        ├── Clock Cycle 4
        ├── ...
        └── Many more cycles
```

This can cause the FIFO occupancy to rapidly transition toward the full or empty condition instead of performing exactly one operation.

### Debouncer

The first stage is a **button debouncer**.

Mechanical switches can produce rapid electrical transitions when pressed or released. These transitions are known as switch bounce.

The debouncer waits until the input signal has remained stable long enough to be considered a valid button state.

### Rising-Edge Detector

After debouncing, a **rising-edge detector** is used.

The edge detector generates a single-cycle pulse when the button transitions from:

```text
LOW → HIGH
```

The resulting signal is:

```text
Button Press
     │
     ▼
 Debouncer
     │
     ▼
Rising-Edge Detector
     │
     ▼
One Clock-Cycle Pulse
     │
     ▼
FIFO / Stack Operation
```

This ensures that one physical button press corresponds to one read, write, push, or pop operation.

---

# Design and Verification

The design was verified through both **simulation and physical FPGA testing**.

## Simulation

The initial FIFO designs were tested using Verilog/SystemVerilog testbenches.

Simulation was used to verify:

* Write operations
* Read operations
* Pointer progression
* Occupancy counting
* Full detection
* Empty detection
* FIFO data ordering
* Stack LIFO behavior
* Width-conversion behavior
* Reset behavior

The testbench operates on a significantly faster time scale than physical human interaction.

For example:

```text
Testbench Clock:
10 ns

Physical Button Interaction:
~0.1 seconds
```

This difference highlighted why simulation alone is not always sufficient for validating an FPGA system.

---

# What I Learned

This project provided experience across multiple levels of digital hardware design, from individual RTL modules to complete FPGA system integration.

### RTL Design

* Synthesizable Verilog/SystemVerilog
* Sequential and combinational logic
* Parameterized modules
* Clocked state and data storage
* Reset design
* Modular RTL architecture

### Buffer Architecture

* FIFO architecture
* LIFO stack architecture
* Read/write pointer management
* Stack pointer management
* Occupancy tracking
* Full and empty flag generation
* Data-width conversion
* Maintaining data ordering

### Control Logic

* Finite State Machines
* ASMD-style control
* System-level FSM integration
* State-based module selection
* Control and datapath separation

### FPGA Interfaces

* Push-button input conditioning
* Debouncing
* Rising-edge detection
* Switch inputs
* LED status outputs
* Seven-segment display multiplexing
* Binary-to-BCD conversion

### Verification and Debugging

* RTL simulation
* Testbench development
* Waveform analysis
* Hardware debugging
* Identifying simulation-to-hardware differences
* Synthesizability considerations
* FPGA implementation using Vivado

One of the most valuable lessons from this project was that **passing simulation does not automatically mean that a design will behave correctly when connected to real hardware**. The transition from a controlled testbench environment to physical inputs introduced real-world timing and signal-conditioning considerations that required additional hardware logic.

---

# Tools and Technologies

| Category       | Technology                   |
| -------------- | ---------------------------- |
| HDL            | Verilog / SystemVerilog      |
| FPGA           | Xilinx Nexys A7              |
| FPGA Toolchain | Xilinx Vivado                |
| Simulation     | Vivado XSim                  |
| Design Method  | RTL                          |
| Control        | Finite State Machines        |
| Display        | Seven-Segment Display        |
| Input          | Push Buttons / Switches      |
| Verification   | Testbench + Hardware Testing |

---

# Repository Structure

```text
Sync_buffer.srcs
│
├── constr_1/New
│   ├── constraints.xdc
│   ├── constraints_main.xdc
│   
│
├── Width_Conversion_FIFO/
│   ├── fifo_controller_W2R1.sv
│   ├── fifo_register_file_W2R1.sv
│   └── fifo_W2R1.sv
│
├── Sim_1/New
│   ├── fifo_W2R1_tb.sv
|   ├── fifo_stack_tb.sv
│   ├── fifo_w1r1_tb.sv
│   └── main_test_tb.sv
│
├── sources_1/New
│   ├── Rising_Edge_Detector.sv
│   ├── bin2bcd.sv
│   ├── db_fsm.sv
│   └── disp_hex_mux.sv
│   └── fifo_controller_W2R1.sv
│   └── fifo_controller_w1r1.sv
│   └── fifo_stack.sv
│   └── fifo_w1r1.sv
│   └── fifow2r1.sv
│   └── main_test.sv
│   └── reg_file_w1r1.sv
│   └── reg_filew2r1.sv
│   └── stack_ctrl.sv
│   └── stack_reg_file.sv
│   └── sync_buff_w1r1.sv
│   └── sync_buff_w2r1.sv
│ 
└── Sync_buffer_Projects.xpr
└── README.md


# Author

Max Wang

Electrical Engineering Student — University of California, Santa Barbara (UCSB)

