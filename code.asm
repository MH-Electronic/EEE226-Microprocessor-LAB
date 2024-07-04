ORG 0000H
LJMP INITIAL

; ---- ISR0 PROGRAM ----
ORG  0013H				; INT0 Memory Location
ACALL WAKEUP
RETI

; ---- ISR1 PROGRAM ----
ORG 0003H				; INT1 Memory Location
LOOP5:
	CLR P1.4
	LCALL DELAY
	JB RED,  RM1 ;Red colour detected
	JB BLUE, BM1; Blue colour detected
	SETB P1.4
	LCALL DELAY
	SJMP LOOP5
	
RM1: 
	LCALL RM
	RETI
	
BM1: 
	LCALL BM
	RETI
	

ORG 0100H
; ---- Pin Initialization and Configurations ----
; Define SFRs and bit variables
//SLP   		EQU P1.0	; SLEEP PIN
RS    		EQU P2.0
RW    		EQU P2.1
EN    		EQU P2.2
WK    		EQU P2.3 	; IDLE AND WAKEUP
REDSERVO   	EQU P1.1
BLUESERVO  	EQU P1.2
REDBOX      EQU P0.7
IRRED       EQU P0.4
BLUEBOX     EQU P0.3
IRBLUE      EQU P0.2
BLUE        EQU P0.1
RED         EQU P0.0


; Register to count number of red objects and blue objects
RED_NUM EQU 00H 
BLE_NUM EQU R5

; ---- VARAIBLES INITIALIZATION ----
INITIAL:
	MOV RED_NUM, #0x00  ; Initialize red count to 0
	MOV BLE_NUM, #0x00  ; Initialize yellow count to 0
	MOV TMOD, #01H ; Set Timer 0 to 16 bit mode

	; Clear P1 and P2
	MOV P1, #0FFH
	MOV P2, #00FH
		
; ---- MAIN PROGRAM ----
START:
    MOV IE,   #85H		; Enable global interrupt, INT0, INT1 
	; Select INT0 and INT1 on falling edge
	MOV TCON, #05H

    ; Initialization of LCD Module
    MOV A, #02H
    ACALL SEND_COMMAND
    ACALL MS_DELAY
    MOV A, #28H
    ACALL SEND_COMMAND
    ACALL MS_DELAY
    MOV A, #0CH          ; Display ON, Cursor OFF
    ACALL SEND_COMMAND
    ACALL MS_DELAY
    MOV A, #01H
    ACALL SEND_COMMAND
    ACALL MS_DELAY
    MOV A, #80H          ; Force cursor to beginning of first line
    ACALL SEND_COMMAND
    ACALL MS_DELAY
	SJMP MAIN

POWER:
	LJMP SLEEPMODE

MAIN:
	CPL P1.3
	; Entering IDLE Mode or not
	JNB P1.0, POWER
	
    MOV A, #80H          ; Continuously Refresh without blinking
    ACALL SEND_COMMAND
    ACALL MS_DELAY
	
    ; First Line of Words
    MOV DPTR, #LINE1
WRITE_FIRST:
	CLR A
    MOVC A, @A+DPTR
	JZ TOTALUNIT
	INC DPTR
	ACALL SEND_DATA
	SJMP WRITE_FIRST
	
TOTALUNIT:
    ; Write Total Unit
    MOV A, RED_NUM
    ADD A, BLE_NUM
    ACALL DISPLAY_NUMBER

    ; Second Line
    MOV A, #0C0H
    ACALL SEND_COMMAND
    ACALL MS_DELAY

    ; Second Line of Words
    MOV DPTR, #LINE2
WRITE_SECOND:
	CLR A
	MOVC A, @A+DPTR
	JZ BLUEUNIT
	INC DPTR
	ACALL SEND_DATA
	SJMP WRITE_SECOND

BLUEUNIT:
    ; Write Blue Number Units
    MOV A, BLE_NUM
    ACALL DISPLAY_NUMBER

    ; Spacebar
    MOV A, #20H          ; ASCII code for space
    ACALL SEND_DATA

    ; Third Line of Words
    MOV DPTR, #LINE3
WRITE_THIRD:
	CLR A
	MOVC A, @A+DPTR
	JZ REDUNIT
	INC DPTR
	ACALL SEND_DATA
	SJMP WRITE_THIRD

REDUNIT:
    ; Write Red Number Units
    MOV A, RED_NUM
    ACALL DISPLAY_NUMBER

    ACALL MS_DELAY
    LJMP MAIN

// ~~~~~~~~~~~~~ END OF PROGRAM ~~~~~~~~~~~~~~
// ===========================================

// ~~~~~~~~~~~~~ Servo Mechanism ~~~~~~~~~~~~~~
;Red mechanism ready
RM:
	JB IRRED, $ ; Wait for IR to detect
	INC RED_NUM
	BACK: JB REDBOX, RSERVO_90 ; Servo turn to 90 degree until red box read high
	ACALL RSERVO_0 ; turn back to 0 degree
	SETB P1.4
	RET

;Blue mechanism ready
BM:
	JB IRBLUE, $ ; Wait for IR to detect
	INC BLE_NUM
	BACK2:JB BLUEBOX, BSERVO_90 ; Servo turn to 90 degree until blue box read high
	ACALL BSERVO_0 ; turn back to 0 degree
	SETB P1.4
	RET

;Set up for servo turn to 90 degree
RSERVO_90:
	SETB REDSERVO
	ACALL DELAY1_4ms
	CLR REDSERVO
	ACALL DELAY18_6ms
	SJMP BACK
	
BSERVO_90:
	SETB BLUESERVO
	ACALL DELAY1_4ms
	CLR BLUESERVO
	ACALL DELAY18_6ms
	SJMP BACK2

;Set up for servo turn to 0 degree
RSERVO_0:
	MOV R1, #20D ; repeat for 20 times to send 20 pulse
	Loop:
		SETB REDSERVO
		ACALL DELAY1ms
		CLR REDSERVO
		ACALL DELAY19ms
		DJNZ R1, Loop
		RET
	
BSERVO_0:
	MOV R1, #20D ; repeat for 20 times to send 20 pulse
	Loop3:
		SETB BLUESERVO
		ACALL DELAY1ms
		CLR BLUESERVO
		ACALL DELAY19ms
		DJNZ R1, Loop3
		RET

;Set up for 1ms delay
DELAY1ms:
	MOV TH0, #0FCH 
	MOV TL0, #67H
	SETB TR0 ; Start Timer0
	JNB TF0, $ ;Wait until Timer0 finish counting
	CLR TR0 ; Clear Timer0
	CLR TF0 ; Clear Timer Flag 0
	RET 

;Set up for 1.4ms delay
DELAY1_4ms:
	MOV TH0, #0F8H
	MOV TL0, #0ADH
	SETB TR0 ; Start Timer0
	JNB TF0, $ ;Wait until Timer0 finish counting
	CLR TR0 ; Clear Timer0
	CLR TF0 ; Clear Timer Flag 0
	RET

;Set up for 19ms delay
DELAY19ms:
	MOV TH0, #0BBH 
	MOV TL0, #99H
	SETB TR0 ; Start Timer0
	JNB TF0, $ ;Wait until Timer0 finish counting
	CLR TR0 ; Clear Timer0
	CLR TF0 ; Clear Timer Flag 0
	RET 

;Set up for 18.6ms delay
DELAY18_6ms:
	MOV TH0, #0B3H 
	MOV TL0, #0A6H
	SETB TR0 ; Start Timer0
	JNB TF0, $ ;Wait until Timer0 finish counting
	CLR TR0 ; Clear Timer0
	CLR TF0 ; Clear Timer Flag 0
	RET 
	
DELAY:
	MOV R2,#3D
LOOP2:MOV R3, #255D
LOOP1:MOV R4, #255D
	DJNZ R4, $
	DJNZ R3, LOOP1
	DJNZ R2, LOOP2
	RET
	
; ~~~~~~~~~~~~~~~~~~~~~~~~ POWER MODE ~~~~~~~~~~~~~~~~~~~~~~~~
; SLEEPMODE, WAKEUP
SLEEPMODE:
	; ---- CLEAR DISPLAY SCREEN ----
	MOV A, #01H
    ACALL SEND_COMMAND
    ACALL MS_DELAY
    MOV A, #80H          ; Force cursor to beginning of first line
    ACALL SEND_COMMAND
    ACALL MS_DELAY
	; ---- FINISIH CLEARING ----
	; ---- SLEEP WORDS ----
    MOV DPTR, #SLEEP
	WRITE_SLEEP:
	CLR A
	MOVC A, @A+DPTR
	INC DPTR
	ACALL SEND_DATA
	JZ ENTERSLP
	SJMP WRITE_SLEEP
	ACALL S_DELAY
	ENTERSLP:
	; ---- 
	MOV A, #0FFH
	; ---- ENTER SLEEP MODE ----
	ORL 87H, #01H	; PCON (IDLE MODE)

JUMP:
	LJMP MAIN

WAKEUP:
	; ---- MISPRESS ----
	CJNE A, #0FFH, JUMP
	; ---- WAKING UP FROM SLEEP MODE ----
	ANL 87H, #00H
	; ---- CLEAR DISPLAY SCREEN ----
	MOV A, #01H
    ACALL SEND_COMMAND
    MOV A, #80H          ; Force cursor to beginning of first line
    ACALL SEND_COMMAND
	; ---- FINISIH CLEARING ----
	; ---- WAKEUP WORDS ----
    MOV DPTR, #WAKE
	WRITE_WAKE:
	CLR A
	MOVC A, @A+DPTR
	INC DPTR
	JZ JUMPBACK
	ACALL SEND_DATA
	SJMP WRITE_WAKE
	JUMPBACK:
	ACALL S_DELAY
	MOV A, #01H
    ACALL SEND_COMMAND
	RET
	
; ~~~~~~~~~~~~~~~~~~~~~~~~ LCD MODULE ~~~~~~~~~~~~~~~~~~~~~~~~
; SEND_COMMAND, SEND_DATA
SEND_COMMAND:
    MOV R6, A            ; Save original value of A
    ANL A, #0F0H         ; Mask lower nibble
    ANL P2, #0x0F        ; Clear upper nibble bits
    ORL P2, A            ; Send upper nibble to LCD
    CLR RS               ; Command mode
    CLR RW               ; Write mode
    SETB EN              ; Enable pulse
    ACALL MS_DELAY       ; Delay
    CLR EN               ; Disable pulse

    MOV A, R6            ; Restore original value of A
    SWAP A               ; Swap nibbles to send lower nibble
    ANL A, #0F0H         ; Mask lower nibble
    ANL P2, #0x0F        ; Clear upper nibble bits
    ORL P2, A            ; Send lower nibble to LCD
    CLR RS               ; Command mode
    CLR RW               ; Write mode
    SETB EN              ; Enable pulse
    ACALL MS_DELAY       ; Delay
    CLR EN               ; Disable pulse
    RET

SEND_DATA:
    MOV R6, A            ; Save original value of A
    ANL A, #0F0H         ; Mask lower nibble
    ANL P2, #0x0F        ; Clear upper nibble bits
    ORL P2, A            ; Send upper nibble to LCD
    SETB RS              ; Data mode
    CLR RW               ; Write mode
    SETB EN              ; Enable pulse
    ACALL MS_DELAY       ; Delay
    CLR EN               ; Disable pulse

    MOV A, R6            ; Restore original value of A
    SWAP A               ; Swap nibbles to send lower nibble
    ANL A, #0F0H         ; Mask lower nibble
    ANL P2, #0x0F        ; Clear upper nibble bits
    ORL P2, A            ; Send lower nibble to LCD
    SETB RS              ; Data mode
    CLR RW               ; Write mode
    SETB EN              ; Enable pulse
    ACALL MS_DELAY       ; Delay
    CLR EN               ; Disable pulse
    RET

// ~~~~~~~~~ ASCII NUMBER to LCD ~~~~~~~~~~~~~ 
DISPLAY_NUMBER:
    MOV B, #10        ; Divide by 10
    DIV AB            ; A = quotient, B = remainder
    ADD A, #30H       ; Convert to ASCII
    ACALL SEND_DATA   ; Send tens place
    MOV A, B          ; Get remainder
    ADD A, #30H       ; Convert to ASCII
    ACALL SEND_DATA   ; Send units place
    RET

// ~~~~~ DELAY SUBROUTINES (MS_DELAY & S_DELAY) ~~~~~~~~~~
MS_DELAY:
    MOV R1, #100
DELAY_LOOP:
    MOV R2, #255
INNER_DELAY_LOOP:
    DJNZ R2, INNER_DELAY_LOOP
    DJNZ R1, DELAY_LOOP
    RET

S_DELAY:
    MOV R1, #7
SDELAY_LOOP1: MOV R2, #255
SDELAY_LOOP2: MOV R3, #255 
INNER_SLOOP:
	DJNZ R3,$
    DJNZ R2, SDELAY_LOOP2
    DJNZ R1, SDELAY_LOOP1
    RET

// ~~~~~~~~~~~~~~~~~ STRING DISPLAY ~~~~~~~~~~~~~~
// (Total Unit, RED, BLE, INITIALIZING, SLEEP MODE)
LINE1:
	DB 'TOTAL_UNIT:',0

LINE2:
	DB 'BLE:',0

LINE3:
	DB 'RED:', 0

WAKE:
	DB 'INITIALIZING...', 0

SLEEP:
	DB 'SLEEP MODE', 0

END
