.include "m2560def.inc"

.def temp=r16
main:
		ser temp
		out DDRE,temp
		ldi temp,0x4A
		sts OCR3AL,temp
		clr temp
		sts OCR3AH,temp
		ldi temp,(1<<CS20)					; no prescaling
		sts TCCR3B,temp
		ldi temp,(1<<WGM30)|(1<<COM3A1)
		sts TCCR3A,temp
end:
		rjmp end

; PE5 is the output