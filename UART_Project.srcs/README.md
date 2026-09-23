# UART-Controlled LED Sequencer on FPGA

## Overview

This project implements a **UART-controlled LED sequencer on a Digilent Nexys A7 FPGA board**. A PC communicates with the FPGA through a serial terminal such as PuTTY. Characters received through UART are decoded by the FPGA and used to control a 16-LED sequence.

The project was designed to build a deeper understanding of how **UART communication, digital logic, finite-state machines, FIFOs, timing, and FPGA I/O** work together in a complete hardware system.

The user can enter a hexadecimal starting position (`0–9`, `a–f`) through the terminal, and the FPGA begins moving through the LEDs sequentially. The terminal can also send `+` and `-` commands to increase or decrease the LED sequence speed.

---

# System Architecture

The overall data path is:

```text
              PC / PuTTY
                   │
                   │ USB-Serial
                   ▼
             ┌───────────┐
             │  UART RX  │
             └─────┬─────┘
                   │
                   ▼
             ┌───────────┐
             │ RX FIFO   │
             └─────┬─────┘
                   │
                   ▼
             ┌───────────┐
             │    FSM    │
             │  top.sv   │
             └─────┬─────┘
                   │
          ┌────────┼─────────┐
          │        │         │
          ▼        ▼         ▼
       LED FSM   Timer     UART TX
          │        │         │
          ▼        │         ▼
       16 LEDs     │      TX FIFO
                   │         │
                   │         ▼
                   │       UART
                   │         │
                   │         ▼
                   │     PC / PuTTY
                   │
                   ▼
            Seven-Segment
               Display
```

The system is divided into several hardware modules, with `top.sv` acting as the main controller that connects the modules together.

---

# Module Structure

## 1. `baud_gen.sv`

The baud generator creates the timing signal used by the UART receiver and transmitter.

The FPGA operates from a **100 MHz system clock**, while UART communication operates at a much slower baud rate such as **9600 baud**.

The baud generator uses a programmable divisor:

```text
dvsr = 650
```

to generate a periodic sampling tick.

The UART uses **16 sampling ticks per transmitted bit**, allowing the receiver to sample near the center of each UART bit.

---

# 2. `uart_rx.sv`

The UART receiver converts the serial signal from the PC into an 8-bit parallel byte.

UART transmits data sequentially over one wire:

```text
Start → D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → Stop
```

The receiver uses a finite-state machine with four states:

```text
IDLE
  ↓
START
  ↓
DATA
  ↓
STOP
```

### IDLE

The receiver waits for the UART line to transition from its idle-high state to a low start bit.

### START

The receiver waits until the appropriate sampling point in the start bit.

### DATA

The receiver samples eight data bits, one at a time.

The bits are received **LSB first** and shifted into an 8-bit register.

### STOP

The receiver waits for the stop bit and then asserts:

```text
rx_done_tick
```

indicating that a complete byte has been received.

The resulting byte is provided through:

```systemverilog
dout[7:0]
```

---

# 3. RX FIFO

The received UART data is stored in a FIFO before being processed by the main controller.

The FIFO provides buffering between the UART receiver and the main FSM.

Instead of requiring the controller to process a received character at exactly the moment it arrives, the UART can place the character into the FIFO and the controller can retrieve it when ready.

Important signals include:

```text
rx_empty
r_data
rd_uart
```

### RX data flow

```text
PC
 ↓
UART RX
 ↓
RX FIFO
 ↓
r_data
 ↓
Main FSM
```

The FSM checks:

```systemverilog
if (!rx_empty)
```

to determine whether a character is available.

When data is available, the FSM asserts:

```systemverilog
rd_uart
```

to remove one byte from the FIFO.

---

# 4. `uart_tx.sv`

The UART transmitter performs the opposite operation of the receiver.

It converts an 8-bit parallel byte into a serial UART waveform.

For example, if the FPGA wants to transmit:

```text
8'h35
```

which represents ASCII `'5'`, the transmitter creates:

```text
Start
  ↓
0 1 0 1 0 0 1 1
  ↓
Stop
```

with the appropriate UART timing.

The transmitter is controlled using signals such as:

```text
wr_uart
w_data
tx_full
tx
```

The main controller places a byte into the TX path using:

```systemverilog
wr_uart = 1'b1;
w_data = ...
```

The UART transmitter then serializes the byte and sends it back to the PC.

---

# 5. TX FIFO

The transmitter also uses a FIFO to buffer outgoing data.

The main FSM does not need to wait for the UART transmitter to physically finish transmitting a byte before continuing its operation.

Instead, it can place data into the transmit FIFO.

The controller checks:

```text
tx_full
```

before writing new data.

The basic transmit path is:

```text
Main FSM
   ↓
w_data
   ↓
TX FIFO
   ↓
UART TX
   ↓
tx
   ↓
PC / PuTTY
```

This creates a clean interface between the application logic and the physical serial communication hardware.

---

# 6. `top.sv`

`top.sv` is the main module and acts as the **system-level controller**.

It connects:

* UART receiver
* UART transmitter
* FIFOs
* Timer
* LED control
* Seven-segment display
* User commands
* Main finite-state machine

The major states are:

```text
IDLE
 ↓
READ_RX
 ↓
PROCESS_RX
 ↓
WAIT_RX
 ↓
FLASH_LED
```

---

## IDLE

The system waits for a character to arrive in the RX FIFO.

```text
rx_empty = 1
```

means there is currently no received data.

When:

```text
rx_empty = 0
```

the FSM moves to `READ_RX`.

---

## READ_RX

The controller asserts:

```text
rd_uart
```

to remove one byte from the RX FIFO.

The received byte becomes available through:

```text
r_data
```

The FSM then moves to `WAIT_RX`.

---
## WAIT_RX

The controller waits for the FIFO read operation to complete before attempting to interpret r_data.

This prevents the FSM from processing stale data from the previous UART transaction.

The FSM then moves to `PROCESS_RX`.


## PROCESS_RX

This is where the system interprets the received ASCII character.

The commands include:

| Character | Function                  |
| --------- | ------------------------- |
| `0–9`     | Select starting LED       |
| `a–f`     | Select starting LED 10–15 |
| `+`       | Increase sequence speed   |
| `-`       | Decrease sequence speed   |
|           |                           |

For example:

```text
'0' → LED 0
'1' → LED 1
'2' → LED 2
...
'9' → LED 9
'a' → LED 10
'b' → LED 11
...
'f' → LED 15
```

ASCII values are converted into LED indices using arithmetic operations such as:

```systemverilog
r_data - 8'h30
```

for characters `'0'–'9'`.

For hexadecimal characters:

```systemverilog
r_data - 8'h61 + 4'd10
```

converts:

```text
'a' → 10
'b' → 11
...
'f' → 15
```

---

# 7. LED Sequencer

Once a starting LED is selected, the FSM enters:

```text
FLASH_LED
```

The LED index is stored in:

```systemverilog
logic [3:0] led_index;
```

The LED pattern is generated using a shift:

```systemverilog
16'b1 << led_index
```

This creates a one-hot LED pattern.

For example:

```text
led_index = 0

0000 0000 0000 0001
```

then:

```text
led_index = 1

0000 0000 0000 0010
```

then:

```text
led_index = 2

0000 0000 0000 0100
```

and so on until LED 15.

The timer determines when the sequence advances to the next LED.

---

# 8. Variable-Speed Timer

The project contains a programmable timer that controls how quickly the LED sequence moves.

There are four speed settings:

| Speed |  Delay |
| ----- | -----: |
| `0`   | 500 ms |
| `1`   | 200 ms |
| `2`   | 100 ms |
| `3`   |  50 ms |

The `+` command increments the speed setting:

```text
500 ms
   ↓ +
200 ms
   ↓ +
100 ms
   ↓ +
50 ms
```

The `-` command reverses the process:

```text
50 ms
 ↓ -
100 ms
 ↓ -
200 ms
 ↓ -
500 ms
```

The speed value is also sent to the seven-segment display.

This demonstrates how a UART command can modify the behavior of hardware logic in real time.

---

# 9. `disp_hex_mux.sv`

The seven-segment display module provides visual feedback for the current speed setting.

The module multiplexes the FPGA's eight seven-segment displays and controls:

```text
an[7:0]
sseg[7:0]
```

Because the displays share segment lines, the FPGA rapidly switches between digits to create the appearance that multiple displays are illuminated simultaneously.

# Complete Command Flow

For example, if the user enters:

```text
4
```

into PuTTY:

```text
PC
 ↓
USB Serial
 ↓
UART RX
 ↓
RX FIFO
 ↓
top.sv
 ↓
PROCESS_RX
 ↓
led_index = 4
 ↓
FLASH_LED
 ↓
LED 4 → LED 5 → LED 6 → ... → LED 15
```

The FPGA simultaneously sends the active LED number back through UART:

```text
4
5
6
7
...
f
```

So the terminal provides both **control input** and **serial feedback**.

---

Verification

The project was verified using a SystemVerilog testbench that simulates UART communication between a PC and the FPGA.

The testbench includes a UART byte transmission task that reproduces the basic UART frame:

       Start        Data Bits             Stop
         ↓             ↓                   ↓
        ┌───┬───────────────────────────┬───┐
Idle ───┘   │ D0 D1 D2 D3 D4 D5 D6 D7 │   └─── Idle
            └───────────────────────────┘

Each byte is transmitted:

With one start bit
With eight data bits
LSB first
With one stop bit

The testbench was used to verify both the UART receive path and the higher-level LED controller.

UART RX Verification

The UART receiver was tested with several different byte patterns, including:

8'h30 → ASCII '0'
8'h31 → ASCII '1'
8'h61 → ASCII 'a'
8'h2B → ASCII '+'
8'hA5 → Test data pattern

After each transmission, the testbench waits for:

rx_done_tick

and compares the received output:

dout

against the expected byte.

For example:

if (dout == 8'h30)
    $display("PASS: Received 0x30 correctly");
else
    $display("FAIL: Expected 0x30");

This verifies that the UART receiver correctly detects the start bit, samples the eight data bits, reconstructs the original byte, and recognizes the stop bit.

Top-Level Verification

The top-level testbench also verifies the commands used by the LED sequencer.

Starting positions are tested using:

0
1
2
a
b
c

The testbench checks that the appropriate LED becomes active.

For example:

'0' → LED 0
'1' → LED 1
'2' → LED 2
'a' → LED 10
'b' → LED 11
'c' → LED 12
Speed Control Verification

The + and - UART commands are also tested.

Starting from the minimum speed:

+
+
+

should produce:

speed 0 → speed 1 → speed 2 → speed 3

The testbench then sends an additional + to verify that the speed does not exceed the maximum value.

Similarly, the testbench sends:

-
-
-

to verify:

speed 3 → speed 2 → speed 1 → speed 0

An additional - command is then sent to verify that the speed does not go below the minimum value.

Verification Goals

The testbench therefore verifies several layers of the design:

UART RX
  ↓
Correct byte reception
  ↓
FIFO communication
  ↓
Command decoding
  ↓
LED selection
  ↓
Speed control

This allowed the design to be tested at both the individual-module level and the system level, rather than relying only on physical FPGA testing.

# Key Concepts Learned

This project brought together several fundamental digital design concepts into one FPGA system.

### Digital Design

* Synchronous sequential logic
* Combinational logic
* Registers
* Counters
* Clocked state machines
* One-hot LED control

### UART

* Start/stop framing
* Baud-rate generation
* Oversampling
* Serial-to-parallel conversion
* Parallel-to-serial conversion
* UART RX/TX architecture

### FIFOs

* Data buffering
* Read/write control
* Full/empty status
* Producer-consumer interfaces

### FPGA System Integration

The biggest takeaway from this project was learning how individual RTL modules become a complete hardware system.

Instead of treating UART, timers, FIFOs, displays, and LED logic as isolated circuits, this project required integrating them through well-defined interfaces.
