$MODDE0CV 

org 0000H
    ljmp init

; variables to calcualte timing reload
XTAL equ 33333333 
FREQ equ 100
RELOAD_TIMER_10ms equ 65536 - (XTAL/(12*FREQ))

; variables to store time and date
dseg at 30h
time:       ds 3 ; stored in BCD, LSD to MSD: seconds, minutes, hours
date:       ds 3 ; stored in BCD, LSD to MSD: day, month, year 
num_days:   ds 1 ; number of days in the current month

bseg
blank: dbit 1 
twelve: dbit 1 
disp_sec: dbit 1 
flash_flag: dbit 1 
inc_dec_flag: dbit 1 

$include(clock_display.asm)
$include(clock_set.asm)

cseg
myLUT: ; Look-up table for 7-seg displays
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

wait10ms:
    clr TR0
    mov TH0, #high(RELOAD_TIMER_10ms)
    mov TL0, #low(RELOAD_TIMER_10ms)
    clr TF0
    setb TR0
wait10ms_L0:
    jnb TF0, wait10ms_L0
    ret

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
    mov a, #0
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

init:
    mov sp, #07FH ; set stack pointer
    mov TMOD, #00000001B ; set timer 0 mode 1
    clr a
	mov LEDRA, a ; clear LEDs
	mov LEDRB, a
    mov R0, a ; register 0 used to count 10ms delays
    mov R1, a ; register 1 bits used for <fill in later>
    mov time+0, a ; clear the time variable
    mov time+1, a
    mov time+2, a
    mov date+0, a
    mov date+1, a
    mov date+2, a
    clr blank
    clr twelve
    clr disp_sec
    sjmp main

main:
    lcall wait10ms
check_set:
    jb SWA.0, set_mode
check_blank:
    jb KEY.3, check_twelve
    jnb KEY.3, $
    cpl blank
check_twelve:
    jb KEY.2, check_disp_sec
    jnb KEY.2, $
    cpl twelve
check_disp_sec:
    jb KEY.1, main_continue
    jnb KEY.1, $
    cpl disp_sec
main_continue:
    lcall display
    inc R0
    cjne R0, #100, main
    lcall incTime
    mov R0, #0
    sjmp main

set_mode:
    mov R0, #0
    mov R1, #0
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
    clr inc_dec_flag
    lcall adjust_digit
check_dec:
    jb KEY.1, set_mode_continue
    jnb KEY.1, $
    setb inc_dec_flag
    lcall adjust_digit
set_mode_continue:
    lcall display_set
    inc R0
    jnb SWA.0, main
    cjne R0, #40, set_mode_loop
    cpl flash_flag
    mov R0, #0
    sjmp set_mode_loop
END