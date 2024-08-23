;------------------------------------------------------------------------------
; Filename: time.asm
; Author: Davis Toth
; Date: 2024-08-22
; Description: 
;------------------------------------------------------------------------------
$NOLIST

; variables to calcualte timing reload
XTAL equ 33333333
FREQ equ 100
RELOAD_TIMER_10ms equ 65536 - (XTAL/(12*FREQ))

CSEG

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

$LIST