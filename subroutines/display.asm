;------------------------------------------------------------------------------
; Filename: display.asm
; Author: Davis Toth
; Date: 2024-09-07
; Description: This file contains subroutines and macros related to displaying 
;              the time and date on the 7-segment displays. This includes a 
;              macro that displays a BCD number, a subroutine that displays the
;              time/date in various formats, and a subroutine that displays the
;              time/date when in set mode.
;------------------------------------------------------------------------------
$NOLIST

CSEG

; Macro: showBCD
; Description: displays a two digit BCD number on the 7-seg displays
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

; Subroutine: display
; Description: shows the time/date on the 7-seg displays in various formats
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
    showBCD(twelve_hour, HEX4, HEX5) ; show hr
    showBCD(time+1, HEX2, HEX3) ; show min
    jb hide_sec, display_twelve_no_sec
    showBCD(time+0, HEX0, HEX1) ; show sec
    ret
display_twelve_no_sec:
    mov HEX0, #0C8H ; display M
    jb pm_flag, display_twelve_no_sec_pm
    mov HEX1, #88H ; display A
    ret
display_twelve_no_sec_pm:
    mov HEX1, #8CH ; display P
    ret

; Subroutine: display_set
; Description: shows the time/date on the 7-seg displays when in set mode
;              flashing the selected digit (pair of hex displays) on/off
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

$LIST