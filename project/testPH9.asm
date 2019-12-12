.include "m2560def.inc"

.def temp=r16
main:
		ser temp
		sts DDRH,temp
		ldi temp,0x4A
		sts OCR2B,temp
		ldi temp,(1<<CS20)					; no prescaling
		sts TCCR2B,temp
		ldi temp,(1<<WGM20)|(1<<COM2B1)
		sts TCCR2A,temp
end:
		rjmp end

; PH9 is the output