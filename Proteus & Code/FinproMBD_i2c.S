; PA-03 - Smart Cat Feeder
; Cat Feeder System in AVR Assembly with I2C LCD

#define __SFR_OFFSET 0x00
#include "avr/io.h"

; Global declarations
.global main
.global I2C_init
.global I2C_start
.global I2C_write
.global I2C_stop
.global init_ADC
.global init_Timer
.global init_INT0
.global init_Buzzer
.global INT0_vect
.global ADC_vect
.global TIMER1_COMPA_vect

; Define PCF8574 address (0x40)
.equ PCF8574_ADDR, 0x40

; Define LCD control bits on PCF8574
.equ LCD_EN, 0b00000100  ; Enable bit
.equ LCD_RW, 0b00000010  ; Read/Write bit
.equ LCD_RS, 0b00000001  ; Register Select bit
.equ LCD_BL, 0b00001000  ; Backlight control bit

; Define state constants (two-state)
.equ STATE_IDLE, 0
.equ STATE_FEEDING, 1

;====================================================================
; Initialization
;====================================================================
main:
    CALL I2C_init       ; Initialize I2C for PCF8574
    CALL init_ADC       ; Initialize ADC for light sensor
    CALL init_Timer     ; Initialize timer for switching state
    CALL init_INT0      ; Initialize interrupt external
    CALL init_Buzzer    ; Initialize buzzer
    CALL LCD_init       ; Initialize LCD via I2C
    CALL delay_sec      ; Wait for LCD to initialize
    
    ; Initial state is idling
    CLR   R28           
    
    ; Display idling message on first line
    LDI   R16, 0x80     ; Set cursor to first position of first line
    CALL  LCD_command
    LDI   R31, hi8(msg_idling)
    LDI   R30, lo8(msg_idling)
    CALL  LCD_print_string
    
    ; Set cursor to second line
    LDI   R16, 0xC0     ; Set cursor to first position of second line
    CALL  LCD_command
    
    ; Start main loop
main_loop:
    CALL delay_ms       ; Small delay to prevent busy-waiting
    JMP main_loop       ; Loop forever

;====================================================================
; I2C Bus Functions
;====================================================================
I2C_init:
    LDI   R21, 0
    STS   TWSR, R21       ; Prescaler = 0
    LDI   R21, 72         ; For 16MHz: 16000000/(16+2*72*1) = 100kHz
    STS   TWBR, R21       ; Set SCL frequency = 100kHz
    LDI   R21, (1<<TWEN)  ; Enable TWI
    STS   TWCR, R21
    RET

I2C_start:
    LDI   R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    STS   TWCR, R21       ; Transmit START condition
    ;---------------------------------------------------------
wait_start:
    LDS   R21, TWCR
    SBRS  R21, TWINT      ; Wait until TWINT flag is set
    RJMP  wait_start
    ;---------------------------------------------------------
    RET

I2C_write:
    STS   TWDR, R24       ; Copy byte in R24 into data register
    LDI   R21, (1<<TWINT)|(1<<TWEN)
    STS   TWCR, R21       ; Transmit byte
    ;---------------------------------------------------------
wait_write:
    LDS   R21, TWCR
    SBRS  R21, TWINT      ; Wait until TWINT flag is set
    RJMP  wait_write
    ;---------------------------------------------------------
    RET

I2C_stop:
    LDI   R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS   TWCR, R21       ; Transmit STOP condition
    RET

;====================================================================
; PCF8574 Functions
;====================================================================
PCF8574_sendByte:
    PUSH  R24            ; Save R24 (used by I2C_write)
    
    CALL  I2C_start      ; Send START condition
    
    LDI   R24, PCF8574_ADDR
    CALL  I2C_write      ; Send PCF8574 write address
    
    MOV   R24, R16       ; R16 contains data. Move data to R24
    CALL  I2C_write      ; Send data byte
    
    CALL  I2C_stop       ; Send STOP condition
    
    POP   R24            ; Restore R24
    RET

;====================================================================
; LCD Functions
;====================================================================
send4bits:
    PUSH  R16            ; R16 contains data and control bits. Save R16
    
    ; Send data with EN=0
    ORI   R16, LCD_BL    ; Keep backlight on (OR with backlight bit)
    CALL  PCF8574_sendByte
    
    ; Pulse EN high
    ORI   R16, LCD_EN    ; Set EN bit
    CALL  PCF8574_sendByte
    CALL  delay_short    ; Small delay
    
    ; Set EN low
    ANDI  R16, ~LCD_EN   ; Clear EN bit
    CALL  PCF8574_sendByte
    CALL  delay_us       ; Longer delay
    
    POP   R16            ; Restore R16
    RET

LCD_command:
    ; Input: R16 contains command byte
    ; RS=0 for command
    PUSH  R17            ; Save R17
    
    MOV   R17, R16       ; Save command
    
    ; Send high nibble
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, LCD_BL    ; Set backlight ON, RS=0 (command)
    CALL  send4bits
    
    ; Send low nibble
    MOV   R16, R17       ; Restore command
    SWAP  R16            ; Swap nibbles
    ANDI  R16, 0xF0      ; Keep high nibble (which was the low nibble)
    ORI   R16, LCD_BL    ; Set backlight ON, RS=0 (command)
    CALL  send4bits
    
    POP   R17            ; Restore R17
    RET

LCD_data:
    ; Input: R16 contains data byte
    ; RS=1 for data
    PUSH  R17            ; Save R17
    
    MOV   R17, R16       ; Save data
    
    ; Send high nibble
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, (LCD_RS | LCD_BL) ; Set RS=1 (data), backlight ON
    CALL  send4bits
    
    ; Send low nibble
    MOV   R16, R17       ; Restore data
    SWAP  R16            ; Swap nibbles
    ANDI  R16, 0xF0      ; Keep high nibble (which was the low nibble)
    ORI   R16, (LCD_RS | LCD_BL) ; Set RS=1 (data), backlight ON
    CALL  send4bits
    
    POP   R17            ; Restore R17
    RET

LCD_init:
    CALL  delay_ms       ; Wait for LCD to power up
    CALL  delay_ms
    CALL  delay_ms
    
    ; Special initialization sequence for 4-bit mode
    LDI   R16, 0x30      ; Function set - 8-bit mode
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, LCD_BL    ; Set backlight ON
    CALL  send4bits
    CALL  delay_ms
    
    LDI   R16, 0x30      ; Function set - 8-bit mode
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, LCD_BL    ; Set backlight ON
    CALL  send4bits
    CALL  delay_ms
    
    LDI   R16, 0x30      ; Function set - 8-bit mode
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, LCD_BL    ; Set backlight ON
    CALL  send4bits
    CALL  delay_ms
    
    LDI   R16, 0x20      ; Function set - 4-bit mode
    ANDI  R16, 0xF0      ; Keep high nibble
    ORI   R16, LCD_BL    ; Set backlight ON
    CALL  send4bits
    CALL  delay_ms
    
    ; Now in 4-bit mode, can use LCD_command
    LDI   R16, 0x28      ; Function set: 4-bit mode, 2-line, 5x8 dots
    CALL  LCD_command
    CALL  delay_ms
    
    LDI   R16, 0x0C      ; Display on, cursor off, blink off
    CALL  LCD_command
    CALL  delay_ms
    
    LDI   R16, 0x01      ; Clear display
    CALL  LCD_command
    CALL  delay_ms
    
    LDI   R16, 0x06      ; Entry mode: Increment cursor, no display shift
    CALL  LCD_command
    CALL  delay_ms
    
    RET

LCD_print_string:
    ; Input: Z register (R31:R30) points to null-terminated string in program memory
    PUSH  R16            ; Save registers
    
print_loop:
    LPM   R16, Z+        ; Load byte from program memory pointed by Z, post-increment Z
    CPI   R16, 0         ; Check for end of string
    BREQ  print_exit     ; If null character, exit
    
    CALL  LCD_data       ; Display character
    CALL  delay_short    ; Small delay between characters
    
    JMP   print_loop     ; Loop for next character
    
print_exit:
    POP   R16            ; Restore registers
    RET

;====================================================================
; Initialize ADC with Interrupt (LDR)
;====================================================================
init_ADC:
    CBI   DDRC, 0       ; Set pin PC0 as input for ADC0 (LDR)
    ;-------------------------------------------------------------
    LDI   R20, 0xE0     ; Internal 2.56V, left-justified data, ADC0
    STS   ADMUX, R20
    
    ; Enable ADC, Enable ADC Interrupt, ADC prescaler CLK/64 (faster sampling)
    LDI   R20, (1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(0<<ADPS0)
    STS   ADCSRA, R20
    
    ; Start first conversion
    LDI   R20, (1<<ADEN)|(1<<ADIE)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)|(0<<ADPS0)
    STS   ADCSRA, R20
    
    RET

;====================================================================
; Initialize Timer for switching states with interrupt
;====================================================================
init_Timer:
    ; Initialize Timer1 for toggling between Idling and Feeding states
    ; Using CTC mode (Clear Timer on Compare Match)
    
    LDI   R20, 0x00     ; Set Timer1 to CTC mode (WGM13:0 = 0100)
    STS   TCCR1A, R20   
    LDI   R20, (1<<WGM12)|(0<<WGM13)
    STS   TCCR1B, R20
    
    ; Set prescaler to 256 (CS12:0 = 100) - more precise than 1024
    LDI   R20, (1<<CS12)|(0<<CS11)|(0<<CS10)
    STS   TCCR1B, R20
    
    ; For feeding duration: 1 second
    ; 16000000/256 = 62500 ticks per second
    ; Set compare match value to 62500 (0xF424)
    LDI   R20, 0xF4
    STS   OCR1AH, R20
    LDI   R20, 0x24
    STS   OCR1AL, R20
    
    ; Enable Timer1 Compare A Match Interrupt
    LDI   R20, (1<<OCIE1A)
    STS   TIMSK1, R20
    
    ; Initialize Timer1 count value to 0
    LDI   R20, 0x00
    STS   TCNT1H, R20
    STS   TCNT1L, R20
    
    ; Initialize feeding state flag to 0 (idling)
    ; Initialize timer count variable
    CLR   R28           ; Current state (0=idle, 1=feeding)
    CLR   R29           ; Timer count for state duration
    
    RET

;====================================================================
; Initialize External Interrupt (Manual feed button)
;====================================================================
init_INT0:
    ; Configure INT0 (PD2) pin as input with pull-up
    CBI   DDRD, 2       ; Set PD2 as input
    SBI   PORTD, 2      ; Enable pull-up resistor on PD2
    
    ; Configure INT0 to trigger on falling edge
    LDI   R20, (1<<ISC01)|(0<<ISC00)  ; Falling edge
    STS   EICRA, R20
    
    ; Enable INT0 interrupt
    LDI   R20, (1<<INT0)
    OUT   EIMSK, R20
    
    ; Enable global interrupts
    SEI
    
    RET

;====================================================================
; Initialize Buzzer
;====================================================================
init_Buzzer:
    ; Configure buzzer pin (PB5) as output
    SBI   DDRB, 5       ; Set PB5 as output
    CBI   PORTB, 5      ; Initialize buzzer OFF
    
    RET

;====================================================================
; INT0 Interrupt Service Routine (Manual feed button)
;====================================================================
.global INT0_vect
INT0_vect:
    PUSH  R16           ; Save used registers
    IN    R16, SREG
    PUSH  R16
    
    ; Force feeding state and reset timer
    LDI   R28, STATE_FEEDING ; Set feeding state flag
    CLR   R29           ; Reset state timer counter
    
    ; Reset timer
    LDI   R16, 0x00
    STS   TCNT1H, R16
    STS   TCNT1L, R16
    
    ; Update display
    CALL  update_display_state
    
    ; Buzzer on (for feeding)
    CALL  buzzer_on
    
    POP   R16           ; Restore used registers
    OUT   SREG, R16
    POP   R16
    RETI

;====================================================================
; ADC Conversion Complete Interrupt
;====================================================================
.global ADC_vect
ADC_vect:
    PUSH  R16           ; Save used registers
    IN    R16, SREG
    PUSH  R16
    PUSH  R17
    
    ; Read ADC result (left-justified)
    LDS   R16, ADCL     ; Get low-byte result (not actually used)
    LDS   R17, ADCH     ; Get high-byte result (what we need)
    
    ; Store ADC value for comparison in a higher register (R25)
    MOV   R25, R17      ; Keep a copy of the ADC value in R25 (not R15, which can't be used with CPI)
    
    ; Update food level display based on ADC value
    ; Threshold checking moved to a separate function
    CALL  update_food_level
    
    ; Start next conversion (after a short delay)
    ; We'll use a timer to trigger ADC readings at regular intervals
    ; This is handled in the Timer1 ISR
    
    POP   R17           ; Restore used registers
    POP   R16
    OUT   SREG, R16
    POP   R16
    RETI

;====================================================================
; Timer1 Compare A Match ISR
;====================================================================
.global TIMER1_COMPA_vect
TIMER1_COMPA_vect:
    PUSH  R16           ; Save used registers
    IN    R16, SREG
    PUSH  R16
    
    ; Increment state timer
    INC   R29
    
    ; Check current state and handle timing
    CPI   R28, STATE_IDLE
    BREQ  timer_idle_state
    
    ; In feeding state
    ; Check if feeding time has elapsed (3 seconds = 3 interrupts)
    CPI   R29, 3
    BRLO  timer_exit    ; If less than 3 seconds, continue
    
    ; Switch back to idle state
    CLR   R28           ; Set idle state
    CLR   R29           ; Reset state timer
    CALL  update_display_state
    JMP   timer_exit
    
timer_idle_state:
    ; In idle state
    ; Check if idle time has elapsed (5 seconds = 5 interrupts)
    CPI   R29, 5
    BRLO  timer_exit    ; If less than 5 seconds, continue
    
    ; Switch to feeding state
    LDI   R28, STATE_FEEDING ; Set feeding state
    CLR   R29           ; Reset state timer
    CALL  update_display_state
    CALL  buzzer_on     ; Signal state change with buzzer
    
timer_exit:
    ; Trigger ADC reading every timer interrupt
    LDI   R16, (1<<ADEN)|(1<<ADIE)|(1<<ADSC)|(1<<ADPS2)|(1<<ADPS1)|(0<<ADPS0)
    STS   ADCSRA, R16   ; Start a new ADC conversion
    
    POP   R16           ; Restore used registers
    OUT   SREG, R16
    POP   R16
    RETI

;====================================================================
; Delay Functions
;====================================================================
delay_short:            ; Very short delay, about 0.45µs
    NOP
    NOP
    RET
;--------------------------------------------------
delay_us:               ; Delay approximately 40µs
    LDI   R20, 90
us_loop:
    CALL  delay_short
    DEC   R20
    BRNE  us_loop
    RET
;--------------------------------------------------
delay_ms:               ; Delay approximately 1.6ms
    LDI   R21, 40
ms_loop:
    CALL  delay_us
    DEC   R21
    BRNE  ms_loop
    RET
;--------------------------------------------------
delay_sec:              ; Delay approximately 0.5s
    LDI   R22, 150      ; Reduce from 250 to make delays shorter
sec_outer:
    LDI   R23, 150      ; Reduce from 250 to make delays shorter
sec_inner:
    CALL  delay_us      ; 40µs delay
    DEC   R23           ; Decrement inner loop
    BRNE  sec_inner     ; Loop if not zero
    DEC   R22           ; Decrement outer loop
    BRNE  sec_outer     ; Loop if not zero
    RET                 ; Return to caller

;====================================================================
; Buzzer Control
;====================================================================
buzzer_on:
    SBI   PORTB, 5      ; Turn buzzer ON (PB5)
    CALL  delay_ms      ; Delay for a short time
    CALL  delay_ms
    CALL  delay_ms
    CBI   PORTB, 5      ; Turn buzzer OFF
    RET

;====================================================================
; Update Display State
;====================================================================
update_display_state:
    ; Update display based on R28 (0 = idling, 1 = feeding)
    LDI   R16, 0x80     ; Set cursor to first line
    CALL  LCD_command
    CALL  delay_ms
    
    CPI   R28, STATE_IDLE
    BREQ  show_idling
    
    ; Show feeding
    LDI   R31, hi8(msg_feeding)
    LDI   R30, lo8(msg_feeding)
    CALL  LCD_print_string
    RET
    
show_idling:
    LDI   R31, hi8(msg_idling)
    LDI   R30, lo8(msg_idling)
    CALL  LCD_print_string
    RET

;====================================================================
; Update Food Level Display
;====================================================================
update_food_level:
    ; Check ADC value against thresholds for food status (R25 contains the ADC value)
    
    ; Set cursor to second line
    LDI   R16, 0xC0     ; Set cursor to second line
    CALL  LCD_command
    CALL  delay_short   ; Use shorter delay for faster response
    
    CPI   R25, 250      ; Compare ADC value with EMPTY threshold
    BRSH  food_empty    ; If ADC >= 250, food level is EMPTY
    
    CPI   R25, 100      ; Compare ADC value with LOW threshold
    BRSH  food_low      ; If ADC >= 100 but < 250, food level is LOW
    
    ; Otherwise it's HIGH (ADC < 100)
    ; Display FOOD HIGH message on second line
    LDI   R31, hi8(msg_high)
    LDI   R30, lo8(msg_high)
    CALL  LCD_print_string
    
    RET
    
food_low:
    ; Display FOOD LOW message on second line
    LDI   R31, hi8(msg_low)
    LDI   R30, lo8(msg_low)
    CALL  LCD_print_string
    
    RET
    
food_empty:
    ; Display FOOD EMPTY message on second line
    LDI   R31, hi8(msg_empty)
    LDI   R30, lo8(msg_empty)
    CALL  LCD_print_string
    
    RET

;====================================================================
; Messages in Program Memory
;====================================================================
.section .progmem.data,"a",@progbits
msg_empty: .ascii "Status: Empty "
         .byte 0
msg_low: .ascii "Status: Low  "
         .byte 0
msg_high: .ascii "Status: High  "
         .byte 0
msg_idling: .ascii "Idling...       "
         .byte 0
msg_feeding: .ascii "Feeding...      " 
         .byte 0    