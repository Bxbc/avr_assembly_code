;
; lab12.asm
;
; Created: 2019/10/4 12:02:21
; Author : BC
;


; Replace with your application code
.include "m2560def.inc"

.def al=r22  ;make the r22 store the low byte of a
.def ah=r23  ;make the r23 store the high byte of a
.def bl=r20
.def bh=r21

.dseg
a:	.byte 2  ;reserve 2 bytes in data memory for variable a
b:	.byte 2  ;rserver 2 bytes in data memory for variable b

.cseg
	rjmp main

main:
	ldi al,low(a)
	ldi ah,high(a)
	ldi bl,low(b)
	ldi bh,high(b)
while:         ;"while" loop in c
	cp bl,al
	cpc bh,ah  ;compare the a with b
	breq halt  ;if equal,end the while loop
	brsh loop
	sub al,bl  ;if a>b,let a = a-b
	sbc ah,bh
	rjmp while

loop:
	sub bl,al  ;if a<=b,let b=b-a
	sbc bh,ah
	rjmp while

halt:
	rjmp halt
