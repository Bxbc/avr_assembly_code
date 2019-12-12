.include "m2560def.inc"

.def temp=r16
main:
		ser temp
		out DDRE,temp
		ldi temp,0x4A
		sts OCR3CL,temp
		clr temp
		sts OCR3CH,temp
		ldi temp,(1<<CS30)					; no prescaling
		sts TCCR3B,temp
		ldi temp,(1<<WGM30)|(1<<COM3A1)
		sts TCCR3A,temp
		sei
end:
		rjmp end

; PE3 is the output