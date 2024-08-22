;------------------------------------------------------------------------------
; Filename: clock_backup.asm
; Author: Davis Toth
; Date: 2024-08-22
; Description: This file contains a backup of the clock program with all 
;              functionality implemented in a single file. 
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
time:       ds 3 ; stored in BCD, LSD to MSD: seconds, minutes, hours
date:       ds 3 ; stored in BCD, LSD to MSD: day, month, year 
num_days:   ds 1 ; number of days in the current month

; flags for various uses
bseg
twelve:         dbit 1 ; when set, displays time in 12-hour format
disp_sec:       dbit 1 ; when set, doesn't display seconds - blanks HEX0 and HEX1 if in 24-hour mode, shows AM/PM if in 12-hour mode
disp_date:      dbit 1 ; when set, displays the date instead of the time in the form MM/DD/YY
blank:          dbit 1 ; when set, blanks the hex displays
enter_set:      dbit 1 ; flag used to enter the set mode
flash_flag:     dbit 1 ; flag used to flash the hex displays when setting the time/date
dec_flag:       dbit 1 ; flag used to decrement the digit when setting the time/date

; Look-up table for 7-seg displays
cseg
myLUT: 
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

;------------------------------------------------------------------------------
; Subroutines and Macros
;------------------------------------------------------------------------------

; Subroutine: uses timer 0 to wait 10ms
wait10ms:
    clr TR0
    mov TH0, #high(RELOAD_TIMER_10ms)
    mov TL0, #low(RELOAD_TIMER_10ms)
    clr TF0
    setb TR0
    jnb TF0, $
    ret

; Macro: displays a two digit BCD number on the 7-seg displays
; Inputs: %0 - the register/variable containing a BCD number to display
;         %1 - the HEX display to show the LSD
;         %2 - the HEX display to show the MSD
; Modifies: a, %1, %2
; Note: the dptr must point to the lookup table before calling this macro
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

; Subroutine: displays the time or date on the 7-seg displays
display:
	mov dptr, #myLUT
    jb blank, display_blank
    jb disp_date, display_date    
    jb twelve, display_twelve
    showBCD(time+2, HEX4, HEX5)
    showBCD(time+1, HEX2, HEX3)
    jb disp_sec, display_no_sec
    showBCD(time+0, HEX0, HEX1)
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
    showBCD(date+2, HEX0, HEX1)
    showBCD(date+0, HEX2, HEX3)
    showBCD(date+1, HEX4, HEX5)
    ret

display_twelve:
    showBCD(time+1, HEX2, HEX3) ; show minutes
    clr c
    mov a, time+2
    subb a, #12H ; do hour - 12
    jc display_twelve_am ; if carry is set, hour < 12
    cjne a, #0, display_twelve_pm ; if hour - 12 = 0, display 12
    showBCD(#12H, HEX4, HEX5)
    sjmp display_twelve_sec
display_twelve_pm:
    mov R3, a
    anl a, #0FH
    subb a, #0AH
    jc display_twelve_pm_continue
    mov a, R3
    subb a, #06H
    mov R3, a
display_twelve_pm_continue:
    showBCD(R3, HEX4, HEX5)
    clr c
    sjmp display_twelve_sec
display_twelve_am:
    mov a, time+2
    cjne a, #0, display_twelve_am_not_zero
    showBCD(#12H, HEX4, HEX5)
    setb c
    sjmp display_twelve_sec
display_twelve_am_not_zero:
    setb c
    showBCD(time+2, HEX4, HEX5)
display_twelve_sec:
    jb disp_sec, display_twelve_ampm
    showBCD(time+0, HEX0, HEX1)
    ret
display_twelve_ampm:
    mov HEX0, #0C8H
    jc display_twelve_show_am
    mov HEX1, #8CH
    ret
display_twelve_show_am:
    mov HEX1, #88H
    ret

; Subroutine: 
display_set:
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
    mov HEX0, #7FH
    mov HEX1, #7FH
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
    mov HEX2, #7FH
    mov HEX3, #7FH
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
    mov HEX4, #7FH
    mov HEX5, #7FH
    ret

; Subroutine: increments the time by 1 second
incTime:
    mov a, time+0
    add a, #1
    da a
    cjne a, #60H, incTime_ret1 ; compare to 60 in BCD
    clr a
    mov time+0, a
    mov a, time+1
    add a, #1
    da a
    cjne a, #60H, incTime_ret2 ; compare to 60 in BCD
    clr a
    mov time+1, a
    mov a, time+2
    add a, #1
    da a
    cjne a, #24H, incTime_ret3 ; compare to 24 in BCD
    lcall incDate
    clr a
    mov time+2, a
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

; Subroutine: 
set_num_days:
    mov a, date+1
    cjne a, #02H, set_num_days_not_feb
    mov a, date+2
    mov b, #4
    div ab ; remainder in b, leap year if b=0
    mov a, b
    cjne a, #0, set_num_days_no_leap
    mov num_days, #30H ; 29 days, compare to 30 for leap year feb
    ret
set_num_days_no_leap:
    mov num_days, #29H ; 28 days, compare to 29
    ret
set_num_days_not_feb:
    anl a, #10H
    cjne a, #10H, set_num_days_month_under_10
    mov a, date+1
    anl a, #1
    cjne a, #0, set_num_days_30
    sjmp set_num_days_31
set_num_days_month_under_10:
    mov a, date+1
    anl a, #1001B
    cjne a, #0, set_num_days_31
    sjmp set_num_days_30
set_num_days_30:
    mov num_days, #31H ; 30 days, compare to 31
    ret
set_num_days_31:
    cjne a, #1001B, set_num_days_31_continue ; September edge case
    sjmp set_num_days_30
set_num_days_31_continue:
    mov num_days, #32H ; 31 days, compare to 32
    ret

; Subroutine: increments the date by 1 day
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
    mov date+1, #1
    mov a, date+2
    add a, #1
    da a
    cjne a, #0A0H, incDate_ret3 ; A0H = 100 in BCD
    clr a
    sjmp incDate_ret3
incDate_ret1:
    mov date+0, a
    ret
incDate_ret2:
    mov date+1, a
    lcall set_num_days
    ret
incDate_ret3:
    mov date+2, a
    ret

; Subroutine: checks if the date is valid
check_days:
    lcall set_num_days
    mov a, num_days
    clr c
    subb a, date+0
    jc check_days_adjust
    cjne a, #0, check_days_ret
check_days_adjust:
    mov a, num_days
    cjne a, #30H, check_days_adjust_L1
    mov date+0, #29H
    ret
check_days_adjust_L1:
    clr c
    subb a, #1
    mov date+0, a
    ret
check_days_ret:
    ret

; Subroutine: adjusts the time or date when setting
adjust_digit:
    cjne R1, #0, adjust_min
    jb SWA.1, adjust_year
    mov R2, time+0
    mov R0, #time+0
    sjmp adjust
adjust_year:
    mov R2, date+2
    mov R0, #date+2
    sjmp adjust
adjust_min:
    cjne R1, #1, adjust_hour
    jb SWA.1, adjust_date
    mov R2, time+1
    mov R0, #time+1
    sjmp adjust
adjust_date:
    mov R2, date+0
    mov R0, #date+0
    sjmp adjust
adjust_hour:
    jb SWA.1, adjust_month
    mov R2, time+2
    mov R0, #time+2
    sjmp adjust
adjust_month:
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
    cjne a, #0, dec_L1
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
    mov a, num_days
    cjne a, #30H, dec_date_day_L1
    mov a, #29H
    sjmp adjust_ret
dec_date_day_L1:
    clr c
    subb a, #1
    sjmp adjust_ret
dec_date_year:
    cjne a, #0, dec_L1
    mov a, #99H
    sjmp adjust_ret
dec_L1:
    anl a, #0FH
    cjne a, #0, dec_L2
    mov a, R2
    add a, #0F0H
    orl a, #09H
    sjmp adjust_ret
dec_L2:
    mov a, R2
    clr c
    subb a, #1
adjust_ret:
    mov @R0, a
    clr flash_flag
    mov R0, #0
    lcall check_days
    ret

; Subroutine:
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
    mov R1, a ; register 1 bits used for <fill in later>
    mov time+0, a ; clear the time variable
    mov time+1, a
    mov time+2, a
    mov date+0, #01H
    mov date+1, #01H
    mov date+2, #00H
    lcall set_num_days
    clr blank
    clr twelve
    clr disp_sec
    sjmp main

; Main loop
main:
    lcall wait10ms
check_set:
    lcall check_enter_set
    jb enter_set, set_mode
check_twelve:
    jb KEY.3, check_disp_sec
    jnb KEY.3, $
    cpl twelve
check_disp_sec:
    jb KEY.2, check_disp_date
    jnb KEY.2, $
    cpl disp_sec
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
    lcall display
    inc R0
    jnb disp_date, main_date_continue
    inc R4
    cjne R4, #200, main_date_continue ; display date for 2 seconds
    clr disp_date
main_date_continue:
    cjne R0, #99, main ; 99 cyles of waiting 10ms, allot 10ms to account for time for code to executue 
    lcall incTime
    mov R0, #0
    sjmp main

; Set mode
set_mode:
    mov R0, #0
    mov R1, #0
    clr disp_date
    setb flash_flag
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
    lcall set_num_days
check_dec:
    jb KEY.1, set_mode_continue
    jnb KEY.1, $
    setb dec_flag
    lcall adjust_digit
    lcall set_num_days
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