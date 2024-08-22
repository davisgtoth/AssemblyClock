$NOLIST

CSEG

display_set:
    cjne R1, #0, flash_min
flash_second:
    showBCD(time+1, HEX2, HEX3)
    showBCD(time+2, HEX4, HEX5)
    jb flash_flag, flash_second_off
    showBCD(time+0, HEX0, HEX1)
    ret
flash_second_off:
    mov HEX0, #7FH
    mov HEX1, #7FH
    ret
flash_min:
    cjne R1, #1, flash_hour
    showBCD(time+0, HEX0, HEX1)
    showBCD(time+2, HEX4, HEX5)
    jb flash_flag, flash_min_off
    showBCD(time+1, HEX2, HEX3)
    ret
flash_min_off:
    mov HEX2, #7FH
    mov HEX3, #7FH
    ret
flash_hour:
    showBCD(time+0, HEX0, HEX1)
    showBCD(time+1, HEX2, HEX3)
    jb flash_flag, flash_hour_off
    showBCD(time+2, HEX4, HEX5)
    ret
flash_hour_off:
    mov HEX4, #7FH
    mov HEX5, #7FH
    ret

adjust_digit:
    cjne R1, #0, adjust_min
    mov R2, time+0
    mov R0, #time+0
    sjmp adjust
adjust_min:
    cjne R1, #1, adjust_hour
    mov R2, time+1
    mov R0, #time+1
    sjmp adjust
adjust_hour:
    mov R2, time+2
    mov R0, #time+2
adjust:
    mov a, R2
    jb inc_dec_flag, decrement
increment:
    add a, #1
    da a
    cjne R1, #2, inc_sec_min
    cjne a, #24H, adjust_ret
    clr a
    sjmp adjust_ret
inc_sec_min:
    cjne a, #60H, adjust_ret
    clr a
    sjmp adjust_ret
decrement:
    cjne a, #0, dec_L1
    cjne R1, #2, dec_sec_min
    mov a, #23H
    sjmp adjust_ret
dec_sec_min:
    mov a, #59H
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
    ret

$LIST