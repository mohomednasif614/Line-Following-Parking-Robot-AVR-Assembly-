;ESD - Line following robot 
;Group 09
;IT23736900 - Mohomed Nasif
;IT23690370 - Elisha Y. Perera
;========================================================

.include "m328pdef.inc"

;================ REGISTERS =================
.def temp          = r16   ; temporary register
.def sensor        = r17   ; 3-bit sensor pattern
.def spdLeft       = r18   ; left motor speed
.def spdRight      = r19   ; right motor speed
.def modeReg       = r20   ; current mode
.def crossCnt      = r21   ; cross line counter
.def flagsReg      = r22   ; marker flag register
.def irCnt         = r23   ; IR detection counter
.def irBlockCnt    = r24   ; IR delay block
.def delayOuter    = r25   ; parking delay counter
.def releaseCnt    = r26   ; release confirm counter
.def crossConfirm  = r27   ; cross confirm counter
.def parkFollowCnt = r29   ; parking forward counter

;================ MODES =================
.equ MODE_NORMAL  = 0
.equ MODE_SLOW    = 1
.equ MODE_PARK    = 2

;================ FLAGS =================
.equ FLAG_ON_MARKER = 0

;================ SPEED VALUES =================
.equ NORMAL_SPEED_L = 80
.equ NORMAL_SPEED_R = 130

.equ SLOW_SPEED_L = 50
.equ SLOW_SPEED_R = 55

;================ RESET =================
.org 0x0000
    rjmp RESET

RESET:
    ; Stack pointer initialize
    ldi temp, HIGH(RAMEND)
    out SPH, temp
    ldi temp, LOW(RAMEND)
    out SPL, temp

    ; Motor pins output
    ldi temp, (1<<PD2)|(1<<PD4)|(1<<PD5)|(1<<PD6)|(1<<PD7)
    out DDRD, temp

    ldi temp, (1<<PB0)|(1<<PB1)
    out DDRB, temp

    ; Sensor pins input
    ldi temp, 0x00
    out DDRC, temp
    out PORTC, temp

    ; IR pin input
    cbi DDRD, PD3
    cbi PORTD, PD3

    ; Enable motor driver
    sbi PORTB, PB1

    ; PWM setup
    ldi temp, (1<<COM0A1)|(1<<COM0B1)|(1<<WGM01)|(1<<WGM00)
    out TCCR0A, temp

    ldi temp, (1<<CS01)|(1<<CS00)
    out TCCR0B, temp

    clr temp
    out OCR0A, temp
    out OCR0B, temp

    ; Initialize variables
    ldi modeReg, MODE_NORMAL
    clr crossCnt
    clr flagsReg
    clr irCnt
    clr irBlockCnt
    clr delayOuter
    clr releaseCnt
    clr crossConfirm
    clr parkFollowCnt

;================ MAIN LOOP =================
MAIN_LOOP:
    rcall READ_SENSORS        ; read sensors
    rcall HANDLE_TRANSITIONS  ; check mode changes

    ; Mode selection
    cpi modeReg, MODE_NORMAL
    breq NORMAL_LINE_FOLLOW

    cpi modeReg, MODE_SLOW
    breq SLOW_LINE_FOLLOW

    cpi modeReg, MODE_PARK
    breq PARKING_MODE

    rjmp NORMAL_LINE_FOLLOW

;================ SENSOR READ =================
READ_SENSORS:
    in temp, PINC
    andi temp, 0x07      ; use PC0-PC2 only

    clr sensor

    sbrc temp, PC0
    ori sensor, 0b100

    sbrc temp, PC1
    ori sensor, 0b010

    sbrc temp, PC2
    ori sensor, 0b001

    ret

;================ MODE CHANGE =================
HANDLE_TRANSITIONS:
    cpi modeReg, MODE_PARK
    breq HT_EXIT

    rcall CHECK_CROSS_COUNT

    cpi modeReg, MODE_SLOW
    brne HT_EXIT

    tst irBlockCnt
    breq HT_IR_ALLOWED

    dec irBlockCnt
    rjmp HT_EXIT

HT_IR_ALLOWED:
    rcall CHECK_IR_IN_SLOW

HT_EXIT:
    ret

;================ CROSS DETECT =================
CHECK_CROSS_COUNT:
    cpi sensor, 0b111
    brne CCC_NOT_111

    clr releaseCnt

    sbrc flagsReg, FLAG_ON_MARKER
    rjmp CCC_EXIT

    inc crossConfirm
    cpi crossConfirm, 2
    brlo CCC_EXIT

    clr crossConfirm
    sbr flagsReg, (1<<FLAG_ON_MARKER)
    inc crossCnt

    cpi crossCnt, 1
    breq SET_SLOW

    cpi crossCnt, 2
    breq SET_SLOW

    cpi crossCnt, 3
    breq RESET_NORMAL

    rjmp CCC_EXIT

SET_SLOW:
    ldi modeReg, MODE_SLOW
    ldi irBlockCnt, 80
    clr irCnt
    rjmp CCC_EXIT

RESET_NORMAL:
    ldi modeReg, MODE_NORMAL
    clr crossCnt
    clr irCnt
    clr irBlockCnt
    rjmp CCC_EXIT

CCC_NOT_111:
    clr crossConfirm
    inc releaseCnt
    cpi releaseCnt, 4
    brlo CCC_EXIT

    clr releaseCnt
    cbr flagsReg, (1<<FLAG_ON_MARKER)

CCC_EXIT:
    ret

;================ IR DETECT =================
CHECK_IR_IN_SLOW:
    sbic PIND, PD3
    rjmp IR_NOT_ACTIVE

    inc irCnt
    cpi irCnt, 8
    brlo IR_EXIT

    ldi modeReg, MODE_PARK
    clr irCnt
    clr irBlockCnt
    rjmp IR_EXIT

IR_NOT_ACTIVE:
    clr irCnt

IR_EXIT:
    ret

;================ NORMAL LINE FOLLOW =================
NORMAL_LINE_FOLLOW:
    cpi sensor, 0b010
    breq STRAIGHT

    cpi sensor, 0b100
    breq LEFT

    cpi sensor, 0b001
    breq RIGHT

    rjmp STRAIGHT

;================ SLOW LINE FOLLOW =================
SLOW_LINE_FOLLOW:
    cpi sensor, 0b010
    breq S_STRAIGHT

    cpi sensor, 0b100
    breq S_LEFT

    cpi sensor, 0b001
    breq S_RIGHT

    rjmp S_STRAIGHT

;================ MOVEMENTS =================
STRAIGHT:
    ldi spdLeft, NORMAL_SPEED_L
    ldi spdRight, NORMAL_SPEED_R
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

LEFT:
    ldi spdLeft, 40
    ldi spdRight, 120
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

RIGHT:
    ldi spdLeft, 120
    ldi spdRight, 40
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

S_STRAIGHT:
    ldi spdLeft, SLOW_SPEED_L
    ldi spdRight, SLOW_SPEED_R
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

S_LEFT:
    ldi spdLeft, 30
    ldi spdRight, 55
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

S_RIGHT:
    ldi spdLeft, 55
    ldi spdRight, 30
    rcall MOVE_FORWARD
    rjmp MAIN_LOOP

;================ PARKING =================
PARKING_MODE:
    rcall STOP_MOTORS
    rcall DELAY_200MS

    ; turn left
    ldi spdLeft, 100
    ldi spdRight, 120
    rcall PIVOT_LEFT
    rcall DELAY_500MS

    ; reverse
    ldi spdLeft, 70
    ldi spdRight, 90
    rcall MOVE_BACKWARD
    rcall DELAY_3000MS

    rcall FINAL_STOP

PARK_HOLD:
    rjmp PARK_HOLD

;================ MOTOR CONTROL =================
MOVE_FORWARD:
    sbi PORTB, PB1
    cbi PORTD, PD2
    sbi PORTD, PD4
    sbi PORTD, PD7
    cbi PORTB, PB0

    out OCR0B, spdLeft
    out OCR0A, spdRight
    ret

MOVE_BACKWARD:
    sbi PORTB, PB1
    sbi PORTD, PD2
    cbi PORTD, PD4
    cbi PORTD, PD7
    sbi PORTB, PB0

    out OCR0B, spdLeft
    out OCR0A, spdRight
    ret

PIVOT_LEFT:
    sbi PORTB, PB1
    sbi PORTD, PD2
    cbi PORTD, PD4
    sbi PORTD, PD7
    cbi PORTB, PB0

    out OCR0B, spdLeft
    out OCR0A, spdRight
    ret

STOP_MOTORS:
    clr temp
    out OCR0A, temp
    out OCR0B, temp
    ret

FINAL_STOP:
    clr temp
    out OCR0A, temp
    out OCR0B, temp
    cbi PORTB, PB1
    ret

;================ DELAYS =================
DELAY_200MS:
    ldi r28, 80
D1:
    rcall DELAY_2P5MS
    dec r28
    brne D1
    ret

DELAY_500MS:
    ldi r28, 200
D2:
    rcall DELAY_2P5MS
    dec r28
    brne D2
    ret

DELAY_3000MS:
    rcall DELAY_500MS
    rcall DELAY_500MS
    rcall DELAY_500MS
    rcall DELAY_500MS
    rcall DELAY_500MS
    rcall DELAY_500MS
    ret

DELAY_2P5MS:
    ldi r30, 90
D3:
    ldi r31, 90
D4:
    dec r31
    brne D4
    dec r30
    brne D3
    ret