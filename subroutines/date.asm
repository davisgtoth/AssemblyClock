;------------------------------------------------------------------------------
; Filename: date.asm
; Author: Davis Toth
; Date: 2024-08-22
; Description: 
;------------------------------------------------------------------------------
$NOLIST

CSEG

; Subroutine: set_num_days 
; Description: sets the number of days in the current month
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

; Subroutine: incDate 
; Description: increments the date by 1 day, adjusting the month and year as necessary
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

; Subroutine: check_days 
; Description: checks if the date is valid for the current month, adjusting as needed           
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

$LIST