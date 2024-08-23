;------------------------------------------------------------------------------
; Filename: set_mode.asm
; Author: Davis Toth
; Date: 2024-08-22
; Description: 
;------------------------------------------------------------------------------
$NOLIST

CSEG

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

$LIST