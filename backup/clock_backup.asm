;------------------------------------------------------------------------------
; Filename: clock_backup.asm
; Author: Davis Toth
; Date: 2024-08-22
; Description: This file contains a backup of the clock program with all 
;              functionality implemented in this one file. 
;------------------------------------------------------------------------------
$MODDE0CV 

org 0000H
    ljmp init

;------------------------------------------------------------------------------
; Data Section: Variables, flags, and BCD to 7-segment lookup table
;------------------------------------------------------------------------------

; variables to calcualte timing reload
XTAL equ 33333333 ; variables to calcualte timing reload
FREQ equ 100
RELOAD_TIMER_10ms equ 65536 - (XTAL/(12*FREQ))

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

; Look-up table for 7-seg displays
; note: segments turn on with logic 0
cseg
myLUT: 
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9


;------------------------------------------------------------------------------
; Subroutines and Macros
;------------------------------------------------------------------------------

; Subroutine: wait10ms - uses timer 0 to wait 10ms
; Modifies: TR0, TH0, TL0, TF0
; Reads: RELOAD_TIMER_10ms
wait10ms:
    clr TR0
    mov TH0, #high(RELOAD_TIMER_10ms)
    mov TL0, #low(RELOAD_TIMER_10ms)
    clr TF0
    setb TR0
    jnb TF0, $
    ret

; Macro: showBCD - displays a two digit BCD number on the 7-seg displays
; Inputs: %0 - the register/variable containing a BCD number to display
;         %1 - the HEX display to show the LSD
;         %2 - the HEX display to show the MSD
; Modifies: a, %1, %2
; Notes: the dptr must point to the lookup table before calling this macro
showBCD MAC
	; Display LSD
    mov a, %0
    anl a, #0FH
    movc a, @a+dptr
    mov %1, a
	; Display MSD
    mov a, %0
    swap a
    anl a, #0FH
    movc a, @a+dptr
    mov %2, a
ENDMAC

; Subroutine: display - shows the time/date on the 7-seg displays in various formats
; Reads: time+0, time+1, time+2, date+0, date+1, date+2, blank, disp_date, twelve, hide_sec
; Modifies: a, dptr, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
; Formats: 
;   - default: displays the full time (sec, min, hr) in 24-hour format
;       - no sec: turns off the second counter, blanks HEX0 and HEX1
;   - twelve: displays the full time (sec, min, hr) in 12-hour format
;       - no sec: turns off the second counter, displays AM/PM instead
;       - modifies: c, R3 
;   - blank: blanks all 7-seg displays, given priority over all other display modes
;   - date: displays the date in the form MM/DD/YY 
display:
	mov dptr, #myLUT
    jb blank, display_blank 
    jb disp_date, display_date
    jb twelve, display_twelve
    showBCD(time+2, HEX4, HEX5) ; show hr
    showBCD(time+1, HEX2, HEX3) ; show min
    jb hide_sec, display_no_sec
    showBCD(time+0, HEX0, HEX1) ; show sec
    ret

display_no_sec:
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    ret

display_blank:
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    mov HEX4, #0FFH
    mov HEX5, #0FFH
    ret

display_date:
    showBCD(date+2, HEX0, HEX1) ; show YY
    showBCD(date+0, HEX2, HEX3) ; show DD
    showBCD(date+1, HEX4, HEX5) ; show MM
    ret

display_twelve:
    showBCD(time+1, HEX2, HEX3) ; show min
    clr c
    mov a, time+2
    subb a, #12H ; do hour - 12, result in a
    jc display_twelve_am ; if carry is set, hour < 12 so carry set = AM, carry cleared = PM (if not dispalying seconds)
    cjne a, #0, display_twelve_pm ; if hour - 12 = 0, is exactly 12PM
    showBCD(#12H, HEX4, HEX5) ; show 12 for hr
    sjmp display_twelve_sec
display_twelve_pm:
    ; check if LSD is greater than 9, if so, subtract 6 to adjust to valid BCD
    mov R3, a
    anl a, #0FH
    subb a, #0AH ; carry already cleared because PM
    jc display_twelve_pm_continue
    mov a, R3
    subb a, #06H ; carry cleared because jc display_twelve_pm_continue didn't jump
    mov R3, a
display_twelve_pm_continue:
    showBCD(R3, HEX4, HEX5) ; show hr adjusted for pm
    clr c ; make sure set to PM for later
    sjmp display_twelve_sec
display_twelve_am:
    mov a, time+2
    cjne a, #0, display_twelve_am_not_zero
    showBCD(#12H, HEX4, HEX5) ; show 12 for hr, is 12 AM = 00 in 24-hour format
    setb c ; cjne modifies carry, make sure set to AM for later
    sjmp display_twelve_sec
display_twelve_am_not_zero:
    setb c ; cjne modifies carry, make sure set to AM for later
    showBCD(time+2, HEX4, HEX5) ; show hr with no modifications for AM (if not 00)
display_twelve_sec:
    jb hide_sec, display_twelve_ampm
    showBCD(time+0, HEX0, HEX1) ; show sec
    ret
display_twelve_ampm:
    mov HEX0, #0C8H ; display M
    jc display_twelve_show_am ; if carry set, is AM
    mov HEX1, #8CH ; display P
    ret
display_twelve_show_am:
    mov HEX1, #88H ; display A
    ret

; Subroutine: display_set - shows the time/date on the 7-seg displays when in set mode
;                           flashing the selected digit (pair of hex displays) on/off
; Modifies: a, dptr, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
; Reads: time+0, time+1, time+2, date+0, date+1, date+2, R1, flash_flag, SWA.1
; Notes:
;   - R1 is used to determine which digit is currently selected
;       - 0 = sec/year (HEX0 and HEX1)
;       - 1 = min/day (HEX2 and HEX3)
;       - 2 = hr/month (HEX4 and HEX5)
;       - all other values undefined 
;   - Date is given priority over time if both switch 0 and 1 are on
;   - If flash_flag set, the selected digit will be blanked 
display_set:
    mov dptr, #myLUT
    cjne R1, #0, flash_hex23
flash_hex01:
    jb SWA.1, flash_hex01_L1
    showBCD(time+1, HEX2, HEX3)
    showBCD(time+2, HEX4, HEX5)
    sjmp flash_hex01_L2
flash_hex01_L1:
    showBCD(date+0, HEX2, HEX3)
    showBCD(date+1, HEX4, HEX5)
flash_hex01_L2:
    jb flash_flag, flash_hex01_off
    jb SWA.1, flash_hex01_L3
    showBCD(time+0, HEX0, HEX1)
    ret
flash_hex01_L3:
    showBCD(date+2, HEX0, HEX1)
    ret
flash_hex01_off:
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    ret
flash_hex23:
    cjne R1, #1, flash_hex45
    jb SWA.1, flash_hex23_L1
    showBCD(time+0, HEX0, HEX1)
    showBCD(time+2, HEX4, HEX5)
    sjmp flash_hex23_L2
flash_hex23_L1:
    showBCD(date+2, HEX0, HEX1)
    showBCD(date+1, HEX4, HEX5)
flash_hex23_L2:
    jb flash_flag, flash_hex23_off
    jb SWA.1, flash_hex23_L3
    showBCD(time+1, HEX2, HEX3)
    ret
flash_hex23_L3:
    showBCD(date+0, HEX2, HEX3)
    ret
flash_hex23_off:
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    ret
flash_hex45:
    jb SWA.1, flash_hex45_L1
    showBCD(time+0, HEX0, HEX1)
    showBCD(time+1, HEX2, HEX3)
    sjmp flash_hex45_L2
flash_hex45_L1:
    showBCD(date+0, HEX2, HEX3)
    showBCD(date+2, HEX0, HEX1)
flash_hex45_L2:
    jb flash_flag, flash_hex45_off
    jb SWA.1, flash_hex45_L3
    showBCD(time+2, HEX4, HEX5)
    ret
flash_hex45_L3:
    showBCD(date+1, HEX4, HEX5)
    ret
flash_hex45_off:
    mov HEX4, #0FFH
    mov HEX5, #0FFH
    ret

; Subroutine: incTime - increments the time by 1 second, adjusting minutes, hours, and date as needed
; Modifies: a, time+0, time+1, time+2, date+0, date+1, date+2
incTime:
    mov a, time+0
    add a, #1
    da a
    cjne a, #60H, incTime_ret1
    mov time+0, #0
    mov a, time+1
    add a, #1
    da a
    cjne a, #60H, incTime_ret2
    mov time+1, #0
    mov a, time+2
    add a, #1
    da a
    cjne a, #24H, incTime_ret3
    lcall incDate ; increment the date by 1 day 
    mov time+2, #0
    ret
incTime_ret1:  
    mov time+0, a
    ret
incTime_ret2:
    mov time+1, a
    ret
incTime_ret3:
    mov time+2, a
    ret

; Subroutine: set_num_days - sets the number of days in the current month
; Modifies: a, num_days
; Reads: date+1, date+2
set_num_days:
    mov a, date+1
    cjne a, #02H, set_num_days_not_feb
    ; February edge case, check if leap year (i.e. if year / 4 has no remainder)
    mov a, date+2
    mov b, #4
    div ab ; remainder in b, leap year if b=0
    mov a, b
    cjne a, #0, set_num_days_no_leap
    mov num_days, #30H ; 29 day month, compare to 30 for overflow 
    ret
set_num_days_no_leap:
    mov num_days, #29H ; 28 day month, compare to 29 for overflow
    ret
set_num_days_not_feb:
    anl a, #10H
    cjne a, #10H, set_num_days_month_under_10 ; handle months under 10 separately
    mov a, date+1
    anl a, #1 ; months >= 10 with 30 days have LSB set
    cjne a, #0, set_num_days_30 
    sjmp set_num_days_31
set_num_days_month_under_10:
    mov a, date+1
    anl a, #1001B ; months < 10 with 30 days will either have 0000 or 1001 after this operation
    cjne a, #0, set_num_days_31
set_num_days_30:
    mov num_days, #31H ; 30 day month, compare to 31 for overflow
    ret
set_num_days_31:
    cjne a, #1001B, set_num_days_31_continue ; 1001 edge case
    sjmp set_num_days_30
set_num_days_31_continue:
    mov num_days, #32H ; 31 day month, compare to 32 for overflow
    ret

; Subroutine: incDate - increments the date by 1 day, adjusting the month and year as needed
; Modifies: a, date+0, date+1, date+2
; Reads: num_days
incDate:
    mov a, date+0
    add a, #1
    da a
    cjne a, num_days, incDate_ret1
    mov date+0, #1
    mov a, date+1
    add a, #1
    da a
    cjne a, #13H, incDate_ret2
    mov date+1, #1 ; num_days is same for Dec and Jan, so no need to update
    mov a, date+2
    add a, #1
    da a
    cjne a, #0A0H, incDate_ret3 ; A0H = 100 in BCD, year resets from 99 to 00
    clr a
    sjmp incDate_ret3
incDate_ret1:
    mov date+0, a
    ret
incDate_ret2:
    mov date+1, a
    lcall set_num_days ; update num_days for new month
    ret
incDate_ret3:
    mov date+2, a
    ret

; Subroutine: check_days - checks if the date is valid for the current month, adjusting as needed           
; Modifies: a, c, date+0
; Reads: date+0, num_days
; Notes: used to not allow invalid dates when setting the date
check_days:
    lcall set_num_days
    mov a, num_days
    clr c
    subb a, date+0 ; (num days in current month + 1) - current day value
    jc check_days_adjust ; if current day is greater than num_days + 1, carry will be set -> adjust
    cjne a, #0, check_days_ret ; also need to adjust if result is 0
check_days_adjust:
    ; set date to num_days - 1
    mov a, num_days
    cjne a, #30H, check_days_adjust_L1
    mov date+0, #29H ; edge case where subtracting requires carry b/w digits, messes up BCD formatting
    ret
check_days_adjust_L1:
    clr c
    subb a, #1
    mov date+0, a
    ret
check_days_ret:
    ret

; Subroutine: adjust_digit - increments/decrements the selected digit when in set mode
; Modifies: a, c, time+0, time+1, time+2, date+0, date+1, date+2, R0, R2 
; Reads: num_days, R1, SWA.1, flash_flag, dec_flag
; Notes:
;   - R1 is used to determine which digit to adjust
;       - 0 = sec/year (HEX0 and HEX1)
;       - 1 = min/day (HEX2 and HEX3)
;       - 2 = hr/month (HEX4 and HEX5)
;       - all other values undefined 
;   - Date is given priority over time if both switch 0 and 1 are on
;   - Increments digit if dec_flag is clear, decrements if set
adjust_digit:
    ; first initialize R0 and R2
    ; R2 = value of the digit being adjusted
    ; R0 = memory location of the digit being adjusted, used as pointer at end
adjust_digit_hex01:
    cjne R1, #0, adjust_hex23
    jb SWA.1, adjust_hex01_year
    mov R2, time+0 
    mov R0, #time+0
    sjmp adjust
adjust_hex01_year:
    mov R2, date+2
    mov R0, #date+2
    sjmp adjust
adjust_hex23:
    cjne R1, #1, adjust_hex45
    jb SWA.1, adjust_hex23_day
    mov R2, time+1
    mov R0, #time+1
    sjmp adjust
adjust_hex23_day:
    mov R2, date+0
    mov R0, #date+0
    sjmp adjust
adjust_hex45:
    jb SWA.1, adjust_hex45_month
    mov R2, time+2
    mov R0, #time+2
    sjmp adjust
adjust_hex45_month:
    mov R2, date+1
    mov R0, #date+1
    sjmp adjust
adjust:
    mov a, R2
    jb dec_flag, decrement
increment:
    add a, #1
    da a
    jb SWA.1, inc_date_month
    cjne R1, #2, inc_sec_min
    cjne a, #24H, adjust_ret
    clr a
    sjmp adjust_ret
inc_sec_min:
    cjne a, #60H, adjust_ret
    clr a
    sjmp adjust_ret
inc_date_month:
    cjne R1, #2, inc_date_day
    cjne a, #13H, adjust_ret
    mov a, #1
    sjmp adjust_ret
inc_date_day:
    cjne R1, #1, inc_date_year
    cjne a, num_days, adjust_ret
    mov a, #1
    sjmp adjust_ret
inc_date_year:
    cjne a, #0A0H, adjust_ret
    clr a
    sjmp adjust_ret
decrement:
    jb SWA.1, dec_date_month
    cjne a, #0, dec_L1 ; handle regular decrement at dec_L1, handle overflow here
    cjne R1, #2, dec_sec_min
    mov a, #23H
    sjmp adjust_ret
dec_sec_min:
    mov a, #59H
    sjmp adjust_ret
dec_date_month:
    cjne R1, #2, dec_date_day
    cjne a, #1, dec_L1
    mov a, #12H
    sjmp adjust_ret
dec_date_day:
    cjne R1, #1, dec_date_year
    cjne a, #1, dec_L1
    mov a, num_days ; if day is 1, subtract 1 from num_days to get loop around when decrementing
    mov R2, a
    sjmp dec_L1
dec_date_day_L1:
    clr c
    subb a, #1
    sjmp adjust_ret
dec_date_year:
    cjne a, #0, dec_L1
    mov a, #99H
    sjmp adjust_ret
dec_L1:
    ; handles edge case where decrementing requires carry between digits
    anl a, #0FH
    cjne a, #0, dec_L2 ; if LSD is not 0, decrement normally
    mov a, R2
    add a, #0F0H ; subtract 1 from MSD by adding 1111
    orl a, #09H ; set the LSD to 9
    sjmp adjust_ret
dec_L2:
    mov a, R2
    clr c
    subb a, #1
adjust_ret:
    mov @R0, a
    clr flash_flag ; cleared to immediately display updated value
    mov R0, #0 ; reset frequency of flashing on/off
    ret

; Subroutine: check_enter_set - checks if switches 0 or 1 are flipped 
; Modifies: enter_set 
; Reads: SWA.0, SWA.1
; Notes: goes into set mode if enter_set is set, shows time/date if cleared
check_enter_set:
    jb SWA.0, enter_set_mode
    jb SWA.1, enter_set_mode
    clr enter_set
    ret
enter_set_mode:
    setb enter_set
    ret

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