# DE0-CV FPGA Board Clock

This repo contains code in assembly language that turns the DE0-CV FPGA board into a digital clock. The code makes use of the 6 hexadecimal displays, the four push buttons and two of the switches.

## User Guide
### Setup
run a to compile the code
```bash
% ./a

1) clock.asm
2) Quit
Please select a file to compile: 1
Compiling clock.asm
No errors found
```

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
