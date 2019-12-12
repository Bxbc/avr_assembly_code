;
; lcdshow.asm
;
; Created: 2019/10/31 23:11:35
; Author : BC
;


; Replace with your application code
;
; test.asm
;
; Created: 2019/10/31 22:59:01
; Author : BC
;


; Replace with your application code

.include "m2560def.inc"

.def row = r22
.def col = r23
.def rmask = r18
.def cmask = r19
.def temp1 = r20
.def temp2 = r21
.def count = r17


.equ TIME = 50
.equ PORTLDIR = 0b11110000					; PF7-4:output,PF3-0,input
.equ ROWMASK = 0b00001111					; For obtaining input from Port F
.equ INITCOLMASK = 0b11101111				; scan from the leftmost column
.equ INITROWMASK = 0b00000001				; scan from the top row
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4		; 4 cycles per iteration - setup/call-return overhead

.equ patten1 = 0b00001111
.equ patten2 = 0b11110000

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4
.equ loop_count = 50000

.macro wait
	ldi temp1, low(loop_count)			; 1 cycle
	ldi temp2, high(loop_count)		; 1 cycle
	ldi count, 20					; 1 cycle
	clr r16								; 1 cycle
start:
	clr r25								; 1 cycle
	clr r24								; 1 cycle
loop: 
	cp r24, temp1						; 1 cycle
	cpc r25, temp2						; 1 cycle
	brsh done							; 1 cycle for no branch,else 2
	adiw r25:r24, 1						; 2 cycle
	nop									; 1 cycle
	rjmp loop							; 2 cycle
done: 
	inc r16								; 1 cycle					
	cp r16, count						; 1 cycle
	brlo start							; 1 cycle for no branch else 2
.endmacro


.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro


	
;.org 0
;	jmp RESET


RESET:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
	clr count
	clr r25
	clr r24
	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, no blink

	ldi temp1,PORTLDIR		  ; PF7-4/out, PF3-0/in
	clr count				  ; initialize the count to 0
	sts DDRL,temp1

main:
		ldi cmask,INITCOLMASK		; Initial column mask
		clr col						; Initial column
colloop:
		cpi col,4
		breq main					; If all columns are scanned, return to mainloop
		sts PORTL,cmask				; Otherwise, keep scan
		ldi temp1,0b11111111		; slow down the scan operation
delay:
		dec temp1
		brne delay					; If temp1 != 0, keep delay loop
		lds temp1,PINL				; read PORTF
		andi temp1,ROWMASK			; Get the keypad output value
		cpi temp1,0b00001111		; Check the row with low valtage
		breq nextcol				; No low valtage detected
		ldi rmask,INITROWMASK		; If one row is low, we need to find out which one it is
		clr row						; Initial the row

rowloop:
		cpi row,4
		breq nextcol				; If row == 4, the row scan is over
		mov temp2,temp1
		and temp2,rmask
		breq antishake				; If bits clear, the key is pressed
		inc row
		lsl rmask					; else just keep scan the row
		jmp rowloop

antishake:							; after detect the pressing, do the loop and wait until the pressing is over
		lds temp1,PINL
		andi temp1,ROWMASK
		cpi temp1,0b00001111
		breq convert				; when it is zero go to the convert
		rcall sleep_5ms
		rjmp antishake
nextcol:
		lsl cmask
		inc col
		jmp colloop

convert:
		;rcall sleep_5ms				; do the anti-shake
		;rcall sleep_5ms
		cpi row,3					; If the key in row 3, we might get "*","#","0"
		breq symbols
		mov temp1,row				; Otherwise we have a number in 1-9
		lsl temp1
		add temp1,row
		add temp1,col				; temp1 = 3*temp1+col+1
		mov temp2,temp1
		subi temp2,-'1'
		do_lcd_data temp2
		subi temp1,-1
getvalue:
		;inc count
		;cpi count,4
		;breq overf
		ldi temp2,10
		mul r24,temp2
		mov r24,r0
		add r24,temp1
		;brvs overf
		jmp main
symbols:
		cpi col,0
		breq star					; detect the star symbol '*'
		cpi col,1					
		breq zero					; detect the hash symbol '#'
		ldi temp2,'#'
		do_lcd_data temp2
		mul r25,r24
		brvs overf
		ldi temp2,0
		cp r1,temp2
		brne overf
		mov temp1,r0
		jmp show
star:	
		ldi temp2,'*'
		do_lcd_data temp2
		mov r25,r24
		clr r24
		;clr count
		jmp main
zero:	
		ldi temp2,'0'
		do_lcd_data temp2
		ldi temp1,0
		jmp getvalue
show:
		clr count
first:
		cpi temp1,100
		brlo second
		inc count
		subi temp1,100
		rjmp first
second:
		subi count,-'0'
		do_lcd_data count
		clr count
third:
		cpi temp1,10
		brlo fourth
		inc count
		subi temp1,10
		rjmp third
fourth:
		subi count,-'0'
		do_lcd_data count
		clr count
		subi temp1,-'0'
		do_lcd_data temp1
		rjmp halt
halt:
		rjmp halt

overf:
		ser r20
		out DDRC,r20
		clr count
re:
		ldi r20,patten1
		out PORTC, r20
		wait
		ldi r20, patten2
		out PORTC, temp1
		wait
		inc count
		cpi count,4
		breq halt
		rjmp re 

	

.macro lcd_set							; Set bit in PORTA
	sbi PORTA, @0						; PORT A: LCD CTRL PA4-PA7>PA4:BE,PA5:RW,PA6:E,PA7:RS
.endmacro

.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

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
	push r26
	push r27
	ldi r27, high(DELAY_1MS)
	ldi r26, low(DELAY_1MS)
delayloop_1ms:
	sbiw r27:r26, 1
	brne delayloop_1ms
	pop r27
	pop r26
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret