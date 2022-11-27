; Disassembly of ISX 1.4 SETEOF utility.

	cseg

bdos	equ	5
fcb	equ	5Ch
cpm_bfr	equ	80h

start:	lxi	h,0
	dad	sp
	shld	cpm_sp
	lxi	sp,stack
	lxi	d,fcb
	mvi	c,15		; open file
	call	bdos
	inr	a
	jz	loc_1
	mvi	c,35		; compute file size
	lxi	d,fcb
	call	bdos
	lhld	fcb+21h		; r0,r1 - contain the number of records
	dcx	h
	shld	fcb+21h
	mvi	c,33		; read random
	lxi	d,fcb
	call	bdos		; read the last record
	ora	a
	jnz	loc_1
	lxi	d,cpm_bfr+80H	; 100h
	lxi	h,fcb+0Dh	; s1
	mvi	m,0
loc_6:	dcx	d
	ldax	d
	cpi	1Ah		; ^Z (eof) ?
	jnz	loc_5
	inr	m
	jmp	loc_6
loc_5:	lxi	h,fcb+0Eh	; s2
	mov	a,m
	ani	7Fh
	mov	m,a
	mvi	c,16		; close file
	lxi	d,fcb
	call	bdos
loc_1:	lhld	cpm_sp
	sphl	
	ret	

cpm_sp:	ds	2		; CP/M stack pointer
	ds	32
stack	equ	$

	end	start
