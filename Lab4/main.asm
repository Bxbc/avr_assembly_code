;
; lab4.asm
;
; Created: 2019/11/10 20:07:27
; Author : BC
;


; Replace with your application code

.include "m2560def.inc"

.def temp = r17
.def unit = r18
.def ten = r19
.def hundred = r20
.def hole = r21
.def number = r22
.def counter = r23

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.dseg
		TempCounter: .byte 2;

.cseg 
.org 0x00 
		jmp RESET 

.org OVF0addr
		jmp Timer0OVF						; jump to the interrupt handler for Timer0 overflow
.org INT2addr    
		jmp EXT_INT2
.org 0x72

.macro do_lcd_data
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro


.macro do_lcd_command
		ldi r16, @0
		rcall lcd_command
		rcall lcd_wait
.endmacro

.macro clear
		ldi YL, low(@0)						; load the memory address to Y pointer
		ldi YH, high(@0)
		clr temp							; set temp to 0
		st Y+, temp							; clear the two bytes at @0 in SRAM
		st Y, temp
.endmacro 

.macro convert
		mov number,@0
		clr hundred
		clr ten
		clr unit
first:
		cpi number,100
		brlo second
		inc hundred
		subi number,100
		rjmp first
second:
		cpi number,10
		brlo third
		inc ten
		subi number,10
		rjmp second
third:
		subi hundred,-'0'
		subi ten,-'0'
		subi number,-'0'
		mov unit,number
.endmacro

RESET:
		ldi r16, low(RAMEND)
		out SPL, r16
		ldi r16, high(RAMEND)
		out SPH, r16
		ser r16
		out DDRF, r16						; set Port F as output
		out DDRA, r16						; set Port A as output

		clr r16
		out PORTF, r16
		out PORTA, r16

		do_lcd_command 0b00111000 ; 2x5x7
		rcall sleep_5ms
		do_lcd_command 0b00111000 ; 2x5x7
		rcall sleep_1ms
		do_lcd_command 0b00111000 ; 2x5x7
		do_lcd_command 0b00111000 ; 2x5x7
		do_lcd_command 0b00001000 ; display off?
		do_lcd_command 0b00000001 ; clear display
		do_lcd_command 0b00000110 ; increment, no display shift
		do_lcd_command 0b00001110 ; Cursor on, bar, no blink

		ser temp 
		out DDRC, temp
		clr temp 
		out PORTC, temp
		out DDRD, temp
		out PORTD, temp
		ldi temp, (2 << ISC20)			; set the falling edge mode
		sts EICRA, temp
		in temp, EIMSK
		ori temp, (1<<INT2)
		out EIMSK, temp		
		sei							    ;enable global interrupt                                                                                                                                                                                                                                                                                                                                      
		jmp main


Timer0OVF:								;interrupt subroutine to Timer0
		in temp, SREG;
		push temp					; prologue starts
		push YH							; save all conflicting registers
		push YL
		push r25
		push r24						; prologue ends 
										
		lds r24, TempCounter			; Load the value of the temporary counter
		lds r25, TempCounter+1
		adiw r25:r24, 1					; increase the temporary counter by 1
		cpi r24, low(977)				; check if TempCounter(r25:r24) = 977 around 1 second
		cpi r25, high(977)
		brne NotSecond

		convert counter
		rcall lcd_display
		clr counter
		clear TempCounter
		rjmp End

NotSecond:
		sts TempCounter, r24
		sts TempCounter+1, r25

End:
		pop r24							; the epilogue
		pop r25
		pop YL
		pop YH
		pop temp
		out SREG, temp
		reti								; return from the interrupt

EXT_INT2: 
		inc hole
		cpi hole, 4
		brne notOnce
		clr hole
		inc counter
notOnce:
		reti

main:
		ldi temp, 0b00000000
		out TCCR0A, temp
		ldi temp, 0b00000011
		out TCCR0B, temp					; set prescalar value to 64
		ldi temp, 1<<TOIE0					; TOIE0 is the bit number of TOIE which is 0
		sts TIMSK0, temp					; enable Timer0 Overflow interrupt
		ldi hundred,'0'
		ldi ten,'0'
		ldi unit,'0'
		rcall lcd_display
		sei									; enable global interrupt
		rjmp loop
loop:
		rjmp loop



.macro lcd_set
		sbi PORTA, @0
.endmacro
.macro lcd_clr
		cbi PORTA, @0
.endmacro


lcd_display:
		do_lcd_command 0b00000001			; clear the LCD
		do_lcd_data hundred
		do_lcd_data ten
		do_lcd_data unit
		ldi r23,' '
		do_lcd_data r23
		ldi r23,'R'
		do_lcd_data r23
		ldi r23,'/'
		do_lcd_data r23
		ldi r23,'s'
		do_lcd_data r23
		clr r23
		ret


lcd_command:
		out PORTF, r16
		nop
		lcd_set LCD_E
		nop
		nop
		nop
		lcd_clr LCD_E
		nop
		nop
		nop
		ret

lcd_data:
		out PORTF, r16
		lcd_set LCD_RS
		nop
		nop
		nop
		lcd_set LCD_E
		nop
		nop
		nop
		lcd_clr LCD_E
		nop
		nop
		nop
		lcd_clr LCD_RS
		ret

lcd_wait:
		push r16
		clr r16
		out DDRF, r16
		out PORTF, r16
		lcd_set LCD_RW
		lcd_wait_loop:
		nop
		lcd_set LCD_E
		nop
		nop
		nop
		in r16, PINF
		lcd_clr LCD_E
		sbrc r16, 7
		rjmp lcd_wait_loop
		lcd_clr LCD_RW
		ser r16
		out DDRF, r16
		pop r16
		ret

sleep_1ms:
		push r24
		push r25
		ldi r25, high(DELAY_1MS)
		ldi r24, low(DELAY_1MS)
delayloop_1ms:
		sbiw r25:r24, 1
		brne delayloop_1ms
		pop r25
		pop r24
		ret

sleep_5ms:
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		rcall sleep_1ms
		ret
