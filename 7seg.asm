;===========================================================
; Project: 7-Segment Display Counter with Interrupts
; MCU: ATmega328P
; Description:
;   - INT0 increments the counter (0 → 9 → 0)
;   - PCINT0 decrements the counter (9 → 0 → 9)
;   - Value is displayed on a single 7-segment display
;===========================================================

.include "./m328Pdef.inc"

;-----------------------------------------------------------
; Interrupt Vector Table
;-----------------------------------------------------------

.org 0
    rjmp Reset              ; Reset vector

.org INT0addr
    rjmp IntV0              ; External Interrupt 0 vector

.org PCI0addr
    rjmp IntVC0             ; Pin Change Interrupt 0 vector

;-----------------------------------------------------------
; Lookup table for decimal digits (common cathode)
; Bit order: (dp,g,f,e,d,c,b,a)
;-----------------------------------------------------------
segmentos_decimales:
.db 0x3F,0x06,0x5B,0x4F,0x66
.db 0x6D,0x7D,0x07,0x7F,0x6F

;===========================================================
; RESET
;===========================================================

Reset:
    ; Initialize Stack Pointer
    ldi R31, low(RAMEND)
    out SPL, R31
    ldi R31, high(RAMEND)
    out SPH, R31

    ; Initialize interrupts
    call INIT_IRQ_INT0
    call INIT_IRQ_PIN_CHANGE

    ; Configure I/O directions
    ; PD7..PD0 except PD2 as output
    ldi r16, 0xFB
    out DDRD, r16

    ; PB2 as output (segment C)
    ldi r16, 0x04
    out DDRB, r16

    sei                     ; Enable global interrupts

;===========================================================
; MAIN LOOP
;===========================================================

main:
    ldi r20, 0              ; Counter = 0
    call actualizar_7segmentos

loop:
    rjmp loop               ; Idle loop (interrupt driven)

;===========================================================
; INT0 - Increment counter
;===========================================================

IntV0:
    sbic PIND,2             ; If button released, exit
    reti

    call delay              ; Simple debounce

    push r16
    in   r16, SREG
    push r16

    inc r20
    cpi r20, 10
    brne no_reset_to_0
    ldi r20, 0

no_reset_to_0:
    call actualizar_7segmentos

    pop r16
    out SREG, r16
    pop r16
    reti

;===========================================================
; PCINT0 - Decrement counter
;===========================================================

IntVC0:
    sbic PINB,0             ; If button released, exit
    reti

    call delay              ; Debounce

    push r16
    in   r16, SREG
    push r16

    cpi r20, 0
    brne no_set_to_9
    ldi r20, 10

no_set_to_9:
    dec r20
    call actualizar_7segmentos

    pop r16
    out SREG, r16
    pop r16
    reti

;===========================================================
; Interrupt Initialization
;===========================================================

INIT_IRQ_PIN_CHANGE:
    ldi R16, (1<<PCIE0)         ; Enable PCINT[7:0]
    sts PCICR, R16

    ldi R16, (1<<PCINT0)        ; Enable PB0 pin change
    sts PCMSK0, R16
    ret

INIT_IRQ_INT0:
    ldi R16, (1<<ISC01)         ; Falling edge trigger
    sts EICRA, R16

    ldi R16, (1<<INT0)          ; Enable INT0
    out EIMSK, R16
    ret

;===========================================================
; actualizar_7segmentos
; Displays decimal digit stored in r20
;
; Mapping:
; (dp,g,f,e,d,c,b,a) =
; (PD7,PD6,PD5,PD4,PD3,PB2,PD1,PD0)
;===========================================================

actualizar_7segmentos:
    ldi zh, high(2*segmentos_decimales)
    ldi zl, low(2*segmentos_decimales)

    add zl, r20
    brcc no_increment_zh
    inc zh

no_increment_zh:
    lpm r16, Z              ; Load pattern from Flash

    ; Update PORTD
    mov r17, r16
    andi r17, 0b11111011
    ori  r17, 0b00000100
    out PORTD, r17

    ; Update PORTB (segment C)
    mov r17, r16
    andi r17, 0b00000100
    ori  r17, 0b00000001
    out PORTB, r17

    ret

;===========================================================
; Software delay (simple nested loop)
;===========================================================

delay:
    ldi  r21, 17
    ldi  r22, 60
    ldi  r23, 204

L1:
    dec  r23
    brne L1
    dec  r22
    brne L1
    dec  r21
    brne L1
    ret
