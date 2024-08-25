;------------------------------------------------------------------------------
; Filename: clock.asm
; Author: Davis Toth
; Date: 2024-08-25
; Description: This assembly program is designed to implement a digital clock
;              on the Terasic DE0-CV FPGA board. The clock supports both 24-hour
;              and 12-hour time formats and can display the date on the 6 buit-in
;              7-segment displays. The time and date can be set using the switches
;              and buttons on the board. The clock also has a features to blank the
;              displays and hide the seconds. The program uses several subroutines
;              to handle timekeeping, datekeeping, display, and setting the time/date.
;              This file contains the main program loop for both normal operation
;              and setting the time/date.
;------------------------------------------------------------------------------
$MODDE0CV 

org 0000H
    ljmp init

;------------------------------------------------------------------------------
; Data Section: Variables, flags, and BCD to 7-segment lookup table
;------------------------------------------------------------------------------

; variables to store time and date
dseg at 30h
time:       ds 3 ; stored in BCD in 24-hour format, LSD to MSD: seconds, minutes, hours
date:       ds 3 ; stored in BCD, LSD to MSD: day, month, year 
num_days:   ds 1 ; number of days in the current month + 1 to compare for overflow

; flags for various uses
bseg
twelve:         dbit 1 ; when set, displays time in 12-hour format
hide_sec:       dbit 1 ; when set, doesn't display seconds - blanks HEX0 and HEX1 if in 24-hour mode, shows AM/PM if in 12-hour mode
disp_date:      dbit 1 ; when set, displays the date instead of the time in the form MM/DD/YY
blank:          dbit 1 ; when set, blanks the hex displays
enter_set:      dbit 1 ; flag used to enter the set mode
flash_flag:     dbit 1 ; flag used to flash the hex displays when setting the time/date
dec_flag:       dbit 1 ; flag used to decrement the digit when setting the time/date

; subroutine files included
$include(subroutines/time.asm)
$include(subroutines/date.asm)
$include(subroutines/display.asm)
$include(subroutines/set_mode.asm)

; Look-up table for 7-seg displays
; note: segments turn on with logic 0
cseg
myLUT: ; Look-up table for 7-seg displays
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

;------------------------------------------------------------------------------
; Main Program
;------------------------------------------------------------------------------

; Initialization
init:
    mov sp, #07FH ; set stack pointer
    mov TMOD, #00000001B ; set timer 0 to mode 1
    clr a
	mov LEDRA, a ; clear LEDs
	mov LEDRB, a
    mov R0, a ; register 0 used to count 10ms delays
    mov time+0, a ; initialize the time to 00:00:00
    mov time+1, a
    mov time+2, a
    mov date+0, #01H ; initialize the date to 01/01/00
    mov date+1, #01H
    mov date+2, #00H
    lcall set_num_days ; initialize num_days
    clr twelve ; clear all flags
    clr hide_sec
    clr disp_date
    clr blank 
    clr enter_set
    clr flash_flag
    clr dec_flag
    sjmp main

; Main loop - counts and displays time, checks for inputs from buttons modifying flags accordingly
; Notes:
;   - R0 used to count 10ms delays
;   - R4 used to count 10ms delays for displaying date for 2 seconds
;   - KEY3 = 12/24 hour format, KEY2 = hide seconds/show AM/PM, KEY1 = display date, KEY0 = blank the 7-seg displays
;   - enters set mode from enter_set flag, i.e. if either switch 0 or 1 is flipped
main:
    lcall wait10ms
check_set:
    lcall check_enter_set
    jb enter_set, set_mode
check_twelve:
    jb KEY.3, check_hide_sec
    jnb KEY.3, $
    cpl twelve
check_hide_sec:
    jb KEY.2, check_disp_date
    jnb KEY.2, $
    cpl hide_sec
check_disp_date:
    jb KEY.1, check_blank
    jnb KEY.1, $
    setb disp_date
    mov R4, #0
check_blank:
    jb KEY.0, main_continue
    jnb KEY.0, $
    cpl blank
main_continue:
    jnb disp_date, main_no_date
    inc R4
    cjne R4, #200, main_no_date ; 200 * 10ms = 2 seconds
    clr disp_date
main_no_date:
    lcall display
    inc R0
    cjne R0, #100, main ; 100 * 10ms = 1 second
    lcall incTime
    mov R0, #0
    sjmp main

; Set mode - allows the user to set the time and date
; Notes:
;   - R0 is used to count 10ms delays, 
;   - R1 is used to determine which digit is currently selected to be set
;       - 0 = sec/year (HEX0 and HEX1)
;       - 1 = min/day (HEX2 and HEX3)
;       - 2 = hr/month (HEX4 and HEX5)
;       - all other values undefined 
;   - KEY3 = move left, KEY2 = increment, KEY1 = decrement, KEY0 = move right
;   - returns to main if enter_set flag is cleared, i.e. both switches 0 and 1 are off
set_mode:
    mov R0, #0 
    mov R1, #0 ; initialize selected digit to sec/year
    clr disp_date ; if enters set mode while displaying date, will stop and flash time/date
    setb flash_flag ; starts by having sec/year off 
set_mode_loop:
    lcall wait10ms
check_left:
    jb KEY.3, check_right
    jnb KEY.3, $
    inc R1
    cjne R1, #3, check_right
    mov R1, #0
check_right:
    jb KEY.0, check_inc
    jnb KEY.0, $
    dec R1
    cjne R1, #0FFH, check_inc
    mov R1, #2
check_inc:
    jb KEY.2, check_dec
    jnb KEY.2, $
    clr dec_flag
    lcall adjust_digit
    lcall set_num_days ; update num_days in case month was changed to not display invalid date
check_dec:
    jb KEY.1, set_mode_continue
    jnb KEY.1, $
    setb dec_flag
    lcall adjust_digit
    lcall set_num_days ; update num_days in case month was changed to not display invalid date
set_mode_continue:
    lcall display_set
    inc R0
    lcall check_enter_set
    jnb enter_set, set_mode_exit
    cjne R0, #40, set_mode_loop
    cpl flash_flag
    mov R0, #0
    sjmp set_mode_loop
set_mode_exit:
    ljmp main
END