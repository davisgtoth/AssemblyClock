;------------------------------------------------------------------------------
; Filename: time.asm
; Author: Davis Toth
; Date: 2024-09-07
; Description: This file contains subroutines related to timekeeping of the 
;              clock, including a delay subroutine used to keep track of time 
;              and a subroutine to increment the time.
;------------------------------------------------------------------------------
$NOLIST

; variables to calcualte timing reload
XTAL equ 33333333
FREQ equ 100
RELOAD_TIMER_10ms equ 65536 - (XTAL/(12*FREQ))

CSEG

; Subroutine: wait10ms 
; Description: uses timer 0 to wait 10ms
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

; Subroutine: incTime
; Description: increments the time by 1 second, adjusting minutes, hours, and date as needed
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
    lcall set_twelve_hour 
    ret
incTime_ret1:  
    mov time+0, a
    ret
incTime_ret2:
    mov time+1, a
    ret
incTime_ret3:
    mov time+2, a
    lcall set_twelve_hour
    ret

set_twelve_hour:
    clr c
    mov a, time+2
    subb a, #12H ; do hour - 12, result in acc
    jc set_twelve_hour_am ; if carry is set, hour < 12 so carry set = AM, carry cleared = PM
    cjne a, #0, set_twelve_hour_pm ; if hour - 12 = 0, is 12 pm
    mov twelve_hour, #12H
    setb pm_flag
    ret
set_twelve_hour_am:
    clr pm_flag
    mov a, time+2
    cjne a, #0, set_twelve_hour_am_not_zero 
    mov twelve_hour, #12H ; 00 in 24-hour format = 12 AM
    ret
set_twelve_hour_am_not_zero:
    mov twelve_hour, time+2 ; if hour < 12 and not 0, is same as 24-hour format
    ret
set_twelve_hour_pm:
    setb pm_flag
    mov R3, a ; store result of hour - 12 in R3
    ; check if LSD is greater than 9, if so, subtract 6 to adjust to valid BCD
    anl a, #0FH
    subb a, #0AH ; carry already cleared because PM
    jc set_twelve_hour_pm_continue
    mov a, R3
    subb a, #06H ; carry cleared because jc set_twelve_hour_pm_continue didn't jump
    mov twelve_hour, a
    ret
set_twelve_hour_pm_continue:
    mov twelve_hour, R3
    ret

$LIST