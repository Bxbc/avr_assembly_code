;
; lab_21.asm
;
; Created: 2019/10/10 23:02:58
; Author : BC
;



.include "m2560def.inc"
.def zero = r15
.def ah = r17
.def al = r16
.def bh = r19
.def bl = r18
.def rh = r21
.def rl = r20
.def rth = r23
.def rtl = r22

.macro remainder
	movw @4:@5,@0:@1
loop:
	cp @5,@3
	cpc @4,@2
	brlo end
	sub @5,@3
	sbc @4,@2
	rjmp loop

end:nop
.endmacro

main:
	clr zero
	rcall gcd
halt:
	rjmp halt

gcd:
	push rtl		;store the temporary return value
	push rth
	push YL
	push YH
	in YL,SPL		;in Rd,A >>Rd<-I/O(A)
	in YH,SPH
	sbiw Y,4		;let Y point to the top of the stack frame
	out SPH,YH		;update sp so that it points to the new stack top
	out SPL,YL
	
	std Y+1,al		;pass the "a" into function
	std Y+2,ah
	std Y+3,bl		;pass the "b" in to function
	std Y+4,bh
	cp bl,zero
	cpc bh,zero
	brne recur		;if b!=0,recall gcd()
	movw rth:rtl,ah:al  ;if b==0,return a
	rjmp epilo		

recur:
	ldd al,Y+1
	ldd ah,Y+2
	ldd bl,Y+3
	ldd bh,Y+4
	remainder ah,al,bh,bl,rh,rl
	movw ah:al,bh:bl
	movw bh:bl,rh:rl
	rcall gcd
	
epilo:
	adiw Y,4
	out SPH,YH		;restore SP
	out SPL,YL
	pop YH
	pop YL
	pop rth
	pop rtl
	ret