.include "m2560def.inc"

.def temp=r16
main:
		ser temp
		out DDRE,temp
		ldi temp,0x3c
		sts OCR3BL,temp
		clr temp
		sts OCR3BH,temp
		ldi temp,(1<<CS30)					; no prescaling
		sts TCCR3B,temp
		ldi temp,(1<<WGM30)|(1<<COM3B1)
		sts TCCR3A,temp
end:
		rjmp end

;PE2 pin output