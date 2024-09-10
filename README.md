# DE0-CV FPGA Board Clock

This repository contains a project where the **DE0-CV FPGA board** is programmed to function as a **digital clock**, using **8051 Assembly language**. The project demonstrates skills in low-level embedded systems programming, hardware-software interfacing, and real-time control, focusing on the use of **7-segment displays** for time and date output.

The code leverages the 8051 microcontroller's architecture to control the DE0-CV board's hardware components, showcasing a hands-on understanding of microcontroller programming and hardware manipulation.
  
![Clock Demo](./gifs/demo.gif)  
_The clock running on the DE0-CV board, displaying the time._

## User Guide

### Setup
To set the time and date, follow these steps:

1. **Enter Set Mode (Time)**:
   - Flip switch `SW0` up to enter set mode for the clock.
   - The current time is entered in **24-hour format**. The seconds digit will flash by default.
   - Use push buttons `KEY2` to increment and `KEY1` to decrement the selected digit.
   - Navigate between digits using `KEY3` (left) and `KEY0` (right).

2. **Enter Set Mode (Date)**:
   - Flip switch `SW1` up to set the date. The year digit is selected by default.
   - Use the same push buttons as above to increment/decrement digits and navigate.
   - **Note**: If both `SW0` and `SW1` are up, date setup takes priority.

**Validation**: The system prevents invalid time and date entries. 

![Set Demo](./gifs/set.gif)

### Display Modes
By default (i.e. when not in set mode, i.e. when all switches are down), the clock will display the full time `hr:min:sec` in 24-hour format. All four push buttons can be used to toggle different display modes:
- `KEY3` : toggles 12-hour format
- `KEY2` : toggles the display of the seconds digit
    - when showing time in 24-hour format, this will blank `HEX1` and `HEX0`
    - when showing time in 12-hour format, this will show either `AM` or `PM` depending on the time
- `KEY1` : displays the date in `MM/DD/YY` format for two seconds 
- `KEY0` : toggles blanking all six hex displays

![Mode Demo](./gifs/modes.gif)  

### Tools and Development Environment
- **Assembler**: The code is compiled using the **Keil uVision IDE** with its `a51` assembler for 8051 microcontrollers.
- **Board**: The project was tested on the **DE0-CV FPGA Board**, which interfaces with the 8051 architecture.
- **Uploader**: A script (`b`) is provided to upload the compiled `.hex` file to the FPGA board.

## File Details 
```bash
AssemblyClock
├── MODDE0CV           # Register definitions for the FPGA
├── README.md          # This file
├── clock.asm          # Main assembly code
├── subroutines/       # Assembly subroutines for different functionalities
│   ├── date.asm       # Date handling code
│   ├── display.asm    # 7-segment display logic
│   ├── set_mode.asm   # Clock and date setting modes
│   └── time.asm       # Time handling code
├── gifs/              # GIF demonstrations of clock functionality
│   ├── demo.gif       # Shows clock in action
│   ├── modes.gif      # Shows mode switching
│   └── set.gif        # Shows time setting process
├── a                  # Assembles code into .hex file
├── a51                # Calls assembler for 8051 code
├── b                  # Uploads .hex file to the FPGA
├── backup/            # Backup of assembly code
│   └── clock_backup.asm # Backup of clock.asm
├── clock.hex          # Compiled machine code
├── clock.lst          # Assembler output listing file
└── pdex               # Tool for programming the FPGA
```
