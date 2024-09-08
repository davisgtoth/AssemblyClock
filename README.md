# DE0-CV FPGA Board Clock

This repo contains code in assembly language that turns the DE0-CV FPGA board into a digital clock. The code makes use of the 6 hexadecimal displays, the four push buttons and two of the switches.

## User Guide
### Setup
To set the time of the clock...

### Modes

## File Details 
```bash
Assembly Clock
├── MODDE0CV
├── README.md
├── a
├── a51
├── b
├── backup
│   └── clock_backup.asm
├── clock.asm
├── clock.hex
├── clock.lst
├── pdex
└── subroutines
    ├── date.asm
    ├── display.asm
    ├── set_mode.asm
    └── time.asm
```
File 'a' is a script used to compile the assembly code into a .hex and .lst file by calling 'a51'. File 'b' is a script used to upload the .hex to the board by calling 'pdex'. 
'MODDE0CV' contains register definitions. 
'clock.asm' contains the main code, which itself calls all the files in the subroutine directory. The backup directory contains all the code in a single file. 
