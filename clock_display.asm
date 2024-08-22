$NOLIST

CSEG

showBCD MAC
	; Display LSD
    mov a, %0
    anl a, #0FH
    movc a, @a+dptr ; move to the accumulator the value of the look-up table plus the number
    mov %1, a
	; Display MSD
    mov a, %0
    swap a
    anl a, #0FH
    movc a, @a+dptr
    mov %2, a
ENDMAC

display:
	mov dptr, #myLUT
    jb blank, display_blank
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
    
$LIST