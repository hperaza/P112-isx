;=======================================================================;
;	B A S I C   D I S K - D R I V E   R O U T I N E S		;
;									;
;  Non-interrupt driven support routines for the SMC diskette chip.	;
;=======================================================================;
;   DISKOPQ - Version for BIOS, with FORMAT disabled to save space.

;   This code is designed to work without interrupts (compatible with
; the ROM bootstrap code). Consequently, timing functions are done by 
; polling and/or delay loops.
;   The DMA is used for data transfer, and is polled for completion (check
; that the byte counter has decremented to zero).

; Call:
;	A  - OPCODE:	0 - Reset disk system: all drives uncalibrated
;			1 - Turn motors off (leave drives calibrated)
;			2 - Read sector/s
;			3 - Write sector/s
;			4 - Verify sector/s
;			5 - Format track
;			6 - Translate logical address to physical
;	B  - No. of sectors to read/write
;	C  - Track No. (even tracks are Side 0, odd tracks are Side 1)
;	D  - Drive No. (0..3)
;	E  - Sector No.
;	HL - Ptr. to data buffer (logical address)
;	IX - Ptr. to Drive Parameter Block (DPB)

; Return:
;	If successful:
;		CY = 0
;		A    undefined
;		HL   advanced past data block
;
;	If errors:
;		CY = 1
;		A    status (see below)
;		HL   unchanged
; 
;	In either case:
;		DE -> Result vector (7 bytes)
;		IX, IY unchanged
;		BC     trashed

;INCFORMAT	EQU	0	; Define this to include the FORMAT cmnd.

;======================================================================
;	L O C A L   D A T A
 
	; Return-error status values (in A, if CY=1)
CALERR	EQU	1	; Error in a recalibration function
IOERR	EQU	2	; Error posted by Result Phase: see (HL)
BADSECT	EQU	3	; Sector/Length will overrun track
LOSTDAT	EQU	4	; DMA did not transfer full block
TIMEOUT	EQU	5	; Interrupt timed out
BADCMD	EQU	6	; Invalid function code
SEKERR	EQU	7	; Seek error

TRIES	EQU	5	; No. of retries on IO errors

;======================================================================
;	F . D . C .    C O M M A N D   C O D E S

CMD_RECAL	EQU	7	; Recalibrate
CMD_SENSE	EQU	8	; Sense Interrupt
CMD_SEEK	EQU	0FH	; Seek to track
CMD_READ	EQU	46H	; Read (MFM, implied seek)
CMD_WRITE	EQU	45H	; Write, ditto
CMD_VERIFY	EQU	56H	; Verify, ditto
CMD_FORMAT	EQU	4DH	; Format a track
CMD_RDID	EQU	4AH	; Read Disk Sector ID Data

;	D . M . A .   C O M M A N D S

DMA_INCMD	EQU	0CDH	; IO  => MEM
DMA_OUTCMD	EQU	0F1H	; MEM => IO
DMA_RUN		EQU	63H	; Kick off Channel-0

;======================================================================
;	U T I L I T Y   S U B R O U T I N E S

; Wait for "Interrupt" from FDC controller (but Polled)

WaitInt: PUSH	BC
	PUSH	DE
	LD	BC,0		; Inner timeout counters
	LD	D,10		; Coarse timeout setting (Lo-Speed)
	IN0	A,(CCR)
	BIT	7,A		; Low CPU Speed?
	JR	Z,WaitI1	; ..jump if So
	SLA	D		; Else Double count to 10
WaitI1:	IN0	A,(DRC)		; Get interrupt lines
	BIT	6,A
	JR	Z,WaitI2	; Go if interrupt set
	DEC	C
	JR	NZ,WaitI1
	DJNZ	WaitI1		; 65k loops
	DEC	D
	JR	NZ,WaitI1	; Coarse outer loop
	SCF
	JR	WaitI3		; Exit: timed out

WaitI2:	XOR	A		; Exit: OK
WaitI3:	POP	DE
	POP	BC
	RET

;--------------------------------
; Check results of I/O operations
;  IY -> test-block for status:  (see "launch" for details)

TestResult:
	CALL	WaitInt		; Wait for completion
	LD	A,TIMEOUT
	JR	C,Exit		; Failed (CY posted to caller)
			; Get 7 result bytes after read/write
	PUSH	BC
	PUSH	DE
	LD	DE,resTab	; Point to Result Table
	LD	B,7		; No. of expected bytes
Lc3:	CALL	GetByte
	LD	(DE),A
	INC	DE		; Post it
	DJNZ	Lc3
	POP	DE
	POP	BC
	LD	HL,resTab	; Pointer to results block
	PUSH	HL

	LD	A,(HL)		; Get ST0
	AND	0F8H		; Kill variable bits (just errors)
	CP	(IY+TST0)	; Check to expected value
	JR	NZ,Bad
	INC	HL
	LD	A,(HL)		; Get ST1
	AND	0FDH		;;  (Kill W/P Bit se we can read W/P Disks)
	CP	(IY+TST1)	; Check to expected value
	JR	NZ,Bad
	INC	HL
	LD	A,(HL)
	SUB	0		; No "funny" errors (ever!)
	JR	NZ,Bad

;; Don't check the count to avoid problems with commands that don't use DMA
;; (ReadID)
	LD	A,CMD_RDID
	CP	(IY+0)
	JR	Z,skip1
	IN0	L,(BCR0L)
	IN0	A,(BCR0H)
	OR	L		; Check that all was transferred
	POP	HL
	LD	A,LOSTDAT
	JR	NZ,Bad		; Should have counted back to zero

	XOR	A		; It all succeeded!
	JR	Exit		; OK: return CY=0 (A=0)
skip1:
	pop	hl
	xor	a
	jr	exit

Bad1:	LD	A,BADSECT	; Bad sector specification
	SCF
	JR	Exit

Bad:	LD	A,IOERR		; Error post: see block at (HL)
	POP	HL
	SCF
Exit:	RET			; CY = error

;--------------------------------
; Send A to Cmnd/data port

SndByt:	PUSH	AF
Scb1:   IN0     A,(_MSR)	; Check FDC status
	BIT	7,A		; Wait till ready
	JR	Z,Scb1
	POP	AF		; Recover the cmnd. byte
	OUT0	(_DATA),A
	RET

;--------------------------------
; Read Cmnd/data port to A

GetByte: IN0	A,(_MSR)
	BIT	7,A		; Ready?
	JR	Z,GetByte
	IN0	A,(_DATA)	; Get it
	RET

;--------------------------------
; Send string of commands from HL

SndCmStr: PUSH	BC		; 1st. byte is count
	LD	B,(HL)		; Save count
SndC1:	INC	HL
	LD	A,(HL)		; Get cmnd. byte
	CALL	SndByt		; Send it
	DJNZ	SndC1		; Repeat
	POP	BC
	RET

;--------------------------------
; Force a recalibrate on this drive

Uncal:	PUSH	HL
	LD	HL,calibd	;First force a recalibrate
	LD	A,(MASK)
	CPL
	AND	(HL)		;Turn of the "calibrated" bit
	LD	(HL),A
	POP	HL
	RET

;--------------------------------
; Set up DMA buffers for input

DMAInp:	call	absaddr		;Get physical addr. for DMA
	out0	(dar0l),l
	out0	(dar0h),h
	out0	(dar0b),a	;Destination pointers
	ld	a,_DMA
	out0	(sar0l),a	;Source: FDC's DMA port
	xor	a
	out0	(sar0h),a
	out0	(sar0b),a	;Controlled by /DREQ0
	ret
 
;--------------------------------
; Set up DMA buffers for output

DMAOut:	call	absaddr		;Get physical addr. for DMA
	out0	(sar0l),l
	out0	(sar0h),h
	out0	(sar0b),a	;Source pointers
	ld	a,_DMA
	out0	(dar0l),a	;Destn.: FDC's DMA port
	xor	a
	out0	(dar0h),a
	out0	(dar0b),a	;Controlled by /DREQ0
	ret
 
;--------------------------------
; Offsets for inline arguments

OPCODE	EQU	0		; Command to FDC
TST0	EQU	1		; Match Status 0
TST1	EQU	2		;   "	  "   1
SKIP	EQU	3		; No. of bytes to skip at return

; Initiate a read or write command

Launch:	EX	(SP),IY		; Save IY, point at argts.
	LD	A,E		; Find final sector for transfer
	ADD	A,B
	DEC	A		; Last sector to do
;; Delete following to permit offset Sector Numbers
;;	DEC	A		; 1 under final
;;	CP	(IX+EOT)	; This MUST be < true final
;;	JR	NC,Bad1
;;	INC	A		; True final sector
	LD	H,A		; Save it

	LD	A,(IY+OPCODE)
	CALL	SndByt		; Command code
	LD	A,D		; Drive
	BIT	0,C		; Odd track (ie Side 1)?
	JR	Z,Lc1
	SET	2,A
Lc1:	CALL	SndByt		; Drive & head
	LD	A,C
	SRL	A		; Cylinder
	CALL	SndByt
	LD	A,C
	AND	1
	CALL	SndByt		; Head
	LD	A,E
	CALL	SndByt		; Sector
	LD	A,(IX+SECSZE)
	CALL	SndByt		; Sector length (encoded)
	LD	A,H
	CALL	SndByt		; Final sector no.
	LD	A,(IX+GPL)
	CALL	SndByt		; Gap length

	LD	A,DMA_RUN	; Activate DMA Ch-0
	OUT0	(DSTAT),A

	LD	A,0FFH		; Data transfer length (default)
	CALL	SndByt		; Final byte: FDC & DMA running

	CALL	TestResult	; Find out what happened
	PUSH	BC
	PUSH	AF
	LD	BC,SKIP
	ADD	IY,BC		; Jump past the inline params.
	POP	AF
	POP	BC
	EX	(SP),IY		; Recover IY, post link
	RET

;--------------------------------
; Determine buffer size (DMA count set)

TranSze: push	hl
	push	de
	push	bc
	ld	hl,64
	ld	b,(ix+SECSZE)	;Size N, => 128*2^N
	inc	b
tz1:	add	hl,hl
	djnz	tz1
	ld	d,h
	ld	e,l		;Sector size in DE
	ld	hl,0
	pop	bc		;No. of sectors in B
	push	bc
tz2:	add	hl,de		;Form total in HL
	djnz	tz2
	out0	(bcr0l),l	;Set DMA counter
	out0	(bcr0h),h
	ld	(blksze),hl	;Save block size
 
	pop	bc
	pop	de		;Restore regs.
	pop	hl
	ret
 
;--------------------------------
; Finish of a seek/recalibrate function

EndSeek: call	waitint		;Wait for it
	ld	a,timeout
	ret	c		;Timed out
 
	ld	a,cmd_sense	;"Sense Interrupt" at the end
	call	SndByt
	call	getbyte
	ld	b,a		;ST0 in B
	call	getbyte		;PCN in A
 
	push	bc		;Verify correct cylinder
	srl	c
	cp	c		;Yes?
	pop	bc
	ld	a,sekerr
	scf
	ret	nz		;Quit if unequal
 
	ld	a,b		;Get back ST0
	and	0e0h
	cp	20h		;Look for success
	ret	z
	ld	a,calerr
	scf
	ret			;CY=1 if it failed
 
;--------------------------------
DORON	EQU	0CH		; Basic state: no drives, no reset, DMA

FSetup:		; Prepare for a Read or Write operation
	PUSH	BC		; Save them...
	PUSH	HL

	LD	B,D		; Drive no.
	INC	B
	LD	A,08H
Su1:	ADD	A,A
	DJNZ	Su1		; Shift drive bit as reqd.
	LD	(mask),A	; Save drive indicator bit
	LD	B,A		; Local copy

	IN0	A,(_DOR)
	LD	C,A
	AND	0FCH		; Kill select bits
	OR	D		; Select reqd. drive
	OR	DORON		; No reset, DMA
	OUT0	(_DOR),A	; Selected

	LD	A,C
	AND	B		; Is this drive running?
	JR	NZ,Su2
	IN0	A,(_DOR)
	OR	B		; Start it up
	OUT0	(_DOR),A

; Wait for motor to run-up. NB this delay assumes:
; 1. 16MHz CPU clock
; 2. 2 wait states per memory access
; 3. Z-80 instruction cycle-counts

	LD	BC,0		; Prime for inner loop
	IN0	A,(CCR)
	RLA			; Hi-Speed CPU?
	LD	A,(IX+MTRON)	; Load Basic Delay Constant
	JR	C,Mo1		; ..jump if Low-Speed
	ADD	A,A		; Else Scale for Inner Loop (double count)
Mo1:	DJNZ	Mo1	; 17*256 = 4352 clocks
	DEC	C	;            6
	JR	NZ,Mo1	;           17
			;         ----
			;         4375 clocks
			;        x 256
			;      -------
			;    1,120,000 clocks
			; or, 1/16 second
	DEC	A
	JR	NZ,Mo1	; Full delay

Su2:			; Send the SPECIFY command (all from DPB)
	LD	A,(IX+DRATE)
	OUT0	(_CCR),A	; Data rate as reqd.

	LD	A,03H		; "Specify"
	CALL	SndByt   

	LD	A,(NVRate)
	BIT	7,A		; Valid Non-Volatile Configuration?
	JR	NZ,Su2A		; ..jump if Not
	INC	D
	DEC	D		; Drive A: (Unit 0)?
	LD	A,(flpy0T)	;  (prepare for Yes)
	JR	Z,Su20		; ..jump if So
	LD	A,(flpy1T)	; Else get Timings for Drive B: (Unit 1)
Su20:	PUSH	AF		;  (save)
	AND	0FH		;  keep only SRT
	NEG			;   make 2's complement
	RLA			; Move
	RLA			;  to
	RLA			;   High
	RLA			;    Nibble
	OR	0FH		;     and add Maximum HUT
	CALL	SndByt
	POP	AF		; Restore timings byte for HLT
	RRA			; Move HLT
	RRA			;  down
	RRA			;   to count * 4
	AND	1EH		;    kill possible junk, insure DMA bit=0
	JR	Su2B		;   ..and jump to Set

Su2A:	LD	A,(IX+SPEC_1)
	CALL	SndByt   
	LD	A,(IX+SPEC_2)
	RES	0,A		; Be sure DMA is activated
Su2B:	CALL	SndByt

	LD	HL,calibd
	LD	A,(mask)
	AND	(HL)		; Is this drive calibrated?
	JR	NZ,Su3		; Done if so

	LD	A,CMD_RECAL
	CALL	SndByt		; Send the "recal" command
	LD	A,D
	CALL	SndByt		; Drive no.

	CALL	EndSeek		; Finish the operation
	JR	C,Su5		; Jump if error
	LD	A,(mask)
	OR	(HL)
	LD	(HL),A		; Flag it calibrated, now
Su3:	XOR	A		; Success...

Su5:	AND	A		; Set the Z bit
	POP	HL
	POP	BC
	RET			; Done: Z set if OK

;======================================================================
;	C O M M A N D   D E S P A T C H E R
 
DiskOp:	CP	MAXCMD
	JR	C,Do1
	LD	A,BADCMD
	SCF
	RET			; Illegal command

Do1:	CALL	Entry		; Enter the slave routine
	PUSH	AF		; Save exit status
	CALL	C,Reset		; If errors, reset the FDC
	POP	AF
	RET	C		; If error, take exit code
	XOR	A		; If OK, return zero
	RET			; Back to caller

Entry:	PUSH	HL		; Save it
	LD	HL,dTab
	ADD	A,A		; Scale opcode by 2
	ADD	A,L
	LD	L,A		; Access the jumptable
	JR	NC,Do2
	INC	H		; Propagate carry
Do2:	LD	A,(HL)		; Look into the table
	INC	HL
	LD	H,(HL)
	LD	L,A

	EX	(SP),HL		; Recover HL: routine ptr. on stack
	RET			; Switch to routine

dTab:	DW	Reset		; Pointers to function routines
	DW	Motors
	DW	XRead		; I/O functions: call wrappers
	DW	XWrite
	DW	XVerf
	DW	XForm
	DW	AbsAddr
MAXCMD	 EQU  ($-dTab)/2	; No. of valid commands

;======================================================================
;	I / O   C O M M A N D   W R A P P E R   F U N C T I O N
 
;  The READ, WRITE, VERIFY and FORMAT commands are essentially identical.
; The despatcher calls a stub, which sets up a common wrapper to
; run the required sub-function, and to implement re-tries in the
; event of data errors.
 
; Wrapper stubs. The common tail is called with the user's HL stacked,
; and HL pointing to the required sub-function.

JPOPC	 EQU  0C3H		; A "JP" opcode

XRead:	PUSH	HL
	LD	HL,XReadS	; Sub-function pointer
	JR	ComTail

XWrite:	PUSH	HL
	LD	HL,XWritS
	JR	ComTail

XVerf:	PUSH	HL
	LD	HL,Verify
	JR	ComTail

XForm:	PUSH	HL
	LD	HL,Format

; Common tail of the "wrapper" function

ComTail: LD	(Switch+1),HL	; Target for the despatcher
	POP	HL		; Caller's value
	PUSH	AF
	LD	A,JPOPC
	LD	(Switch),A	; Complete the "JP" instruction

	PUSH	HL
	LD	HL,0
	LD	(blkSze),HL	; Default value
	POP	HL

	LD	A,TRIES
Again:	LD	(rtCnt),A	; Retry counter
	POP	AF

	PUSH	HL
	CALL	Switch		; To the sub-function
	POP	HL		; Save HL (no others changed)

	JR	NC,Ok		; Exit: no error
	CP	IOERR		; Was it an IO error?
	JR	Z,More
	CP	SEKERR		; Or a seek error
	JR	NZ,Fatal	; No: other errors are fatal

More:	PUSH	AF		; Seek or IO errors: retry
	call	Reset		;;;-----;;;
	CALL	Uncal		; Reset the "calibrated" bit
	LD	A,(rtCnt)
	DEC	A		; Count attempts
	JR	NZ,Again	; More to go

	POP	AF		; Exhausted: get the error code
Fatal:
	IF	VERBOSE
	call	perror
	ENDIF
	SCF			; Hard errors
	LD	DE,resTab	; Pass the result pointer
	RET

Ok:	LD	DE,(blkSze)
	ADD	HL,DE		; Success: index HL past block
	LD	DE,resTab	; Return DE -> status block
	RET

;-------------------------------
; Common stub for sub-functions to exit with error

Fails:	SCF			; Return Carry for Error
	RET

;======================================================================
;	R E S E T   T H E   D I S K E T T E   S Y S T E M

Reset:	PUSH	HL
	XOR	A
	LD	(calibd),A	; All drives uncalibrated
	OUT0	(_DOR),A	; Force reset
	LD	A,DORON
	OUT0	(_DOR),A	; All drives off (DMA asserted)
	LD	HL,cnfgTab
	CALL	SndCmStr	; "Configure"
	XOR	A		; Post OK
	POP	HL
	RET

cnfgTab: DB	ECFT-$-1	; Length
	DB	13H		; "Configure"
	DB	00H		; Required
	DB	71H		; No FIFO in use
	DB	43		; Write precomp point
ECFT	  EQU  $
 
;======================================================================
;	T U R N   O F F   A L L   D R I V E - M O T O R S

;  This command is really only needed until interrups are supported,
; since it is then possible to automatically turn off a drive which has
; not been accessed for some time.
;  This command is used by the elementary BIOS keyboard routine: the
; drives are turned off if the system has waited for keyboard input
; for too long - a simple method!

Motors:	IN0	A,(_DOR)
	AND	0FH		; Drop motor lines: keep selection
	OUT0	(_DOR),A
	XOR	A		; "Success"
	RET

;======================================================================
;	R E A D   O N E   O R   M O R E   S E C T O R S

XReadS:	CALL	FSetup		; Drive selected & ready
	JR	NZ,Fails

	CALL	DMAInp		; Set up DMA pointers for input
	CALL	TranSze		; Get total buffer size

	LD	A,DMA_INCMD
	OUT0	(DMODE),A	; DMA set up: IO => MEM

	CALL	Launch		; Go fire it off
	DB	CMD_READ		; Command code
	DB	40H			; Expected ST0
	DB	80H			; Expected ST1
	RET			; CY=fault: HL -> result phase

;======================================================================
;	W R I T E   O N E   O R   M O R E   S E C T O R S

XWritS:	CALL	FSetup		; Drive selected & ready
	JR	NZ,Fails

	CALL	DMAOut		; Set up DMA pointers for output
	CALL	TranSze		; Get total buffer size

	LD	A,DMA_OUTCMD
	OUT0	(DMODE),A	; DMA set up: MEM => IO

	CALL	Launch		; Go fire it off
	DB	CMD_WRITE		; Command code
	DB	40H			; Expected ST0
	DB	80H			; Expected ST1
	RET			; CY=fault: HL -> result phase

;======================================================================
;	V E R I F Y   S E C T O R S  -  N O   T R A N S F E R

Verify:	CALL	FSetup		; Drive selected & ready
	JR	NZ,Fails

	CALL	Launch		; Go fire it off
	DB	CMD_VERIFY		; Command code
	DB	0			; Expected ST0
	DB	0			; Expected ST1
	RET			; CY=fault: HL -> result phase

;======================================================================
;	F O R M A T   A   T R A C K   O F   T H E   D I S K E T T E

Format:
	  IFDEF  INCFORMAT	;Do we include FORMAT ?
	call	FSetup		;Drive running, & calibrated
	jp	nz,fails
 
	ld	a,cmd_seek	;Seek to the required track
	call	SndByt		;We cannot use "implied seeks" here
	ld	a,d
	bit	0,c
	jr	z,fm1
	set	2,a		;A = drive & head bits
fm1:	call	SndByt
	ld	a,c
	srl	a		;Cylinder no.
	call	SndByt
 
	call	endseek		;Wait for seek to complete
	ret	c		;Failed
 
	call	DMAOut		;DMA pointers for output
 
	push	hl
	ld	l,(ix+EOT)	;No. of sectors
	ld	h,0
	add	hl,hl
	add	hl,hl		;4 bytes/sector
	out0	(bcr0l),l
	out0	(bcr0h),h	;Set up DMA counter
	ld	(blksze),hl
	pop	hl
 
	ld	a,dma_outcmd
	out0	(dmode),a	;DMA armed to output
 
	ld	a,cmd_format	;Now initiate the FDC
	call	SndByt
	ld	a,d
	bit	0,c
	jr	z,fm2
	set	2,a		;Side select
fm2:	call	SndByt		;Drive & side
	ld	a,(ix+SECSZE)
	call	SndByt		;Sector size
	ld	a,(ix+EOT)
	call	SndByt		;Final sector no.
	ld	a,(ix+GAPFMT)
	call	SndByt		;Gap-3 length
 
	ld	a,dma_run
	out0	(dstat),a	;Kick off the DMA
 
	ld	a,(ix+DATFMT)
	call	SndByt		;Last byte: FDC running
 
	push	iy
	ld	iy,fmtres	;Expected results
	call	testresult	;Wait for it...
	pop	iy
	ret			;A and CY show result

fmtres:	db	0		;Filler
	db	0		;ST-0
	db	0		;ST-1

	  ELSE
	JR	Fails		;No FORMAT command
	  ENDIF

;======================================================================
;	R E A D    D I S K    S E C T O R    I D    D A T A
; Enter: D = Disk Number (A=0, B=1, etc)
;	IX -> Disk Definition Table (Original characteristics table)
; Exit : A = 0, Zero Set (Z), Carry Clear (NC) if ID Read Correctly
;	   Carry Set (C) if Timeout (Reg A and Zero Flag indeterminate)
;	   A <> 0, Zero Reset (NZ) if Error Reading ID (Carry indeterminate)

ReadID:	CALL	FSetup		; Start Motors, Select, etc...
	JR	NZ,Fails	; ..signify Error on return if Bad
	LD	A,CMD_RDID
	CALL	SndByt		; Command the Controller
	LD	A,D
	CALL	SndByt		;  with Drive #
	LD	IY,RIDres	;    (check results with this)
	CALL	TestResult	;   get controller response
	RET	C		;  ..return Carry set if Timeout

; Sort out the data, determining which Disk format if possible

	LD	HL,resTab	; The Command results went here
	LD	DE,6
	ADD	HL,DE		;  offset to Sector Size
	LD	A,(HL)		;   fetch
	OR	A		;    and insure Carry Clear
	RET

RIDres:	DB	4AH		; Command
	DB	00		; Expected ST0
	DB	00		; Expected ST1

;======================================================================
; C O N V E R T   L O G I C A L   T O   P H Y S I C A L   A D D R E S S

;  This utility converts a logical address (in HL) to a 20-bit physical
; address (in AHL). Other registers are unchanged. Absolute addresses
; are used by the Z182 DMA.
;  The routine accesses the memory-mapping hardware registers, to obtain
; the current translations.
;	NB This code assumes that CA1 > BA > CA0

absaddr:          ;Converts HL to AHL
        push    hl
        ld      a,h     ;First, see which logical bank
        and     0f0h
        ld      h,a     ;Save 4kB page
        in0     a,(cbar)
        and     0f0h    ;CA1 logical base
        ld      l,a
        ld      a,h
        sub     l       ;Form Addr - Base
        jr      c,not1  ;If CY: Addr < Base, so don't use
        in0     a,(cbr) ;It is CA1 - take base
        jr      mod
 
not1:   in0     a,(cbar)
        add     a,a
        add     a,a
        add     a,a
        add     a,a     ;BA logical base in A[7:4]
        ld      l,a
        ld      a,h
        sub     l       ;Form Addr - Base
        ld      a,0
        jr      c,mod   ;Not BA, must be CA0
        in0     a,(bbr) ;Else, it is BA
mod:
        pop     hl      ;Now do the adjustment
        push    bc      ;Save it
        push    hl      ;Save HL again
        ld      c,h
        ld      b,0     ;BC = HL >> 8
        ld      l,a
        ld      h,b     ;HL = physical base
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl   ;HL = physical base << 4
        add     hl,bc   ;Top address in HL
        ld      a,h
        and     0fh     ;Bits 19:16 in A
        ld      b,l     ;Save bits 15:8
        pop     hl
        ld      h,b     ;Full address in AHL
        pop     bc      ;Restore BC
	and	a	;CY=0 (ie no errors)
	ret		; Done

;--------------------------------------------------------------------

	IF	VERBOSE

perror:	push	af
	ld	(errc),a
	ld	a,c
	ld	(ptrkn),a
	ld	a,e
	ld	(psecn),a
	push	hl
	push	de
	push	bc
	ld	hl,emsg1
	call	putmsg
	ld	a,(sekdsk)
	add	a,'A'
	ld	c,a
	call	conout
	ld	hl,emsg2
	call	putmsg
	ld	a,(ptrkn)
	call	adec
	ld	hl,emsg3
	call	putmsg
	ld	a,(psecn)
	call	adec
	ld	hl,emsg4
	call	putmsg
	call	errmsg
	pop	bc
	pop	de
	pop	hl
	pop	af
	ret

emsg1:	db	0dh,0ah,'Error on drive ',0
emsg2:	db	', track ',0
emsg3:	db	', sector ',0
emsg4:	db	': ',0

ahex:	push	af
	rrc	a
	rrc	a
	rrc	a
	rrc	a
	call	ahex1
	pop	af
ahex1:	and	0Fh
	cp	10
	jr	c,ahex2
	add	a,7
ahex2:	add	a,'0'
	push	bc
	ld	c,a
	call	conout
	pop	bc
	ret

adec:	ld	c,'0'
ad2:	cp	10
	jr	c,ad1
	inc	c
	sub	10
	jr	ad2
ad1:	push	af
	call	putc
	pop	af
	add	a,'0'
	ld	c,a
putc:	push	bc
	call	conout
	pop	bc
	ret

e1:	db	'Recalibration error',0
e3:	db	'Bad sector length',0
e4:	db	'DMA underrun',0
e5:	db	'Interrupt timeout',0
e6:	db	'Invalid function code',0
e7:	db	'Seek error',0

errtab:	dw	e1,eu,e3,e4,e5,e6,e7

e21:	db	'CRC error',0
e22:	db	'DMA overrun',0
e23:	db	'Sector not found',0
e24:	db	'Write protect',0
e25:	db	'Missing address mark',0

errt02:	dw	e25,e24,e23,eu,e22,e21

eu:	db	'Unknown',0

errmsg:	ld	a,(errc)
	or	a
	ret	z
	cp	2
	jr	z,err2
	cp	8
	jr	nc,unknw
	ld	hl,errtab
em2:	dec	a
	jr	z,em1
	inc	hl
	inc	hl
	jr	em2
em1:	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	jp	putmsg

unknw:	ld	hl,eu
	call	putmsg
	ld	c,' '
	call	conout
	ld	a,(errc)
	jp	ahex

err2:	ld	a,(restab+1)
	and	37h
	ld	hl,errt02
em3:	rrc	a
	jr	c,em1
	inc	hl
	inc	hl
	jr	em3

errc:	ds	1
ptrkn:	ds	1
psecn:	ds	1

	ENDIF
