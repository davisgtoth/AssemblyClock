# DE0-CV FPGA Board Clock

This repository contains code in 8051 Assembly language that turns the DE0-CV FPGA board into a digital clock. The code makes use of the six 7-segment hexadecimal displays to show the time in `hr:min:sec` and date in `MM/DD/YY`. The four push buttons and two of the switches are used to set the clock and switch between various display modes.  
  
![Clock Demo](./gifs/demo.gif)

## User Guide
### Setup
To set the time of the clock, switch `SW0` is flipped up to enter set mode. Here, the current time can be entered individually for each digit in 24-hour format. By default, when first entering set mode the second's digit will be selected and start flashing. The four push buttons are used to navigate between the digits and increment/decrement them as follows:  
- `KEY3` : move to the left
- `KEY2` : increments the selected digit
- `KEY1` : decrements the selected digit
- `KEY0` : move to the right
  
To set the date, switch `SW1` is flipped up. Here, the year digit is initially selected by default. All four push buttons are used in the same way to set the date. Note that if both `SW0` and `SW1` are flipped up, priority is arbitrarily given to set the date.  

In both cases, the code has been designed to make it impossible to enter invalid times and dates. Also note that when moving left/right, the selection will loop back around.  

![Set Demo](./gifs/set.gif)

### Display Modes
By default (i.e. when not in set mode, i.e. when all switches are down), the clock will display the full time `hr:min:sec` in 24-hour format. All four push buttons can be used to toggle different display modes:
- `KEY3` : toggles 12-hour format
- `KEY2` : toggles the display of the seconds digit
    - when showing time in 24-hour format, this will blank `HEX1` and `HEX0`
    - when showing time in 12-hour format, this will show either `AM` or `PM` depending on the time
- `KEY1` : displays the date for two seconds 
- `KEY0` : toggles blanking all six hex displays

![Mode Demo](./gifs/modes.gif)

## File Details 
```bash
AssemblyClock
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
├── gifs
│   ├── demo.gif
│   ├── modes.gif
│   └── set.gif
├── pdex
└── subroutines
    ├── date.asm
    ├── display.asm
    ├── set_mode.asm
    └── time.asm
```
- `a` is a script used to compile the assembly code into a .hex and .lst file by calling 'a51'.
- `b` is a script used to upload the .hex to the board by calling 'pdex'.
- `MODDE0CV` contains register definitions.
- `clock.asm` contains the main code, which itself calls all the files in the subroutine directory.
- `backup/clock_backup.asm` contains a backup of the code, all in a single file.
- `gifs/` contains gifs used in the README
