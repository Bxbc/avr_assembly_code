;
; lab1_1.asm
;
; Created: 2019/9/26 17:08:29
; Author : BC
;


.include "m2560def.inc"
.def digit_1=r16
.def digit_2=r17
.def result =r10


main:
		subi digit_1,128
		brcs decimal       ;if smaller means that the digit is in decimal	
		subi digit_1,48    ;below is the operation towards the hexadecimal numble('48' is the number of ASCLL '0')
		subi digit_2,176   ;176 is the 48 + 2^7
		rjmp transf
decimal:
		ldi r18,128
		add digit_1,r18    ;add 2^7 to get the original code from the complement
		subi digit_1,48
		subi digit_2,48

transf:
		ldi r18,16
		mul digit_1,r18
		mov result,r0
		add result,digit_2
end:
		rjmp end
