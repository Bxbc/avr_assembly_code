; COMP9032
; pj.asm
;
; Created: 2019/11/21 14:28:50
; Author : XI BI
; z5198280


; Replace with your application code

.include "m2560def.inc"

.def w1 = r11						; w1,w2,w3,w4 represent the states of four windows in this case
.def w2 = r12
.def w3 = r13
.def w4 = r14
.def eflag = r15					; if cflag = 1, the windows would in the central control state
.def cflag = r17					; if eflag = 1, the windows would in the emergency state
.def row = r22
.def col = r23
.def rmask = r20
.def cmask = r21
.def temp1 = r18					; to store the temporary data
.def temp2 = r19
.def count = r24
.equ loop_count = 50000
.equ PORTLDIR = 0b11110000					; PF7-4:output,PF3-0,input
.equ ROWMASK = 0b00001111					; For obtaining input from Port F
.equ INITCOLMASK = 0b11101111				; scan from the leftmost column
.equ INITROWMASK = 0b00000001				; scan from the top row
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro initial					; this macro is to show the initial state
	do_lcd_command 0b00000001   ; clear display at begining
	do_lcd_data ' '
	do_lcd_data 'S'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b11000000		; jump to the sencond line to show 
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
.endmacro

.macro central				  ; this macro is to show the central control state
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data ' '
	do_lcd_data 'C'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b11000000
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data_r @0
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data_r @0
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data_r @0
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data_r @0
.endmacro

.macro emergency					; this macro is to show the emergency state
	do_lcd_command 0b00000001 		; clear display
	do_lcd_data ' '
	do_lcd_data '!'
	do_lcd_data '!'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b11000000
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
.endmacro

.macro local					; this macro is to show the local control state
	do_lcd_command 0b00000001   ; clear display
	do_lcd_data ' '
	do_lcd_data 'L'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b11000000
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	ldi r18,'0'
	add r18,@0
	do_lcd_data_r r18
	do_lcd_data ' '
	do_lcd_data ' '
	ldi r18,'0'
	add r18,@1
	do_lcd_data_r r18
	do_lcd_data ' '
	do_lcd_data ' '
	ldi r18,'0'
	add r18,@2
	do_lcd_data_r r18
	do_lcd_data ' '
	do_lcd_data ' '
	ldi r18,'0'
	add r18,@3
	do_lcd_data_r r18
.endmacro

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data		; this macro is to get the constant value
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_data_r	; this macro is to get the value in register
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro wait
	ldi temp1, low(loop_count)			; 1 cycle
	ldi temp2, high(loop_count)			; 1 cycle
	ldi row, 20						    ; 1 cycle
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
	cp r16, row 						; 1 cycle
	brlo start							; 1 cycle for no branch else 2
.endmacro								; around 0.5s delay

.org 0x00
	jmp RESET
.org INT0addr							; interrupt0 is to jump to the emergency branch
	jmp EXT_INT0		
.org INT1addr							; interrupt1 is to jump to the central control branch
	jmp EXT_INT1

RESET:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16
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
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	initial					  ; show the initial text on the LCD
	ldi temp1,PORTLDIR
	sts DDRL,temp1
	clr w1					  ; at the begining, make the four windows clear
	clr w2
	clr w3
	clr w4
	clr cflag
	clr eflag
	clr temp1
	out DDRD,temp1						; set the PB0 and PB1 button as input 
	out PORTD,temp1						; PB1 represents the central control, PB0 represents the emergency
	ldi temp1,(3<<ISC00)|(3<<ISC10)		; set INT0 and INT1 as falling edge sensed interrupts
	sts EICRA,temp1
	in temp1,EIMSK
	ori temp1,(1<<INT0)|(1<<INT1)		; set the  INT0 and INT1 as
	out EIMSK,temp1						; falling edge sensed interrupts
	ser temp1							; set the PortH and PortE as output for PWM signal
	sts DDRH,temp1						; PE2 corresponding to the led 0:1, represents OC3B
	out DDRE,temp1						; PE3 corresponding to the led 2:3, represents OC3C
	ldi temp1,0							; PE5 corresponding to the led 4:5, represents OC3A
	sts OCR3BL,temp1					; PH9 corresponding to the led 6:7, represents OC2A
	sts OCR3CL,temp1
	sts OCR3AL,temp1
	sts OCR2B,temp1						; set the value in high bits and low bits both 0
	clr temp1							; by this way, the valtage of PWM signal is 0
	sts OCR3BH,temp1
	sts OCR3CH,temp1
	sts OCR3AH,temp1
	ldi temp1,(1<<CS30)					; no prescaling in Timer3
	sts TCCR3B,temp1
	ldi temp1,(1<<WGM30)|(1<<COM3B1)|(1<<COM3C1)|(1<<COM3A1)	; set the PWM wave mode as Phase correct
	sts TCCR3A,temp1
	ldi temp1,(1<<CS20)					; no prescaling in Timer2
	sts TCCR2B,temp1
	ldi temp1,(1<<WGM20)|(1<<COM2B1)
	sts TCCR2A,temp1
	sei									; enable Global interrupt
	rjmp main

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
		breq convert				; when it is no pressing go to the convert
		rjmp antishake
nextcol:
		lsl cmask
		inc col
		jmp colloop
convert:
		cpi col,3					; if column = 3, we get the letters A,B,C,D
		breq letters1				; we use A means that all windows clear
		cpi cflag,1					; if cflag = 1, we are in the central state, people could not change the windows' state
		breq main				
		mov temp1,row				; if we not in central control state, we can change the windows' state individualy
		lsl temp1
		add temp1,row
		add temp1,col				
		subi temp1,-1				; temp1 = 3*row+col+1
		ldi temp2,1					; temp1 now store the number of the key pressed of the keypad  
		cpi temp1,1					; if the key 1 pressed, means the opaque level of window 1 decrease
		breq subw1
		cpi temp1,2					; if the key 2 pressed, means the opaque level of window 1 increase
		breq addw1
		cpi temp1,3					; if the key 3 pressed, means the opaque level of window 2 decrease
		breq subw2
		cpi temp1,4					; if the key 4 pressed, means the opaque level of window 2 increase
		breq addw2
		cpi temp1,5					; if the key 5 pressed, means the opaque level of window 3 decrease
		breq subw3
		cpi temp1,6					; if the key 6 pressed, means the opaque level of window 3 increase
		breq addw3
		cpi temp1,7					; if the key 7 pressed, means the opaque level of window 4 decrease
		breq subw4
		cpi temp1,8					; if the key 8 pressed, means the opaque level of window 4 increase
		breq addw4
		jmp main					; in local control state, we ignore other keys pressed
letters1:						    ; because the address range out of the breq
		jmp letters					; use this to be the middle transfer station
subw1:
		ldi temp1,0					; if the state of window already is 0, it can not be decreased
		cpc w1,temp1
		breq w1sj
		sub w1,temp2
w1sj:	jmp localshow				; jump to the branch to show the text of local control state
addw1:
		ldi temp1,3					; if the state of window already is 3, it can not be increased
		cpc w1,temp1
		breq w1aj
		add w1,temp2
w1aj:	jmp localshow
subw2:								; below is the same as the operation in window 1
		ldi temp1,0
		cpc w2,temp1
		breq w2sj
		sub w2,temp2
w2sj:	jmp localshow
addw2:	
		ldi temp1,3
		cpc w2,temp1
		breq w2aj
		add w2,temp2
w2aj:	jmp localshow
subw3:
		ldi temp1,0
		cpc w3,temp1
		breq w3sj
		sub w3,temp2
w3sj:	jmp localshow
addw3:
		ldi temp1,3
		cpc w3,temp1
		breq w3aj
		add w3,temp2
w3aj:	jmp localshow
subw4:
		ldi temp1,0
		cpc w4,temp1
		breq w4sj
		sub w4,temp2
w4sj:	jmp localshow
addw4:
		ldi temp1,3
		cpc w4,temp1
		breq w4aj
		add w4,temp2
w4aj:	jmp localshow

letters:
		cpi cflag,1					; only when the flag is 1 means that we are in central control situation
		breq control				; else we ignore the key pressed
		jmp main
control:
		cpi row,0					; row = 0 means we get the 'A' pressed
		breq centerclear
		cpi row,1					; row = 1 means we get the 'B' pressed
		breq centerset
		jmp main
centerclear:
		ldi temp1,'0'
		jmp centralshow
centerset:
		ldi temp1,'3'
		ldi row,3
		jmp centralshow
centralshow:
		central temp1				; show the text use the macro
		ldi temp1,30				; use the value in temp1 to multiply 30 to set the voltage of PWM
		mul row,temp1
		mov temp1,r0
		sts OCR3BL,temp1			; use the result of multiply to update the voltage
		sts OCR3CL,temp1
		sts OCR3AL,temp1
		sts OCR2B,temp1
		jmp main					; return to main branch

EXT_INT0:									; use the external interrupt0 to detect emergency state
		ldi temp2,1							; the second time pressing the emergency button will
		add eflag,temp2						; release the emergency state and the windows will go into the initial state
		emergency
		ldi temp1,0
		sts OCR3BL,temp1
		sts OCR3CL,temp1
		sts OCR3AL,temp1
		sts OCR2B,temp1
		in temp1,EIMSK
		andi temp1,(0<<INT1)				; shielding the interrupt from INT1
		out EIMSK,temp1
		sei
lockstate:
		ldi temp2,2
		cpc eflag,temp2
		brlo eflagset
		ldi temp2,0
		mov eflag,temp2
		jmp RESET
eflagset:
		rjmp lockstate
EXT_INT1:							; use the external interrupt1 to detect the central control command
		cpi cflag,1					; and the sencond time into this state will realse this state as well
		brne cflagset				; if cflag != 1,means we can go into the central control state
		jmp RESET					; otherwise release the central control state and go to the initial state
cflagset:
		sei							; enable the global interrupt
		ldi cflag,'0'
		central cflag
		ldi cflag,1					; set the cflag with 1
		jmp main					; waiting the control instrument from keypad

localshow:
		local w1,w2,w3,w4			; when in local show branch
		wait						; delay 0.5s to show
		ldi temp1,30				; use the value of the state in each window
		mul w1,temp1				; to mutiply 30 and use the result to update
		mov temp2,r0				; the voltage of PWM
		sts OCR3BL,temp2
		mul w2,temp1
		mov temp2,r0
		sts OCR3CL,temp2
		mul w3,temp1
		mov temp2,r0
		sts OCR3AL,temp2
		mul w4,temp1
		mov temp2,r0
		sts OCR2B,temp2
		jmp main					; return to the main branch

.macro lcd_set
	sbi PORTA, @0
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

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r26
	push r27
	ldi r26, high(DELAY_1MS)
	ldi r27, low(DELAY_1MS)
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
