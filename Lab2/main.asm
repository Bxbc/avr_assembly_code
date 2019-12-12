;
; lab_22.asm
;
; Created: 2019/10/18 10:52:18
; Author : BC
;


; Replace with your application code
.include "m2560def.inc"
.equ patten1 = 0b00001111
.equ patten2 = 0b11110000
.equ patten3 = 0b11111111
.equ stop = 0b00000000


.equ loop_count = 50000
.equ loop_j = 20
.def iH = r25
.def iL = r24
.def countH = r19
.def countL = r18
.def j = r16
.def countj = r17


.macro wait
	ldi countL, low(loop_count)			; 1 cycle
	ldi countH, high(loop_count)		; 1 cycle
	ldi countj, loop_j					; 1 cycle
	clr j								; 1 cycle
start:
	sbis PIND,1
	rjmp start
	clr iH								; 1 cycle
	clr iL								; 1 cycle
loop: 
	cp iL, countL						; 1 cycle
	cpc iH, countH						; 1 cycle
	brsh done							; 1 cycle for no branch,else 2
	adiw iH:iL, 1						; 2 cycle
	nop									; 1 cycle
	rjmp loop							; 2 cycle
done: 
	inc j								; 1 cycle					
	cp j, countj						; 1 cycle
	brlo start							; 1 cycle for no branch else 2
.endmacro


main: 
		ser r20
		cbi DDRD,1
		out DDRC, r20			;set port C for output
re:
		ldi r20,patten1
		out PORTC, r20
		wait				; 0.5s delay to be visible
		ldi r20, patten2
		out PORTC, r20
		wait
		ldi r20, patten3
		out PORTC, r20
		wait
		rjmp re 
halt:
		ldi r20,stop
		out PORTC,r20
		rjmp halt
