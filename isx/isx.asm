; Disassembly of Digital Research's ISIS emulator ISX.COM

		cseg

wboot		equ	0
iobyte		equ	3
cpm_disk	equ	4
bdos		equ	5

vec_38		equ	38h
vec_40		equ	40h

unk_1		equ	5Bh
cpm_fcb		equ	5Ch
cpm_bfr		equ	80h

;----------------------------------------------------------------------

		org	100h

start:
		jmp	main

loc_2:
		jmp	bdos_ept

tr_level:	db	0			; trace level
word_3:		dw	0
word_4:		dw	0
word_5:		dw	0

;		ds	115

;----------------------------------------------------------------------

		org	180h

; This BDOS subsystem (0180H - 0FFFH) replaces the CP/M BDOS,
; which is overlayed by ISIS application programs.
;
; This is basically a CP/M 2.2 BDOS, with a minor modification to
; support exact file sizes.

bdos_ept:
		jmp	bdose

;----------------------------------------------------------------------

		lhld	wboot+1
		mvi	l,0		; boot?
		pchl	

dos_reset:
		lhld	wboot+1
		mvi	l,3		; BIOS wboot
		pchl	

b_const:
		lhld	wboot+1
		mvi	l,6		; BIOS const
		pchl	

b_conin:
		lhld	wboot+1
		mvi	l,9		; BIOS conin
		pchl	

b_conout:
		lhld	wboot+1
		mvi	l,0Ch		; BIOS conout
		pchl	

b_list:
		lhld	wboot+1
		mvi	l,0Fh		; BIOS list
		pchl	

b_punch:
		lhld	wboot+1
		mvi	l,12h		; BIOS punch
		pchl	

b_reader:
		lhld	wboot+1
		mvi	l,15h		; BIOS reader
		pchl	

b_home:
		lhld	wboot+1
		mvi	l,18h		; BIOS home
		pchl	

b_seldsk:
		lhld	wboot+1
		mvi	l,1Bh		; BIOS seldsk
		pchl	

b_settrk:
		lhld	wboot+1
		mvi	l,1Eh		; BIOS settrk
		pchl	

b_setsec:
		lhld	wboot+1
		mvi	l,21h		; BIOS setsec
		pchl	

b_setdma:
		lhld	wboot+1
		mvi	l,24h		; BIOS setdma
		pchl	

b_read:
		lhld	wboot+1
		mvi	l,27h		; BIOS read
		pchl	

b_write:
		lhld	wboot+1
		mvi	l,2Ah		; BIOS write
		pchl	

		lhld	wboot+1
		mvi	l,2Dh		; BIOS listst
		pchl	

b_sectran:
		lhld	wboot+1
		mvi	l,30h		; BIOS sectran
		pchl	

;----------------------------------------------------------------------

err_tbl:	dw	err_badsec
e_sel:		dw	err_select
e_ro:		dw	err_ro
e_filero:	dw	err_filero

;----------------------------------------------------------------------

bdose:
		xchg	
		shld	info
		xchg	
		mov	a,e
		sta	linfo
		lxi	h,0
		shld	lret
		dad	sp
		shld	entsp
		lxi	sp,lstack
		xra	a
		sta	fcbdsk
		sta	resel
		lxi	h,goback	; return address
		push	h
		mov	a,c
		cpi	41		; maxfunc + 1
		rnc	
		mov	c,e
		lxi	h,dos_ftbl
		mov	e,a
		mvi	d,0
		dad	d
		dad	d
		mov	e,m
		inx	h
		mov	d,m
		lhld	info
		xchg	
		pchl	

;----------------------------------------------------------------------

dos_ftbl:	dw	dos_reset
		dw	dos_conin
		dw	dos_conout
		dw	dos_rdrin
		dw	b_punch
		dw	b_list
		dw	dos_condir
		dw	dos_getiob
		dw	dos_setiob
		dw	dos_putstr
		dw	dos_conbfr
		dw	dos_const
		dw	dos_vers
		dw	dos_dskrst
		dw	dos_seldsk
		dw	dos_open
		dw	dos_close
		dw	dos_sfst
		dw	dos_snxt
		dw	dos_erase
		dw	dos_read
		dw	dos_write
		dw	dos_makef
		dw	dos_rename
		dw	dos_getlog
		dw	dos_getdsk
		dw	dos_setdma
		dw	dos_getalloc
		dw	dos_setro
		dw	dos_getro
		dw	dos_attrib
		dw	dos_getdpb
		dw	dos_user
		dw	dos_rndrd
		dw	dos_rndwr
		dw	dos_filesz
		dw	dos_setrec
		dw	dos_drvrst
		dw	func_ret
		dw	func_ret
		dw	dos_rndwrzf

;----------------------------------------------------------------------

err_badsec:
		lxi	h,bad_sec
		call	errflg
		cpi	3
		jz	wboot
		ret	

;----------------------------------------------------------------------

err_select:
		lxi	h,sel_errm
		jmp	loc_6

err_ro:
		lxi	h,disk_ro
		jmp	loc_6

err_filero:
		lxi	h,file_ro

loc_6:
		call	errflg
		jmp	wboot

;----------------------------------------------------------------------

dos_errm:	db	'Bdos Err On '
dsk_errm:	db	' : $'
bad_sec:	db	'Bad Sector$'
sel_errm:	db	'Select$'
file_ro:	db	'File '
disk_ro:	db	'R/O$'

;----------------------------------------------------------------------

errflg:
		push	h
		call	dos_crlf	; dos cr/lf
		lda	curdsk
		adi	'A'
		sta	dsk_errm
		lxi	b,dos_errm
		call	dos_print
		pop	b
		call	dos_print
d_conin:	lxi	h,kbchar
		mov	a,m
		mvi	m,0
		ora	a
		rnz	
		jmp	b_conin

;----------------------------------------------------------------------

conech:
		call	d_conin
		call	is_echoc
		rc	
		push	psw
		mov	c,a
		call	dos_conout
		pop	psw
		ret	

;----------------------------------------------------------------------

is_echoc:
		cpi	0Dh		; cr
		rz	
		cpi	0Ah		; lf
		rz	
		cpi	9		; tab
		rz	
		cpi	8		; backspace
		rz	
		cpi	20h		; space
		ret	

;----------------------------------------------------------------------

conbrk:					; check for char ready
		lda	kbchar
		ora	a
		jnz	conb1
		call	b_const
		ani	1
		rz	
		call	b_conin
		cpi	13h		; ctrl/s
		jnz	conb0
		call	b_conin
		cpi	3		; ctrl/c
		jz	wboot
		xra	a
		ret	

conb0:		sta	kbchar
conb1:		mvi	a,1
		ret	

;----------------------------------------------------------------------

d_conout:
		lda	compcol
		ora	a
		jnz	compout
		push	b
		call	conbrk		; check for char ready
		pop	b
		push	b
		call	b_conout
		pop	b
		push	b
		lda	listcp
		ora	a
		cnz	b_list
		pop	b
compout:	mov	a,c
		lxi	h,column
		cpi	7Fh		; rubout
		rz	
		inr	m
		cpi	' '
		rnc	
		dcr	m
		mov	a,m
		ora	a
		rz	
		mov	a,c
		cpi	8		; backspace
		jnz	notbksp
		dcr	m
		ret	

notbksp:	cpi	0Ah		; lf
		rnz	
		mvi	m,0
		ret	

;----------------------------------------------------------------------

ctlout:
		mov	a,c
		call	is_echoc
		jnc	dos_conout
		push	psw
		mvi	c,'^'
		call	d_conout
		pop	psw
		ori	40h
		mov	c,a
dos_conout:
		mov	a,c
		cpi	9		; tab
		jnz	d_conout
tab0:		mvi	c,' '
		call	d_conout
		lda	column
		ani	7
		jnz	tab0
		ret	

;----------------------------------------------------------------------

backup:					; backup one screen position
		call	bckspc
		mvi	c,' '
		call	b_conout
bckspc:		mvi	c,8		; backspace
		jmp	b_conout

;----------------------------------------------------------------------

crlfp:
		mvi	c,'#'
		call	d_conout
		call	dos_crlf	; dos cr/lf
crlfp0:		lda	column
		lxi	h,strtcol
		cmp	m
		rnc	
		mvi	c,' '
		call	d_conout
		jmp	crlfp0

;----------------------------------------------------------------------

dos_crlf:
		mvi	c,0Dh		; cr
		call	d_conout
		mvi	c,0Ah		; lf
		jmp	d_conout

;----------------------------------------------------------------------

dos_print:
		ldax	b
		cpi	'$'
		rz	
		inx	b
		push	b
		mov	c,a
		call	dos_conout
		pop	b
		jmp	dos_print

;----------------------------------------------------------------------

dos_conbfr:
		lda	column
		sta	strtcol
		lhld	info
		mov	c,m
		inx	h
		push	h
		mvi	b,0
readnx:		push	b
		push	h
readn0:		call	d_conin
		ani	7Fh
		pop	h
		pop	b
		cpi	0Dh		; cr
		jz	readen
		cpi	0Ah		; lf
		jz	readen
		cpi	8		; backspace
		jnz	noth
		mov	a,b
		ora	a
		jz	readnx
		dcr	b
		lda	column
		sta	compcol
		jmp	linelen

noth:		cpi	7Fh		; rubout
		jnz	notrub
		mov	a,b
		ora	a
		jz	readnx
		mov	a,m
		dcr	b
		dcx	h
		jmp	rdech1

notrub:		cpi	5		; ctrl/e
		jnz	notcte
		push	b
		push	h
		call	dos_crlf	; dos cr/lf
		xra	a
		sta	strtcol
		jmp	readn0

notcte:		cpi	10h		; ctrl/p
		jnz	notctp
		push	h
		lxi	h,listcp
		mvi	a,1
		sub	m
		mov	m,a
		pop	h
		jmp	readnx

notctp:		cpi	18h		; ctrl/x
		jnz	notctx
		pop	h
backx:		lda	strtcol
		lxi	h,column
		cmp	m
		jnc	dos_conbfr
		dcr	m
		call	backup		; backup one screen position
		jmp	backx

notctx:		cpi	15h		; ctrl/u
		jnz	notctu
		call	crlfp
		pop	h		; discard starting position
		jmp	dos_conbfr	; start all over

notctu:		cpi	12h		; ctrl/r
		jnz	notctr
linelen:	push	b
		call	crlfp
		pop	b
		pop	h
		push	h
		push	b
rep0:		mov	a,b
		ora	a
		jz	rep1
		inx	h
		mov	c,m
		dcr	b
		push	b
		push	h
		call	ctlout
		pop	h
		pop	b
		jmp	rep0

rep1:		push	h
		lda	compcol
		ora	a
		jz	readn0
		lxi	h,column
		sub	m
		sta	compcol

backsp:		call	backup		; backup one screen position
		lxi	h,compcol
		dcr	m
		jnz	backsp
		jmp	readn0

notctr:		inx	h
		mov	m,a
		inr	b
rdech1:		push	b
		push	h
		mov	c,a
		call	ctlout
		pop	h
		pop	b
		mov	a,m
		cpi	3		; ctrl/c
		mov	a,b
		jnz	notctc
		cpi	1		; ctrl/c must be the first char
		jz	wboot
notctc:		cmp	c
		jc	readnx
readen:		pop	h
		mov	m,b
		mvi	c,0Dh
		jmp	d_conout

;----------------------------------------------------------------------

dos_conin:
		call	conech
		jmp	sta_ret

;----------------------------------------------------------------------

dos_rdrin:
		call	b_reader
		jmp	sta_ret

;----------------------------------------------------------------------

dos_condir:
		mov	a,c
		inr	a
		jz	dirinp
		inr	a
		jz	b_const
		jmp	b_conout

;----------------------------------------------------------------------

dirinp:
		call	b_const
		ora	a
		jz	retmon
		call	b_conin
		jmp	sta_ret

;----------------------------------------------------------------------

dos_getiob:
		lda	iobyte
		jmp	sta_ret

;----------------------------------------------------------------------

dos_setiob:
		lxi	h,iobyte
		mov	m,c
		ret	

;----------------------------------------------------------------------

dos_putstr:
		xchg	
		mov	c,l
		mov	b,h
		jmp	dos_print

;----------------------------------------------------------------------

dos_const:				; check for char ready
		call	conbrk
sta_ret:
		sta	lret
func_ret:
		ret	

;----------------------------------------------------------------------

setlret1:
		mvi	a,1
		jmp	sta_ret

;----------------------------------------------------------------------

compcol:	db	0		; true if computing column position
strtcol:	db	0
column:		db	0
listcp:		db	0		; printer echo flag
kbchar:		db	0
entsp:		dw	0

		ds	48
lstack		equ	$

usrcode:	db	0
curdsk:		db	0
info:		dw	0
lret:		dw	0

;----------------------------------------------------------------------

sel_error:
		lxi	h,e_sel
goerr:
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		pchl	

;----------------------------------------------------------------------

move:
		inr	c
move0:		dcr	c
		rz	
		ldax	d
		mov	m,a
		inx	d
		inx	h
		jmp	move0

;----------------------------------------------------------------------

selectdisk:
		lda	curdsk
		mov	c,a
		call	b_seldsk
		mov	a,h
		ora	l
		rz	
		mov	e,m
		inx	h
		mov	d,m
		inx	h
		shld	cdrmaxa
		inx	h
		inx	h
		shld	curtrka
		inx	h
		inx	h
		shld	curreca
		inx	h
		inx	h
		xchg	
		shld	tranv
		lxi	h,buffa
		mvi	c,8		; addlist
		call	move
		lhld	dpbaddr
		xchg	
		lxi	h,sectpt
		mvi	c,15		; dpblist
		call	move
		lhld	maxall
		mov	a,h
		lxi	h,single
		mvi	m,0FFh
		ora	a
		jz	retselect
		mvi	m,0

retselect:
		mvi	a,0FFh
		ora	a
		ret	

;----------------------------------------------------------------------

home:
		call	b_home
		xra	a
		lhld	curtrka
		mov	m,a
		inx	h
		mov	m,a
		lhld	curreca
		mov	m,a
		inx	h
		mov	m,a
		ret	

;----------------------------------------------------------------------

rdbuff:
		call	b_read
		jmp	diocomp

;----------------------------------------------------------------------

wrbuff:
		call	b_write
diocomp:
		ora	a
		rz	
		lxi	h,err_tbl
		jmp	goerr

;----------------------------------------------------------------------

seekdir:
		lhld	dcnt
		mvi	c,2		; dskshf
		call	hlrotr
		shld	arecord
		shld	drec
seek:		lxi	h,arecord
		mov	c,m
		inx	h
		mov	b,m
		lhld	curreca
		mov	e,m
		inx	h
		mov	d,m
		lhld	curtrka
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
seek0:		mov	a,c
		sub	e
		mov	a,b
		sbb	d
		jnc	seek1
		push	h
		lhld	sectpt
		mov	a,e
		sub	l
		mov	e,a
		mov	a,d
		sbb	h
		mov	d,a
		pop	h
		dcx	h
		jmp	seek0

seek1:		push	h
		lhld	sectpt
		dad	d
		jc	seek2
		mov	a,c
		sub	l
		mov	a,b
		sbb	h
		jc	seek2
		xchg	
		pop	h
		inx	h
		jmp	seek1

seek2:		pop	h
		push	b
		push	d
		push	h
		xchg	
		lhld	offset
		dad	d
		mov	b,h
		mov	c,l
		call	b_settrk
		pop	d
		lhld	curtrka
		mov	m,e
		inx	h
		mov	m,d
		pop	d
		lhld	curreca
		mov	m,e
		inx	h
		mov	m,d
		pop	b
		mov	a,c
		sub	e
		mov	c,a
		mov	a,b
		sbb	d
		mov	b,a
		lhld	tranv
		xchg	
		call	b_sectran
		mov	c,l
		mov	b,h
		jmp	b_setsec

;----------------------------------------------------------------------

dm_position:
		lxi	h,blkshf
		mov	c,m
		lda	vrecord
dmpos0:		ora	a
		rar	
		dcr	c
		jnz	dmpos0
		mov	b,a
		mvi	a,8
		sub	m
		mov	c,a
		lda	extval
dmpos1:		dcr	c
		jz	dmpos2
		ora	a
		ral	
		jmp	dmpos1

dmpos2:		add	b
		ret	

;----------------------------------------------------------------------

getdm:
		lhld	info
		lxi	d,10h		; dskmap
		dad	d
		dad	b
		lda	single
		ora	a
		jz	getdmd
		mov	l,m
		mvi	h,0
		ret	

;----------------------------------------------------------------------

getdmd:
		dad	b
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		ret	

;----------------------------------------------------------------------

index:
		call	dm_position
		mov	c,a
		mvi	b,0
		call	getdm
		shld	arecord
		ret	
;----------------------------------------------------------------------

allocated:
		lhld	arecord
		mov	a,l
		ora	h
		ret	

;----------------------------------------------------------------------

atran:
		lda	blkshf
		lhld	arecord
atran0:		dad	h
		dcr	a
		jnz	atran0
		shld	arecord1
		lda	blkmsk
		mov	c,a
		lda	vrecord
		ana	c
		ora	l
		mov	l,a
		shld	arecord
		ret	

;----------------------------------------------------------------------

getexta:
		lhld	info
		lxi	d,0Ch		; extnum
		dad	d
		ret	

;----------------------------------------------------------------------

getfcba:
		lhld	info
		lxi	d,0Fh		; reccnt
		dad	d
		xchg	
		lxi	h,11h		; nxtrec-reccnt
		dad	d
		ret	

;----------------------------------------------------------------------

getfcb:
		call	getfcba
		mov	a,m
		sta	vrecord
		xchg	
		mov	a,m
		sta	rcount
		call	getexta
		lda	extmsk
		ana	m
		sta	extval
		ret	

;----------------------------------------------------------------------

setfcb:
		call	getfcba
		lda	seqio
		cpi	2		; check ranfill
		jnz	setfcb1
		xra	a
setfcb1:	mov	c,a
		lda	vrecord
		add	c
		mov	m,a
		xchg	
		lda	rcount
		mov	m,a
		ret	

;----------------------------------------------------------------------

hlrotr:
		inr	c		; in case zero
hlrotr0:	dcr	c
		rz	
		mov	a,h
		ora	a
		rar	
		mov	h,a
		mov	a,l
		rar	
		mov	l,a
		jmp	hlrotr0

;----------------------------------------------------------------------

compute_cs:
		mvi	c,80h		; recsiz
		lhld	buffa
		xra	a
compcs0:	add	m
		inx	h
		dcr	c
		jnz	compcs0
		ret	

;----------------------------------------------------------------------

hlrotl:
		inr	c		; in case zero
hlrotl0:	dcr	c
		rz	
		dad	h
		jmp	hlrotl0

;----------------------------------------------------------------------

set_cdisk:
		push	b
		lda	curdsk
		mov	c,a
		lxi	h,1
		call	hlrotl
		pop	b
		mov	a,c
		ora	l
		mov	l,a
		mov	a,b
		ora	h
		mov	h,a
		ret	

;----------------------------------------------------------------------

nowrite:		; return true if dir checksum difference occurred
		lhld	rodsk
		lda	curdsk
		mov	c,a
		call	hlrotr
		mov	a,l
		ani	1
		ret	

;----------------------------------------------------------------------

dos_setro:
		lxi	h,rodsk
		mov	c,m
		inx	h
		mov	b,m
		call	set_cdisk
		shld	rodsk
		lhld	dirmax
		inx	h
		xchg	
		lhld	cdrmaxa
		mov	m,e
		inx	h
		mov	m,d
		ret	

;----------------------------------------------------------------------

check_rodir:
		call	getdptra
check_rofile:
		lxi	d,9		; rofile, offset to r/o bit
		dad	d
		mov	a,m
		ral	
		rnc	
		lxi	h,e_filero
		jmp	goerr

;----------------------------------------------------------------------

check_write:
		call	nowrite
		rz			; ok to write if not rodsk
		lxi	h,e_ro
		jmp	goerr

;----------------------------------------------------------------------

getdptra:
		lhld	buffa
		lda	dptr
addh:		add	l
		mov	l,a
		rnc	
		inr	h
		ret	

;----------------------------------------------------------------------

getmodnum:
		lhld	info
		lxi	d,0Eh		; modnum
		dad	d
		mov	a,m
		ret	

;----------------------------------------------------------------------

clrmodnum:
		call	getmodnum
		mvi	m,0
		ret	

;----------------------------------------------------------------------

setfwf:
		call	getmodnum
		ori	80h		; fwfmsk (file write flag mask)
		mov	m,a
		ret	

;----------------------------------------------------------------------

compcdr:
		lhld	dcnt
		xchg	
		lhld	cdrmaxa
		mov	a,e
		sub	m
		inx	h
		mov	a,d
		sbb	m
		ret	

;----------------------------------------------------------------------

setcdr:
		call	compcdr
		rc	
		inx	d
		mov	m,d
		dcx	h
		mov	m,e
		ret	

;----------------------------------------------------------------------

subdh:					; HL = DE - HL
		mov	a,e
		sub	l
		mov	l,a
		mov	a,d
		sbb	h
		mov	h,a
		ret	

;----------------------------------------------------------------------

newchecksum:
		mvi	c,0FFh		; true
checksum:	lhld	drec
		xchg	
		lhld	chksiz
		call	subdh		; HL = DE - HL
		rnc	
		push	b
		call	compute_cs
		lhld	checka
		xchg	
		lhld	drec
		dad	d
		pop	b
		inr	c
		jz	initial_cs
		cmp	m
		rz	
		call	compcdr
		rnc	
		call	dos_setro
		ret	

;----------------------------------------------------------------------

initial_cs:
		mov	m,a
		ret	

;----------------------------------------------------------------------

wrdir:
		call	newchecksum
		call	setdir
		mvi	c,1		; indicates a write directory operation
		call	wrbuff
		jmp	setdata

;----------------------------------------------------------------------

rd_dir:
		call	setdir
		call	rdbuff
setdata:
		lxi	h,dmaad
		jmp	setdma

;----------------------------------------------------------------------

setdir:
		lxi	h,buffa
setdma:
		mov	c,m
		inx	h
		mov	b,m
		jmp	b_setdma

;----------------------------------------------------------------------

dir_to_user:
		lhld	buffa
		xchg	
		lhld	dmaad
		mvi	c,80h		; recsiz
		jmp	move

;----------------------------------------------------------------------

end_of_dir:
		lxi	h,dcnt
		mov	a,m
		inx	h
		cmp	m
		rnz	
		inr	a
		ret	

;----------------------------------------------------------------------

set_end_dir:
		lxi	h,0FFFFh
		shld	dcnt
		ret	

;----------------------------------------------------------------------

read_dir:
		lhld	dirmax
		xchg	
		lhld	dcnt
		inx	h
		shld	dcnt
		call	subdh		; HL = DE - HL
		jnc	read_dir0
		jmp	set_end_dir

read_dir0:	lda	dcnt
		ani	3		; dskmsk
		mvi	b,5		; fcbshf
read_dir1:	add	a
		dcr	b
		jnz	read_dir1
		sta	dptr
		ora	a
		rnz	
		push	b
		call	seekdir
		call	rd_dir
		pop	b
		jmp	checksum

;----------------------------------------------------------------------

getallocbit:
		mov	a,c
		ani	111b
		inr	a
		mov	e,a
		mov	d,a
		mov	a,c
		rrc	
		rrc	
		rrc	
		ani	11111b
		mov	c,a
		mov	a,b
		add	a
		add	a
		add	a
		add	a
		add	a
		ora	c
		mov	c,a
		mov	a,b
		rrc	
		rrc	
		rrc	
		ani	11111b
		mov	b,a
		lhld	alloca
		dad	b
		mov	a,m
rotl:		rlc	
		dcr	e
		jnz	rotl
		ret	

;----------------------------------------------------------------------

setallocbit:
		push	d
		call	getallocbit
		ani	11111110b
		pop	b
		ora	c
rotr:		rrc	
		dcr	d
		jnz	rotr
		mov	m,a
		ret	

;----------------------------------------------------------------------

scandm:
		call	getdptra
		lxi	d,10h		; dskmap
		dad	d
		push	b
		mvi	c,11h		; fcblen-dskmap+1
scandm0:	pop	d
		dcr	c
		rz	
		push	d
		lda	single
		ora	a
		jz	scandm1
		push	b
		push	h
		mov	c,m
		mvi	b,0
		jmp	scandm2

scandm1:	dcr	c
		push	b
		mov	c,m
		inx	h
		mov	b,m
		push	h
scandm2:	mov	a,c
		ora	b
		jz	scanm3
		lhld	maxall
		mov	a,l
		sub	c
		mov	a,h
		sbb	b
		cnc	setallocbit
scanm3:		pop	h
		inx	h
		pop	b
		jmp	scandm0

;----------------------------------------------------------------------

initialize:
		lhld	maxall
		mvi	c,3		; maxall/8
		call	hlrotr
		inx	h
		mov	b,h
		mov	c,l
		lhld	alloca
initial0:	mvi	m,0
		inx	h
		dcx	b
		mov	a,b
		ora	c
		jnz	initial0
		lhld	dirblk
		xchg	
		lhld	alloca
		mov	m,e
		inx	h
		mov	m,d
		call	home
		lhld	cdrmaxa
		mvi	m,3
		inx	h
		mvi	m,0
		call	set_end_dir
initial2:	mvi	c,0FFh		; true
		call	read_dir
		call	end_of_dir
		rz	
		call	getdptra
		mvi	a,0E5h		; empty
		cmp	m
		jz	initial2	; go get another item
		lda	usrcode		; not empty, user code the same?
		cmp	m
		jnz	pdollar
		inx	h		; same user code, check for '$' submit
		mov	a,m
		sui	'$'
		jnz	pdollar
		dcr	a
		sta	lret
pdollar:	mvi	c,1
		call	scandm
		call	setcdr
		jmp	initial2

;----------------------------------------------------------------------

copy_dirloc:
		lda	dirloc
		jmp	sta_ret

;----------------------------------------------------------------------

search:
		mvi	a,0FFh
		sta	dirloc
		lxi	h,searchl
		mov	m,c
		lhld	info
		shld	searcha
		call	set_end_dir
		call	home
searchn:	mvi	c,0		; false
		call	read_dir
		call	end_of_dir
		jz	search_fin
		lhld	searcha
		xchg	
		ldax	d
		cpi	0E5h		; empty
		jz	searchnext
		push	d
		call	compcdr
		pop	d
		jnc	search_fin
searchnext:	call	getdptra
		lda	searchl
		mov	c,a
		mvi	b,0
searchloop:	mov	a,c
		ora	a
		jz	endsearch
		ldax	d
		cpi	'?'
		jz	searchok
		mov	a,b
		cpi	13		; ubytes
		jz	searchok
		cpi	12		; extnum
		ldax	d
		jz	searchext
		sub	m
		ani	7Fh
		jnz	searchn
		jmp	searchok

searchext:	push	b
		lda	extmsk
		cma	
		mov	b,a
		ana	m
		mov	c,a
		ldax	d
		ana	b
		sub	c
		pop	b
		jnz	searchn
searchok:	inx	d
		inx	h
		inr	b
		dcr	c
		jmp	searchloop

endsearch:	lda	dcnt
		ani	3
		sta	lret
		lxi	h,dirloc
		mov	a,m
		ral	
		rnc	
		xra	a
		mov	m,a
		ret	

search_fin:	call	set_end_dir
		mvi	a,0FFh
		jmp	sta_ret

;----------------------------------------------------------------------

delete:
		call	check_write
		mvi	c,12		; extnum
		call	search
delete0:	call	end_of_dir
		rz	
		call	check_rodir
		call	getdptra
		mvi	m,0E5h		; empty
		mvi	c,0
		call	scandm
		call	wrdir
		call	searchn
		jmp	delete0

;----------------------------------------------------------------------

get_block:
		mov	d,b
		mov	e,c
lefttst:	mov	a,c
		ora	b
		jz	righttst
		dcx	b
		push	d
		push	b
		call	getallocbit
		rar	
		jnc	retblock
		pop	b
		pop	d
righttst:	lhld	maxall
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	retblock0
		inx	d
		push	b
		push	d
		mov	b,d
		mov	c,e
		call	getallocbit
		rar	
		jnc	retblock
		pop	d
		pop	b
		jmp	lefttst

retblock:	ral	
		inr	a
		call	rotr
		pop	h
		pop	d
		ret	

retblock0:	mov	a,c
		ora	b
		jnz	lefttst
		lxi	h,0
		ret	

;----------------------------------------------------------------------

copy_fcb:
		mvi	c,0
		mvi	e,20h		; fcblen
copy_dir:
		push	d
		mvi	b,0
		lhld	info
		dad	b
		xchg	
		call	getdptra
		pop	b
		call	move
seek_copy:
		call	seekdir
		jmp	wrdir

;----------------------------------------------------------------------

rename:
		call	check_write
		mvi	c,0Ch		; extnum
		call	search
		lhld	info
		mov	a,m
		lxi	d,10h		; dskmap
		dad	d
		mov	m,a
rename0:	call	end_of_dir
		rz	
		call	check_rodir
		mvi	c,10h		; dskmap
		mvi	e,0Ch		; extnum
		call	copy_dir
		call	searchn
		jmp	rename0

;----------------------------------------------------------------------

indicators:
		mvi	c,0Ch		; extnum
		call	search
indic0:		call	end_of_dir
		rz	
		mvi	c,0
		mvi	e,0Ch		; extnum
		call	copy_dir
		call	searchn
		jmp	indic0

;----------------------------------------------------------------------

open:
		mvi	c,0Fh		; namlen
		call	search
		call	end_of_dir
		rz	
open_copy:
		call	getexta
		mov	a,m
		push	psw
		push	h
		call	getdptra
		xchg	
		lhld	info
		mvi	c,20h		; nxtrec
		push	d
		call	move
		call	setfwf
		pop	d
		lxi	h,0Ch		; extnum
		dad	d
		mov	c,m
		lxi	h,0Fh		; reccnt
		dad	d
		mov	b,m
		pop	h
		pop	psw
		mov	m,a
		mov	a,c
		cmp	m
		mov	a,b
		jz	open_rcnt
		mvi	a,0
		jc	open_rcnt
		mvi	a,128
open_rcnt:
		lhld	info
		lxi	d,0Fh		; reccnt
		dad	d
		mov	m,a
		ret	

;----------------------------------------------------------------------

mergezero:
		mov	a,m
		inx	h
		ora	m
		dcx	h
		rnz	
		ldax	d
		mov	m,a
		inx	d
		inx	h
		ldax	d
		mov	m,a
		dcx	d
		dcx	h
		ret	

;----------------------------------------------------------------------

close:
		xra	a
		sta	lret		; lret
		mov	h,a
		mov	l,a
		shld	dcnt
		call	nowrite
		rnz	
		call	getmodnum
		ani	80h		; fwfmsk
		rnz	
		mvi	c,0Fh		; namlen
		call	search		; locate file
		call	end_of_dir
		rz	
		lxi	b,10h		; dskmap
		call	getdptra
		dad	b
		xchg	
		lhld	info
		dad	b
		mvi	c,10h		; fcblen-dskmap
merge0:		lda	single
		ora	a
		jz	merged
		mov	a,m
		ora	a
		ldax	d
		jnz	fcbnzero
		mov	m,a
fcbnzero:	ora	a
		jnz	buffnzero
		mov	a,m
		stax	d
buffnzero:	cmp	m
		jnz	mergerr
		jmp	dmset

merged:		call	mergezero
		xchg	
		call	mergezero
		xchg	
		ldax	d
		cmp	m
		jnz	mergerr
		inx	d
		inx	h
		ldax	d
		cmp	m
		jnz	mergerr
		dcr	c
dmset:		inx	d
		inx	h
		dcr	c
		jnz	merge0
		lxi	b,0FFECh	; -(fcblen-extnum)
		dad	b
		xchg	
		dad	b
		ldax	d
		cmp	m
		jc	endmerge
		mov	m,a
		inx	d
		inx	h
		ldax	d
		mov	m,a
		lxi	b,2		; reccnt-ubytes
		dad	b
		xchg	
		dad	b
		mov	a,m
		stax	d
endmerge:	mvi	a,0FFh		; true
		sta	fcb_copied
		jmp	seek_copy

mergerr:	lxi	h,lret
		dcr	m
		ret	

;----------------------------------------------------------------------

make:
		call	check_write
		lhld	info
		push	h
		lxi	h,efcb
		shld	info
		mvi	c,1
		call	search
		call	end_of_dir
		pop	h
		shld	info
		rz	
		xchg	
		lxi	h,0Fh		; namlen
		dad	d
		mvi	c,11h		; fcblen-namlen
		xra	a
make0:		mov	m,a
		inx	h
		dcr	c
		jnz	make0
		lxi	h,0Dh		; ubytes
		dad	d
		mov	m,a
		call	setcdr
		call	copy_fcb
		jmp	setfwf

;----------------------------------------------------------------------

open_reel:
		xra	a
		sta	fcb_copied
		call	close
		call	end_of_dir
		rz	
		lhld	info
		lxi	b,0Ch		; extnum
		dad	b
		mov	a,m
		inr	a
		ani	1Fh		; maxext
		mov	m,a
		jz	open_mod
		mov	b,a
		lda	extmsk
		ana	b
		lxi	h,fcb_copied
		ana	m
		jz	open_reel0
		jmp	open_reel1

open_mod:	lxi	b,2		; modnum-extnum
		dad	b
		inr	m
		mov	a,m
		ani	0Fh		; maxmod
		jz	open_r_err
open_reel0:	mvi	c,0Fh		; namlen
		call	search
		call	end_of_dir
		jnz	open_reel1
		lda	rmf
		inr	a
		jz	open_r_err
		call	make
		call	end_of_dir
		jz	open_r_err
		jmp	open_reel2

open_reel1:	call	open_copy
open_reel2:	call	getfcb
		xra	a
		jmp	sta_ret

open_r_err:	call	setlret1
		jmp	setfwf

;----------------------------------------------------------------------

seqdiskread:
		mvi	a,1
		sta	seqio
diskread:
		mvi	a,0FFh		; true
		sta	rmf
		call	getfcb
		lda	vrecord
		lxi	h,rcount
		cmp	m
		jc	recordok
		cpi	128
		jnz	diskeof
		call	open_reel
		xra	a
		sta	vrecord
		lda	lret
		ora	a
		jnz	diskeof
recordok:	call	index
		call	allocated
		jz	diskeof
		call	atran
		call	seek
		call	rdbuff
		jmp	setfcb

;----------------------------------------------------------------------

diskeof:
		jmp	setlret1

;----------------------------------------------------------------------

seqdiskwrite:
		mvi	a,1
		sta	seqio

diskwrite:	mvi	a,0		; false
		sta	rmf
		call	check_write
		lhld	info
		call	check_rofile
		call	getfcb
		lda	vrecord
		cpi	128		; lstrec+1
		jnc	setlret1
		call	index
		call	allocated
		mvi	c,0
		jnz	diskwr1
		call	dm_position
		sta	dminx
		lxi	b,0
		ora	a
		jz	nopblock
		mov	c,a
		dcx	b
		call	getdm
		mov	b,h
		mov	c,l
nopblock:	call	get_block
		mov	a,l
		ora	h
		jnz	blockok
		mvi	a,2
		jmp	sta_ret

blockok:	shld	arecord
		xchg	
		lhld	info
		lxi	b,10h		; dskmap
		dad	b
		lda	single
		ora	a
		lda	dminx
		jz	allocwd
		call	addh
		mov	m,e
		jmp	diskwru

allocwd:	mov	c,a
		mvi	b,0
		dad	b
		dad	b
		mov	m,e
		inx	h
		mov	m,d
diskwru:	mvi	c,2
diskwr1:	lda	lret
		ora	a
		rnz	
		push	b
		call	atran
		lda	seqio
		dcr	a
		dcr	a
		jnz	diskwr11
		pop	b
		push	b
		mov	a,c
		dcr	a
		dcr	a
		jnz	diskwr11
		push	h
		lhld	buffa
		mov	d,a
fill0:		mov	m,a
		inx	h
		inr	d
		jp	fill0
		call	setdir
		lhld	arecord1
		mvi	c,2
fill1:		shld	arecord
		push	b
		call	seek
		pop	b
		call	wrbuff
		lhld	arecord
		mvi	c,0
		lda	blkmsk
		mov	b,a
		ana	l
		cmp	b
		inx	h
		jnz	fill1
		pop	h
		shld	arecord
		call	setdata
diskwr11:	call	seek
		pop	b
		push	b
		call	wrbuff
		pop	b
		lda	vrecord
		lxi	h,rcount
		cmp	m
		jc	diskwr2
		mov	m,a
		inr	m
		mvi	c,2
diskwr2:	dcr	c
		dcr	c
		jnz	noupdate
		push	psw
		call	getmodnum
		ani	7Fh		; not fwfmsk
		mov	m,a
		pop	psw
noupdate:	cpi	7Fh		; lstrec
		jnz	diskwr3
		lda	seqio
		cpi	1
		jnz	diskwr3
		call	setfcb
		call	open_reel
		lxi	h,lret
		mov	a,m
		ora	a
		jnz	nospace
		dcr	a
		sta	vrecord
nospace:	mvi	m,0
diskwr3:	jmp	setfcb

;----------------------------------------------------------------------

rseek:
		xra	a
		sta	seqio
rseek1:
		push	b
		lhld	info
		xchg	
		lxi	h,21h		; ranrec
		dad	d
		mov	a,m
		ani	7Fh
		push	psw
		mov	a,m
		ral	
		inx	h
		mov	a,m
		ral	
		ani	11111b
		mov	c,a
		mov	a,m
		rar	
		rar	
		rar	
		rar	
		ani	1111b
		mov	b,a
		pop	psw
		inx	h
		mov	l,m
		inr	l
		dcr	l
		mvi	l,6		; produce error 6, seek past physical end
		jnz	seekerr
		lxi	h,20h		; nxtrec
		dad	d
		mov	m,a
		lxi	h,0Ch		; extnum
		dad	d
		mov	a,c
		sub	m
		jnz	ranclose
		lxi	h,0Eh		; modnum
		dad	d
		mov	a,b
		sub	m
		ani	7Fh
		jz	seekok
ranclose:	push	b
		push	d
		call	close
		pop	d
		pop	b
		mvi	l,3		; cannot close error 3
		lda	lret
		inr	a
		jz	badseek
		lxi	h,0Ch		; extnum
		dad	d
		mov	m,c
		lxi	h,0Eh		; modnum
		dad	d
		mov	m,b
		call	open
		lda	lret
		inr	a
		jnz	seekok
		pop	b
		push	b
		mvi	l,4		; seek to unwritten extent 4
		inr	c
		jz	badseek
		call	make
		mvi	l,5		; cannot create new extent 5
		lda	lret
		inr	a
		jz	badseek
seekok:		pop	b
		xra	a
		jmp	sta_ret

badseek:	push	h
		call	getmodnum
		mvi	m,11000000b
		pop	h
seekerr:	pop	b
		mov	a,l
		sta	lret
		jmp	setfwf

;----------------------------------------------------------------------

randiskread:
		mvi	c,0FFh		; true = read operation
		call	rseek
		cz	diskread
		ret	

;----------------------------------------------------------------------

randiskwrite:
		mvi	c,0		; false = write operation
		call	rseek
		cz	diskwrite
		ret	

;----------------------------------------------------------------------

compute_rr:
		xchg	
		dad	d
		mov	c,m
		mvi	b,0
		lxi	h,0Ch		; extnum
		dad	d
		mov	a,m
		rrc	
		ani	80h
		add	c
		mov	c,a
		mvi	a,0
		adc	b
		mov	b,a
		mov	a,m
		rrc	
		ani	0Fh
		add	b
		mov	b,a
		lxi	h,0Eh		; modnum
		dad	d
		mov	a,m
		add	a
		add	a
		add	a
		add	a
		push	psw
		add	b
		mov	b,a
		push	psw
		pop	h
		mov	a,l
		pop	h
		ora	l
		ani	1
		ret	

;----------------------------------------------------------------------

getfilesize:
		mvi	c,0Ch		; extnum
		call	search
		lhld	info
		lxi	d,21h		; ranrec
		dad	d
		push	h
		mov	m,d
		inx	h
		mov	m,d
		inx	h
		mov	m,d
getsize:	call	end_of_dir
		jz	setsize
		call	getdptra
		lxi	d,0Fh		; reccnt
		call	compute_rr
		pop	h
		push	h
		mov	e,a
		mov	a,c
		sub	m
		inx	h
		mov	a,b
		sbb	m
		inx	h
		mov	a,e
		sbb	m
		jc	getnextsize
		mov	m,e
		dcx	h
		mov	m,b
		dcx	h
		mov	m,c
getnextsize:	call	searchn
		jmp	getsize

setsize:	pop	h
		ret	

;----------------------------------------------------------------------

dos_setrec:
		lhld	info
		lxi	d,20h		; nxtrec
		call	compute_rr
		lxi	h,21h		; ranrec
		dad	d
		mov	m,c
		inx	h
		mov	m,b
		inx	h
		mov	m,a
		ret	

;----------------------------------------------------------------------

select:
		lhld	dlog
		lda	curdsk
		mov	c,a
		call	hlrotr
		push	h
		xchg	
		call	selectdisk
		pop	h
		cz	sel_error
		mov	a,l
		rar	
		rc	
		lhld	dlog
		mov	c,l
		mov	b,h
		call	set_cdisk
		shld	dlog
		jmp	initialize

;----------------------------------------------------------------------

dos_seldsk:
		lda	linfo
		lxi	h,curdsk
		cmp	m
		rz	
		mov	m,a
		jmp	select

;----------------------------------------------------------------------

reselect:
		mvi	a,0FFh
		sta	resel
		lhld	info
		mov	a,m
		ani	11111b
		dcr	a
		sta	linfo
		cpi	30
		jnc	noselect
		lda	curdsk
		sta	olddsk
		mov	a,m
		sta	fcbdsk
		ani	11100000b
		mov	m,a
		call	dos_seldsk
noselect:	lda	usrcode
		lhld	info
		ora	m
		mov	m,a
		ret	

;----------------------------------------------------------------------

dos_vers:
		mvi	a,22h
		jmp	sta_ret

;----------------------------------------------------------------------

dos_dskrst:
		lxi	h,0
		shld	rodsk
		shld	dlog
		xra	a
		sta	curdsk
		lxi	h,80h		; tbuff
		shld	dmaad
		call	setdata
		jmp	select

;----------------------------------------------------------------------

dos_open:
		call	clrmodnum
		call	reselect
		jmp	open

;----------------------------------------------------------------------

dos_close:
		call	reselect
		jmp	close

;----------------------------------------------------------------------

dos_sfst:
		mvi	c,0
		xchg	
		mov	a,m
		cpi	'?'
		jz	qselect
		call	getexta
		mov	a,m
		cpi	'?'
		cnz	clrmodnum
		call	reselect
		mvi	c,0Fh		; namlen
qselect:	call	search
		jmp	dir_to_user

;----------------------------------------------------------------------

dos_snxt:
		lhld	searcha
		shld	info
		call	reselect
		call	searchn
		jmp	dir_to_user

;----------------------------------------------------------------------

dos_erase:
		call	reselect
		call	delete
		jmp	copy_dirloc

;----------------------------------------------------------------------

dos_read:
		call	reselect
		jmp	seqdiskread

;----------------------------------------------------------------------

dos_write:
		call	reselect
		jmp	seqdiskwrite

;----------------------------------------------------------------------

dos_makef:
		call	clrmodnum
		call	reselect
		jmp	make

;----------------------------------------------------------------------

dos_rename:
		call	reselect
		call	rename
		jmp	copy_dirloc

;----------------------------------------------------------------------

dos_getlog:
		lhld	dlog
		jmp	sthl_ret

;----------------------------------------------------------------------

dos_getdsk:
		lda	curdsk
		jmp	sta_ret

;----------------------------------------------------------------------

dos_setdma:
		xchg	
		shld	dmaad
		jmp	setdata

;----------------------------------------------------------------------

dos_getalloc:
		lhld	alloca
		jmp	sthl_ret

;----------------------------------------------------------------------

dos_getro:
		lhld	rodsk
		jmp	sthl_ret

;----------------------------------------------------------------------

dos_attrib:
		call	reselect
		call	indicators
		jmp	copy_dirloc

;----------------------------------------------------------------------

dos_getdpb:
		lhld	dpbaddr
sthl_ret:
		shld	lret
		ret	

;----------------------------------------------------------------------

dos_user:
		lda	linfo
		cpi	0FFh
		jnz	loc_7
		lda	usrcode
		jmp	sta_ret

loc_7:		ani	1Fh
		sta	usrcode
		ret

;----------------------------------------------------------------------

dos_rndrd:
		call	reselect
		jmp	randiskread

;----------------------------------------------------------------------

dos_rndwr:
		call	reselect
		jmp	randiskwrite

;----------------------------------------------------------------------

dos_filesz:
		call	reselect
		jmp	getfilesize

;----------------------------------------------------------------------

dos_drvrst:
		lhld	info
		mov	a,l
		cma	
		mov	e,a
		mov	a,h
		cma	
		lhld	dlog
		ana	h
		mov	d,a
		mov	a,l
		ana	e
		mov	e,a
		lhld	rodsk
		xchg	
		shld	dlog
		mov	a,l
		ana	e
		mov	l,a
		mov	a,h
		ana	d
		mov	h,a
		shld	rodsk
		ret	

;----------------------------------------------------------------------

goback:
		lda	resel
		ora	a
		jz	retmon
		lhld	info
		mvi	m,0
		lda	fcbdsk
		ora	a
		jz	retmon
		mov	m,a
		lda	olddsk
		sta	linfo
		call	dos_seldsk
retmon:		lhld	entsp
		sphl	
		lhld	lret
		mov	a,l
		mov	b,h
		ret	

;----------------------------------------------------------------------

dos_rndwrzf:
		call	reselect
		mvi	a,2
		sta	seqio
		mvi	c,0
		call	rseek1
		cz	diskwrite
		ret	

;----------------------------------------------------------------------

efcb:		db	0E5h
rodsk:		dw	0		; read only disk vector
dlog:		dw	0		; logged-in disks
dmaad:		dw	80h		; initial dma address
cdrmaxa:	dw	0		; pointer to cur dir max value
curtrka:	dw	0		; current track address
curreca:	dw	0		; current record address
buffa:		dw	0		; pointer to directory dma address
dpbaddr:	dw	0		; current disk parameter block address
checka:		dw	0		; current checksum vector address
alloca:		dw	0		; current allocation vector address
sectpt:		dw	0		; sectors per track
blkshf:		db	0		; block shift factor
blkmsk:		db	0		; block mask
extmsk:		db	0		; extent mask
maxall:		dw	0		; maximum allocation number
dirmax:		dw	0		; largest directory number
dirblk:		dw	0		; reserved allocation bits for directory
chksiz:		dw	0		; size of checksum vector
offset:		dw	0		; offset tracks at beginning
tranv:		dw	0		; address of translate vector
fcb_copied:	db	0		; set true if copy_fcb called
rmf:		db	0		; read mode flag for open_reel
dirloc:		db	0		; directory flag in rename, etc.
seqio:		db	0		; 1 if sequential i/o
linfo:		db	0		; linfo = low(info)
dminx:		db	0		; local for diskwrite
searchl:	db	0		; search length
searcha:	dw	0		; search address
		db	0
		db	0  
single:		db	0		; set true if single byte alloc map
resel:		db	0		; reselection flag
olddsk:		db	0		; disk on entry to bdos
fcbdsk:		db	0		; disk named in fcb
rcount:		db	0		; record count in current fcb
extval:		db	0		; extent number and extmsk
vrecord:	db	0		; current virtual record
		db	0  
arecord:	dw	0		; current actual record
arecord1:	dw	0		; current actual block# * blkmsk
dptr:		db	0		; directory pointer 0,1,2,3
dcnt:		dw	0		; directory counter 0,1,...,dirmax
drec:		dw	0		; directory record 0,1,...,dirmax/4

;		ds	58

;----------------------------------------------------------------------

		org	1000h

; The ISIS subsystem (1000H - 30FFH) starts here...
;
; The command line processor is based on CP/M CCP

isx_start:
		jmp	isx_main

;----------------------------------------------------------------------
;
; Utility procedures

conin:
		mvi	c,1		; console input
		jmp	bdos

;----------------------------------------------------------------------

printchar:
		mov	e,a
		mvi	c,2		; console output
		jmp	bdos

;----------------------------------------------------------------------

printbc:				; print char saving BC registers
		push	b
		call	printchar
		pop	b
		ret	

;----------------------------------------------------------------------

put_spc:
		mvi	a,' '
		jmp	printbc		; print char saving BC registers

;----------------------------------------------------------------------

crlf:
		mvi	a,0Dh
		call	printbc		; print char saving BC registers
		mvi	a,0Ah
		jmp	printbc		; print char saving BC registers

;----------------------------------------------------------------------

ln_print:
		push	b
		call	crlf
		pop	d
putstr:					; print string
		mvi	c,9
		jmp	bdos

;----------------------------------------------------------------------

dsk_reset:
		mvi	c,0Dh		; reset disk
		call	bdos		; returns 0FFh if there is a file
					; whose name begins with '$' in A:
		push	psw
		mvi	c,1Eh		; ??? set file attrib
		lxi	d,80h		; this is probably a bug,
					; I would expect 1A (set dma) here.
		call	bdos
		pop	psw
		ret	

;----------------------------------------------------------------------

seldsk:
		mov	e,a
		mvi	c,0Eh		; select disk
		jmp	bdos

;----------------------------------------------------------------------

openf:
		mvi	c,0Fh		; open file
		call	bdos
		sta	i_dcnt		; bdos return code
		inr	a
		ret	

;----------------------------------------------------------------------

openc:					; open comfcb
		xra	a
		sta	comrec		; comfcb rc byte
		lxi	d,comfcb
		jmp	openf

;----------------------------------------------------------------------

closef:
		mvi	c,10h		; close file
		call	bdos
		sta	i_dcnt		; bdos return code
		inr	a
		ret	

;----------------------------------------------------------------------

srchfst:
		mvi	c,11h		; search for first
		call	bdos
		sta	i_dcnt		; bdos return code
		inr	a
		ret	

;----------------------------------------------------------------------

srchnxt:
		mvi	c,12h		; search for next
		call	bdos
		sta	i_dcnt		; bdos return code
		inr	a
		ret	

;----------------------------------------------------------------------

srchcom:
		lxi	d,comfcb
		jmp	srchfst

;----------------------------------------------------------------------

erasef:
		mvi	c,13h		; delete file
		jmp	bdos

;----------------------------------------------------------------------

readf:
		mvi	c,14h		; read
		call	bdos
		ora	a
		ret	

;----------------------------------------------------------------------

readc:					; read the comfcb file
		lxi	d,comfcb
		jmp	readf

;----------------------------------------------------------------------

writef:
		mvi	c,15h		; write
		call	bdos
		ora	a
		ret	

;----------------------------------------------------------------------

makef:
		mvi	c,16h		; make file
		call	bdos
		sta	i_dcnt		; bdos return code
		ret	

;----------------------------------------------------------------------

irename:
		mvi	c,17h		; rename file
		jmp	bdos

;----------------------------------------------------------------------

rndrd:
		mvi	c,21h		; read random
		jmp	bdos

;----------------------------------------------------------------------

fsize:
		mvi	c,23h		; compute file size
		jmp	bdos

;----------------------------------------------------------------------

adec:
		push	psw
		mvi	c,100
		call	sbcnt
		push	b
		call	print_digit
		pop	b
		pop	psw
		sub	d
		push	psw
		mvi	c,10
		call	sbcnt
		push	b
		call	print_digit
		pop	b
		pop	psw
		sub	d
		call	print_digit
		ret	

;----------------------------------------------------------------------

sbcnt:
		mvi	b,0FFh
sbc1:		inr	b
		sub	c
		jnc	sbc1
		mov	a,b
		ret	

;----------------------------------------------------------------------

print_digit:
		push	b
		adi	'0'
		call	printchar
		pop	b
		inr	b
		xra	a
prd2:		dcr	b
		jz	prd1
		add	c
		jmp	prd2

prd1:		mov	d,a
		ret	

;----------------------------------------------------------------------

hex_nibble:
		sui	10
		jnc	hn1
		adi	'9'+1
		jmp	printchar
hn1:
		adi	'A'
		jmp	printchar

;----------------------------------------------------------------------

ahex:
		push	psw
		rrc	
		rrc	
		rrc	
		rrc	
		ani	0Fh
		call	hex_nibble
		pop	psw
		ani	0Fh
		jmp	hex_nibble

;----------------------------------------------------------------------

; Trace table, used by the tr_dump routine to figure out function
; names and arguments, etc.

tr_tbl:		dw	tr_open
		dw	tr_close
		dw	tr_delete
		dw	tr_read
		dw	tr_write
		dw	tr_seek
		dw	tr_load
		dw	tr_rename
		dw	tr_console
		dw	tr_exit
		dw	tr_attrib
		dw	tr_rescan
		dw	tr_error
		dw	tr_whocon
		dw	tr_spath

tr_open:	dw	fn_open
aOpen:		db	'OPEN    '	; ISIS function name
		db	5		; number of arguments
		db	80h,3,2,2,80h	; type of arguments:
					;  01h - file number (file descriptor)
					;  02h - word value
					;  03h - pointer to ASCII string
					;  04h - word? buffer?
					;  80h - pointer to word or buffer
					; Hi-bit set means pointer (e.g.
					; 82h is pointer to word)
					; Note that 80h always ends the list

tr_close:	dw	fn_close
aClose:		db	'CLOSE   '
		db	2
		db	1,80h

tr_delete:	dw	fn_delete
aDelete:	db	'DELETE  '
		db	2
		db	3,80h

tr_read:	dw	fn_read
aRead:		db	'READ    '
		db	5
		db	1,80h,2,80h,80h

tr_write:	dw	fn_write
aWrite:		db	'WRITE   '
		db	4
		db	1,4,2,80h

tr_seek:	dw	fn_seek
aSeek:		db	'SEEK    '
		db	5
		db	1,2,82h,82h,80h

tr_load:	dw	fn_load
aLoad:		db	'LOAD    '
		db	5
		db	3,2,2,80h,80h

tr_rename:	dw	fn_rename
aRename:	db	'RENAME  '
		db	3
		db	3,3,80h

tr_console:	dw	fn_console
aConsole:	db	'CONSOLE '
		db	3
		db	3,3,80h

tr_exit:	dw	fn_exit
aExit:		db	'EXIT    '
		db	1
		db	80h

tr_attrib:	dw	fn_attrib
aAttrib:	db	'ATTRIB  '
		db	4
		db	3,2,2,80h

tr_rescan:	dw	fn_rescan
aRescan:	db	'RESCAN  '
		db	2
		db	1,80h

tr_error:	dw	fn_error
aError:		db	'ERROR   '
		db	2
		db	2,80h

tr_whocon:	dw	fn_whocon
aWhocon:	db	'WHOCON  '
		db	3
		db	1,80h,80h

tr_spath:	dw	fn_spath
aSpath:		db	'SPATH   '
		db	3
		db	3,80h,80h

;----------------------------------------------------------------------

hlhex:
		push	h
		mov	a,h
		call	ahex
		pop	h
		mov	a,l
		jmp	ahex

;----------------------------------------------------------------------

type_spc:
		mvi	a,' '
		jmp	printchar

;----------------------------------------------------------------------

type_arrow:
		mvi	a,'-'
		call	printchar
		mvi	a,'>'
		jmp	printchar

;----------------------------------------------------------------------

stype_a:
		push	h
		push	b
		call	printchar
		pop	b
		pop	h
		ret	

;----------------------------------------------------------------------

sahex:
		push	h
		call	ahex
		pop	h
		ret	

;----------------------------------------------------------------------

type_spch:				; type space, saving HL
		push	h
		call	type_spc
		pop	h
		ret	

;----------------------------------------------------------------------

dump_ascii:				; display ascii char, or '.' if
					; not printable
		cpi	7Fh
		jnc	dmp_dot
		cpi	' '
		jnc	dmp_ok
dmp_dot:	mvi	a,'.'
dmp_ok:		jmp	stype_a

;----------------------------------------------------------------------

end_dmp?:
		xchg	
		lhld	dmp_to
		mov	a,l
		sub	e
		mov	a,h
		sbb	d
		xchg	
		ret	

;----------------------------------------------------------------------

dump_mem:				; dump memory contents from dmp_from
					; address to dmp_to
		lhld	dmp_from
		call	hlhex		; display start address
		mvi	a,'-'
		call	printchar
		lhld	dmp_to
		call	hlhex		; display end address
		call	crlf
		lhld	dmp_from
		xra	a
		sub	l
		mov	l,a
		mvi	a,0
		sbb	h
		mov	h,a
		shld	word_15		; word_15 = -dmp_from
dmp_16:		call	crlf
		call	break_key
		rnz	
		lhld	dmp_from
		shld	word_17
		push	h
		xchg	
		lhld	word_15
		dad	d
		call	hlhex		; display address as relative offset
		pop	h
dmp_h:		call	type_spch
		mov	a,m
		call	sahex
		inx	h
		call	end_dmp?
		jc	dmp_a
		xchg	
		lhld	word_15
		dad	d
		xchg	
		mov	a,e
		ani	0Fh
		jnz	dmp_h
dmp_a:		shld	dmp_from
		call	type_spc
		lhld	word_17
dmp_a1:		mov	a,m
		call	dump_ascii
		inx	h
		xchg	
		lhld	dmp_from
		xchg	
		mov	a,e
		sub	l
		jnz	dmp_a1
		mov	a,d
		sbb	h
		jnz	dmp_a1
		lhld	dmp_from
		call	end_dmp?
		rc	
		jmp	dmp_16

;----------------------------------------------------------------------

outnamf:				; type D and get word @ HL+E
		push	d
		mvi	a,' '
		call	stype_a
		pop	d
		mov	a,d
		mvi	d,0
		push	h
		dad	d
		mov	e,m		; DE = word from (HL+E)
		inx	h
		mov	d,m
		pop	h
		push	d
		call	stype_a
		pop	d
		ret	

;----------------------------------------------------------------------

out_byte:
		call	outnamf		; type D and get word @ HL+E
		mov	a,e
		call	sahex
		ret	

;----------------------------------------------------------------------

out_word:
		call	outnamf		; type D and get word @ HL+E
		xchg	
		push	d
		call	hlhex
		pop	h
		ret	

;----------------------------------------------------------------------

tr_dump:
		lxi	h,0
		shld	dmp_from
		call	crlf
		lda	pgm_c
		call	adec		; output C (function code)
		mvi	a,':'
		call	printchar
		call	type_spc
		lxi	h,pgm_c		; function code
		mov	e,m		;  into DE
		mvi	d,0
		lxi	h,tr_tbl	; offset into trace table
		dad	d
		dad	d
		mov	e,m		; fetch pointer
		inx	h
		mov	d,m
		xchg	
		mov	e,m		; get handling routine address
		inx	h
		mov	d,m
		inx	h
		push	h
		xchg	
		call	hlhex		; output DOS routine address
		call	type_spc
		mvi	c,8
		pop	h
tr_outname:	mov	a,m
		inx	h
		push	h
		push	b
		call	printchar	; output function name
		pop	b
		pop	h
		dcr	c
		jnz	tr_outname
		push	h
		call	type_spc
		lhld	pgm_de
		call	hlhex		; output DE (argument) value
		call	type_spc
		mvi	a,'('
		call	printchar
		lhld	pgm_sp
		mov	e,m
		inx	h
		mov	d,m
		lxi	h,-3
		dad	d
		call	hlhex		; output program PC (calling addr)
		mvi	a,')'
		call	printchar
		call	crlf
		pop	h
		mov	c,m		; C - number of arguments
		inx	h
		xchg	
		mvi	b,0
		lhld	pgm_de
loc_21:		push	b
		push	d
		push	h
		push	b
		call	type_spc
		call	type_spc
		call	type_spc
		pop	psw		; A - previous value of B
		call	adec		; output argument number
		mvi	a,':'
		call	printchar
		pop	h
		mov	e,m
		inx	h
		mov	d,m		; DE - word pointed by pgm_de
		inx	h
		push	h
		push	d
		xchg	
		call	hlhex		; print argument value
		pop	d
		pop	h
		xthl	
		mov	a,m		; get argument type
		inx	h
		push	h
		cpi	2
		jz	tr_02
		mov	b,a
		ani	80h
		mov	a,b
		jz	tr_0x
		push	psw
		push	d
		call	type_arrow	; type "->"
		pop	d
		pop	psw
		ani	7Fh
		jnz	loc_22
		lxi	h,byte_23
		mov	c,m
		inr	m
		lxi	h,word_24
		mvi	b,0
		dad	b
		dad	b
		mov	m,e
		inx	h
		mov	m,d
		jmp	tr_02

loc_22:		cpi	2
		jnz	tr_0x
		xchg	
		mov	e,m
		inx	h
		mov	h,m
		mov	l,e
		call	hlhex
		jmp	tr_02

tr_0x:		cpi	1
		jnz	loc_25
		lxi	h,fd_tab
		mvi	d,0		; E - fileno
		dad	d
		mov	a,m
		push	psw
		call	type_spc
		pop	psw
		push	psw
		call	ahex		; show fd flags byte
		call	type_spc
		pop	psw
		ral			; 'in use' bit set?
		jnc	tr_02		; jump if not
		rar	
		rar	
		rar	
		ani	1Fh
		lxi	h,f_dscrptrs
		lxi	d,28h		; 40 - file descriptor length
tr_fnddescr:	ora	a
		jz	tr_found
		dad	d
		dcr	a
		jmp	tr_fnddescr

tr_found:	shld	dmp_from
		call	type_spch	; type space, saving HL
		mov	a,m
		ora	a
		jz	tr_nodisk
		dcr	a
		adi	'A'		; output disk name
		call	stype_a
		mvi	a,':'
		call	stype_a
tr_nodisk:	mvi	c,11		; filename length (8+3)
tr_typefname:	inx	h
		mov	a,c
		cpi	3
		jnz	tr_nofsep
		mvi	a,'.'		; type ext separator
		call	stype_a
tr_nofsep:	mov	a,m
		cpi	' '
		cnz	stype_a
		dcr	c
		jnz	tr_typefname
		lhld	dmp_from
		lxi	d,450Ch		; D = 'E', E = byte offset
		call	out_byte	; fcb ex
		lxi	d,550Dh		; 'U'
		call	out_byte	; fcb s1
		lxi	d,520Fh		; 'R'
		call	out_byte	; fcb rc
		lxi	d,4320h		; 'C'
		call	out_byte	; fcb cr
		lxi	d,4C21h		; 'L'
		call	out_byte	; fcb r0
		lxi	d,4023h		; '@'
		call	out_word
		lxi	d,4225h		; 'B'
		call	out_word	; number of records
		lxi	d,2C27h		; ','
		call	out_byte	; last record byte count
		jmp	tr_02

loc_25:		cpi	3
		jnz	tr_02
		xchg	
tr_03:		mov	a,m
		cpi	21h
		jc	tr_02
		push	h
		call	printchar
		pop	h
		inx	h
		jmp	tr_03

tr_02:		call	crlf
		pop	d
		pop	h
		pop	b
		inr	b
		dcr	c
		jnz	loc_21
		lda	tr_level
		ani	4
		jz	locret_26
		lhld	dmp_from
		mov	a,l
		ora	h
		jz	locret_26
		lxi	d,23h
		dad	d
		mov	e,m
		inx	h
		mov	d,m
		lxi	h,7Fh
		dad	d
		shld	dmp_to
		xchg	
		shld	dmp_from
		call	dump_mem
		call	crlf
locret_26:	ret	

;----------------------------------------------------------------------

sub_27:
		lda	byte_23
		ora	a
		rz	
		lxi	h,byte_23
		mov	c,m
		mvi	m,0
		lxi	h,word_24
loc_28:		mov	e,m
		inx	h
		mov	d,m
		inx	h
		push	b
		push	h
		push	d
		call	type_spc
		call	type_spc
		call	type_spc
		pop	h
		push	h
		call	hlhex
		mvi	a,'='
		call	printchar
		pop	h
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		call	hlhex
		pop	h
		pop	b
		dcr	c
		jnz	loc_28
		call	crlf
		ret

;----------------------------------------------------------------------

get_trlvl:
		lxi	b,tr_lvl	; "trace level: "
		call	ln_print
		xra	a
		sta	tr_level
loc_29:		call	conin
		cpi	'1'
		jnz	loc_30
		lxi	h,tr_level
		mov	a,m
		add	a		; shift existing bits to the left
		inr	a		; and add a '1' bit to the right
		mov	m,a
		jmp	loc_29

loc_30:		cpi	'#'
		jnz	loc_31
		xthl	
		inx	h
		xthl	
		rst	7
		ret	

;----------------------------------------------------------------------

		ret	

;----------------------------------------------------------------------

loc_31:		cpi	0Dh		; cr
		jnz	get_trlvl	; get trace level
		call	crlf
		ret	

tr_lvl:		db	'TRACE LEVEL: $'

;----------------------------------------------------------------------

setup_40h:
		lxi	h,vec_40
		lxi	d,save_40
		mvi	c,3
sav40:		mov	a,m
		stax	d
		inx	d
		inx	h
		dcr	c
		jnz	sav40
		mvi	a,0C3h		; jmp
		sta	vec_40		; 0040H
		lxi	h,idos_ept	; isis dos entry point
		shld	vec_40+1	; 0041H
		ret	

;----------------------------------------------------------------------

res_40h:
		lxi	h,vec_40	; 0040H
		lxi	d,save_40
		mvi	c,3
res40:		ldax	d
		mov	m,a
		inx	d
		inx	h
		dcr	c
		jnz	res40
		ret	

;----------------------------------------------------------------------

toupper:
		cpi	'a'
		rc	
		cpi	'{'
		rnc	
		ani	5Fh
		ret	

;----------------------------------------------------------------------

readcom:
		lda	submit		; submit file present?
		ora	a
		jz	nosub		; no, read command from console
		lda	cur_disk
		ora	a
		mvi	a,0
		cnz	seldsk
		lda	subrc
		dcr	a
		sta	subcr
		lxi	d,subfcb
		call	readf
		jnz	nosub
		lxi	d,buflen
		lxi	h,cpm_bfr	; 0080H
		mvi	b,128
		call	copy
		lxi	h,subrc
		dcr	m		; one less record
		lxi	h,submod
		mvi	m,0		; clear fwflag
		lxi	d,subfcb
		call	closef
		jz	nosub
		lda	cur_disk
		ora	a
		cnz	seldsk
		mvi	c,9		; print string
		lxi	d,combuf
		call	bdos
		call	break_key
		jz	noread
		call	del_sub		; remove $$$.SUB file
		jmp	cli

nosub:		call	del_sub		; remove $$$.SUB file
		mvi	c,0Ah		; read console buffer
		lxi	d,rbuff
		call	bdos
noread:		lxi	h,buflen
		mov	b,m
readcom0:	inx	h
		mov	a,b
		ora	a
		jz	readcom1
		mov	a,m
		call	toupper
		mov	m,a
		dcr	b
		jmp	readcom0

readcom1:	mov	m,a
		lxi	h,combuf
		shld	comaddr
		ret	

;----------------------------------------------------------------------

break_key:
		mvi	c,0Bh		; get console status
		call	bdos
		ora	a
		rz	
		call	conin
		ora	a
		ret	

;----------------------------------------------------------------------

getdsk:
		mvi	c,19h		; get current disk
		jmp	bdos

;----------------------------------------------------------------------

loc_32:					; not used...
		ldax	d
		mov	m,a
		inx	d
		inx	h
		dcr	c
		jnz	loc_32
		ret	

;----------------------------------------------------------------------

isetdma:
		mvi	c,1Ah		; set dma
		jmp	bdos

;----------------------------------------------------------------------

dma80:
		lxi	d,cpm_bfr	; 0080h
		call	isetdma
		ret	

;----------------------------------------------------------------------

del_sub:
		lxi	h,submit	; remove $$$.SUB file
		mov	a,m
		ora	a
		rz	
		mvi	m,0
		xra	a
		call	seldsk		; select disk A:
		lxi	d,subfcb
		call	erasef		; erase $$$.SUB file
		lda	cur_disk
		jmp	seldsk

;----------------------------------------------------------------------

comerr:
		call	crlf
		lhld	staddr
cmd_e1:		mov	a,m
		cpi	' '
		jz	cmd_e2
		ora	a
		jz	cmd_e2
		push	h
		call	printchar
		pop	h
		inx	h
		jmp	cmd_e1

cmd_e2:		mvi	a,'?'
		call	printchar
		call	crlf
		call	del_sub		; delete $$$.SUB file
		jmp	cli

;----------------------------------------------------------------------

loc_33:
		ldax	d
loc_34:		cpi	'*'
		jz	loc_35
		cpi	'?'
		jz	loc_35
		push	psw
		sui	'A'
		cpi	1Ah
		jc	loc_36
		pop	psw
		push	psw
		sui	'0'
		cpi	0Ah
		jc	loc_36
		pop	psw
		cmp	a
		ret	

loc_36:		pop	psw
loc_35:		ora	a
		ret	

;----------------------------------------------------------------------

skip_spc:
		ldax	d
		ora	a
		rz	
		cpi	' '
		rnz	
		inx	d
		jmp	skip_spc

;----------------------------------------------------------------------

add_hla:
		add	l
		mov	l,a
		rnc	
		inr	h
		ret	

;----------------------------------------------------------------------

loc_37:
		push	psw
		lhld	comaddr
		xchg	
		call	skip_spc
		lxi	h,3
		dad	d
		mov	a,m
		cpi	':'		; device or disk specified?
		pop	b
		jnz	no_dev
		mvi	c,0
		ldax	d
		cpi	':'		; first char is a isis disk/dev delimiter?
		jnz	cpm_dev		; no -> probably is a CP/M device
		push	d
		inx	d
		ldax	d
		cpi	'F'		; isis disk name?
		inx	d
		ldax	d
		pop	d
		jnz	isis_dev	; no -> probably a isis dev
		sui	'0'
		cpi	6		; :F0: ... :F5: ?
		jc	no_dev		; yes -> not a device.
isis_dev:	mvi	c,4
cpm_dev:	mov	a,b
		dcr	a
		add	a
		add	c
		lxi	h,dev_tbl
		call	add_hla
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		mvi	c,0
loc_39:		mov	a,m
		ora	a
		jz	bad_dev
		mvi	b,3
		inr	c
loc_40:		ldax	d
		cmp	m
		jnz	loc_41
		inx	d
		inx	h
		dcr	b
		jnz	loc_40
		mov	a,c		; valid device name found
		ora	a
		ret	

loc_41:		ldax	d
		cpi	':'
		jz	loc_42
		call	loc_34
		jz	no_dev
loc_42:		inx	d
		inx	h
		dcr	b
		jnz	loc_41
		dcx	d
		dcx	d
		dcx	d
		jmp	loc_39

bad_dev:	mvi	a,0FFh		; invalid ISIS or CP/M device name
		ora	a
		ret	

no_dev:		xra	a
		ret	

;----------------------------------------------------------------------

dev_tbl:	dw	cpm_idev
		dw	cpm_odev
		dw	isx_idev
		dw	isx_odev

cpm_idev:	db	'CONRDRTTYCRTUC1PTRUR1UR2EMP',0
cpm_odev:	db	'CONLSTPUNTTYCRTUC1LPTUL1PTPUP1UP2EMP',0
isx_idev:	db	':CI:RD:TI:VI:I1:HR:R1:R2:BB',0
isx_odev:	db	':CO:LS:PN:TO:VO:O1:LP:L1:HP:P1:P2:BB',0

byte_43:	db	17h, 0Ch, 0Ch,  8,  0Ah, 0Dh, 0Eh
		db	0Fh, 16h, 18h, 14h, 10h,  7,   9
		db	0Bh, 14h, 15h, 11h, 12h, 13h, 16h

;----------------------------------------------------------------------

fillfcb0:
		mvi	a,0
fillfcb:	lxi	h,comfcb
		call	add_hla
		push	h
		push	h
		xra	a
		sta	sdisk
		lhld	comaddr
		xchg	
		call	skip_spc
		xchg	
		shld	staddr
		xchg	
		pop	h
		ldax	d
		ora	a
		jz	setcur0
		cpi	':'		; check for isis disk specification :Fn:
		jnz	loc_44
		inx	d
		ldax	d
		cpi	'F'
		jnz	setcur
		inx	d
		ldax	d
		sui	'0'
		cpi	6
		jnc	loc_45
		inr	a
		mov	b,a		; save possible disk code in B
		inx	d
		ldax	d
		cpi	':'
		jz	setdsk
		dcx	d
loc_45:		dcx	d
		jmp	setcur

loc_44:		sbi	'A'-1		; check for CP/M disk specification d:
		mov	b,a		; save possible disk code in B
		inx	d
		ldax	d
		cpi	':'
		jz	setdsk
setcur:		dcx	d
setcur0:	lda	cur_disk
		mov	m,a
		jmp	setname

setdsk:		mov	a,b		; disk code
		sta	sdisk
		mov	m,b		; save it in fcb too
		inx	d
setname:	mvi	b,8
setnam0:	call	loc_33		; is a legal filespec character?
		jz	padname
		inx	h
		cpi	'*'		; '*' ?
		jnz	setnam1
		mvi	m,'?'		; yes, fill the remaining with '?'
		jmp	setnam2

setnam1:	mov	m,a
		inx	d
setnam2:	dcr	b
		jnz	setnam0
trname:		call	loc_33
		jz	settype
		inx	d
		jmp	trname

padname:	inx	h
		mvi	m,' '
		dcr	b
		jnz	padname
settype:	mvi	b,3
		cpi	'.'
		jnz	padtype
		inx	d
settyp0:	call	loc_33
		jz	padtype
		inx	h
		cpi	'*'
		jnz	settyp1
		mvi	m,'?'
		jmp	settyp2

settyp1:	mov	m,a
		inx	d
settyp2:	dcr	b
		jnz	settyp0
trtype:		call	loc_33
		jz	efill
		inx	d
		jmp	trtype

padtype:	inx	h
		mvi	m,' '
		dcr	b
		jnz	padtype
efill:		mvi	b,3
efill0:		inx	h
		mvi	m,0
		dcr	b
		jnz	efill0
		xchg	
		shld	comaddr
		pop	h
		lxi	b,11
scnq:		inx	h
		mov	a,m
		cpi	'?'
		jnz	scnq0
		inr	b
scnq0:		dcr	c
		jnz	scnq
		mov	a,b
		ora	a
		ret	

;----------------------------------------------------------------------

intcmd_tbl:	db	'DBUG'
		db	'DIR '
		db	'ERA '
		db	'TYPE'
		db	'REN '

;----------------------------------------------------------------------

intrinsic:
		lxi	h,intcmd_tbl	; search for a cli internal command
		mvi	c,0
intrin0:	mov	a,c
		cpi	5
		rnc	
		lxi	d,comfcb+1	; cmd fcb file name
		mvi	b,4
intrin1:	ldax	d
		cmp	m		; match?
		jnz	intrin2
		inx	d
		inx	h
		dcr	b
		jnz	intrin1
		ldax	d
		cpi	' '
		jnz	intrin3
		mov	a,c		; return command code in C
		ret	

intrin2:	inx	h
		dcr	b
		jnz	intrin2
intrin3:	inr	c
		jmp	intrin0

;----------------------------------------------------------------------

loc_46:
		ora	a
		jnz	loc_47
		lxi	d,subfcb	; $$$.SUB fcb
		call	openf
		jz	loc_47
		mvi	a,0FFh
		jmp	loc_48

loc_47:		xra	a
loc_48:		sta	submit
		ret	

;----------------------------------------------------------------------

cmp_hlde:				; CY if HL > DE
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		ret	

;----------------------------------------------------------------------

ld_getbyte:
		lxi	h,bptr
		inr	m
		jnz	loc_49
		mvi	m,80h
		push	b
		push	d
		push	h
		lxi	d,comfcb
		call	readf
		jnz	ld_exit
		pop	h
		pop	d
		pop	b
loc_49:		lhld	bptr
		mov	a,c
		add	m
		mov	c,a		; C - checksum?
		dcx	d
		mov	a,d
		ora	e
		mov	a,m
		ret	

;----------------------------------------------------------------------

ld_getword:
		call	ld_getbyte
		jz	ld_exit
		push	psw
		call	ld_getbyte
		jz	ld_exit
		mov	h,a
		pop	psw
		mov	l,a
		ret	

;----------------------------------------------------------------------

load:
		call	dma80		; set dma to default 0080H
		lxi	h,0FFh
		shld	bptr
		lxi	h,0
		shld	word_50
		shld	word_4
		shld	word_5
		dad	sp
		shld	save_sp
loc_51:		mvi	c,0
		call	ld_getbyte
		push	psw
		call	ld_getword
		xchg	
		pop	psw
		cpi	2
		jz	loc_52
		cpi	4
		jnz	loc_53
		call	ld_getbyte
		cpi	1
		jnz	loc_52
		call	ld_getbyte
		call	ld_getword
		shld	word_4
		jmp	loc_52

loc_53:		cpi	18h
		jz	loc_52
		cpi	16h
		jz	loc_52
		cpi	6
		jnz	loc_54
		call	ld_getbyte
		ora	a
		jnz	ld_exit
		call	ld_getword
		push	d
		xchg	
		lhld	word_55
		dad	d
		pop	d
		push	d
		push	h
		dad	d
		xchg	
		lhld	bdos+1		; mem top
		call	cmp_hlde	; CY if HL > DE
		jnc	ld_exit
		lhld	word_5
		call	cmp_hlde	; CY if HL > DE
		jc	loc_56
		xchg	
		shld	word_5
		xchg	
loc_56:		lxi	h,loc_57	; 3100h
		pop	d
		push	d
		call	cmp_hlde	; CY if HL > DE
		jc	ld_exit
		lhld	word_50
		mov	a,h
		ora	l
		jz	loc_58
		call	cmp_hlde	; CY if HL > DE
		jnc	loc_59
loc_58:		xchg	
		shld	word_50
loc_59:		pop	h
		pop	d
loc_60:		push	h
		call	ld_getbyte
		pop	h
		jz	loc_61
		mov	m,a
		inx	h
		jmp	loc_60

loc_54:		cpi	12h
		jz	loc_52
		cpi	8
		jz	loc_52
		cpi	0Eh
		jnz	loc_52
		lhld	word_50
		mov	a,h
		ora	l
		jz	ld_exit
		ret	

loc_52:		call	ld_getbyte
		jnz	loc_52
loc_61:		mov	a,c
		ora	a
		jz	loc_51
ld_exit:	lhld	save_sp
		sphl	
		xra	a
		ret	

;----------------------------------------------------------------------

isx_main:
		xra	a
		sta	byte_62
		mvi	a,0FFh
		sta	unk_1
		lhld	wboot+1
		lxi	d,loc_2	; 0103H
		dcx	h
		mov	m,d
		dcx	h
		mov	m,e
		dcx	h
		shld	bdos+1
		lxi	h,0
		shld	word_3
		lxi	sp,stack
		call	getdsk
		mov	c,a
		push	b
		push	b
		lxi	b,logmsg
		call	ln_print
		call	dsk_reset	; 0FFh in accum if $ file present
		pop	b
		push	psw
		mov	a,c
		call	seldsk
		pop	psw
		pop	b
		inr	a
		ora	c
		call	loc_46		; open $$$.SUB file, if exists
cli:		lxi	sp,stack
		call	crlf
		call	getdsk
		sta	cur_disk
		adi	'0'
		call	printchar
		mvi	a,'>'		; prompt
		call	printchar
		lxi	d,cpm_bfr	; 0080H
		call	isetdma
		call	readcom
		call	fillfcb0
		cnz	comerr
		lda	sdisk		; disk explicitely specified?
		ora	a
		jnz	cmd_run		; yes, take the file name as a command to load
		call	intrinsic	; search for a cli internal command
		lxi	h,jmp_tbl
		mov	e,a
		mvi	d,0
		dad	d
		dad	d
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		pchl			; execute the command

;----------------------------------------------------------------------

jmp_tbl:	dw	cmd_dbug
		dw	cmd_dir
		dw	cmd_era
		dw	cmd_type
		dw	cmd_ren
		dw	cmd_run

logmsg:		db	0Dh,0Ah,'ISIS-II INTERFACE VERS 1.4',0Dh,0Ah,'$'

;----------------------------------------------------------------------

err_read:
		lxi	b,rd_err
		jmp	ln_print

rd_err:		db	'READ ERROR$'

;----------------------------------------------------------------------

err_nofile:
		lxi	b,no_file
		jmp	ln_print

no_file:	db	'NOT FOUND$'


;----------------------------------------------------------------------

		mvi	b,3
copy:		mov	a,m
		stax	d
		inx	h
		inx	d
		dcr	b
		jnz	copy
		ret	

;----------------------------------------------------------------------

cfetch:
		lxi	h,cpm_bfr	; 0080h
		add	c
		call	add_hla
		mov	a,m
		ret	

;----------------------------------------------------------------------

set_disk:
		xra	a
		sta	comfcb
		lda	sdisk
		ora	a
		rz	
		dcr	a
		lxi	h,cur_disk
		cmp	m
		rz	
		jmp	seldsk

;----------------------------------------------------------------------

reset_disk:
		lda	sdisk		; restore disk
		ora	a
		rz	
		dcr	a
		lxi	h,cur_disk
		cmp	m
		rz	
		lda	cur_disk
		jmp	seldsk

;----------------------------------------------------------------------

cmd_dbug:
		call	get_trlvl	; get trace level
		lda	tr_level
		sta	byte_62
		jmp	cmd_exit

;----------------------------------------------------------------------

cmd_dir:
		call	fillfcb0
		call	set_disk
		lxi	h,comfcb+1
		mov	a,m
		cpi	' '
		jnz	cmd_d2
		mvi	b,11
cmd_d1:		mvi	m,'?'
		inx	h
		dcr	b
		jnz	cmd_d1
cmd_d2:		mvi	e,0
		push	d
		call	srchcom
		cz	err_nofile
dir_loop:	jz	cmd_dex
		lda	i_dcnt		; bdos return code
		rrc	
		rrc	
		rrc	
		ani	1100000b
		mov	c,a
		mvi	a,0Ah		; sysfile
		call	cfetch		; get byte pointed by C from cpm_bfr
		ral	
		jc	cmd_d3		; skip if system file
		pop	d
		mov	a,e
		inr	e
		push	d
		ani	3
		push	psw
		jnz	cmd_d4
		call	crlf
		push	b
		mvi	a,'F'
		call	printchar
		call	getdsk
		cpi	10
		jc	cmd_d10
		push	psw
		mvi	a,'1'
		call	printchar
		pop	psw
		sui	10
cmd_d10:	adi	'0'
		call	printchar
		mvi	a,':'
		call	printchar
		pop	b
		jmp	cmd_d5

cmd_d4:		call	put_spc
		mvi	a,':'
		call	printbc		; print char saving BC registers
cmd_d5:		call	put_spc
		mvi	b,1
cmd_d6:		mov	a,b
		call	cfetch		; get byte pointed by C from cpm_bfr
		ani	7Fh
		cpi	' '
		jnz	cmd_d7
		pop	psw
		push	psw
		cpi	3
		jnz	cmd_d9
		mvi	a,9
		call	cfetch		; get byte pointed by C from cpm_bfr
		ani	7Fh
		cpi	' '
		jz	cmd_d8
cmd_d9:		mvi	a,' '
cmd_d7:		call	printbc
		inr	b
		mov	a,b
		cpi	12
		jnc	cmd_d8
		cpi	9
		jnz	cmd_d6
		call	put_spc
		jmp	cmd_d6

cmd_d8:		pop	psw
cmd_d3:		call	break_key
		jnz	cmd_dex
		call	srchnxt
		jmp	dir_loop

cmd_dex:	pop	d
		jmp	cmd_exit

;----------------------------------------------------------------------

cmd_era:
		call	fillfcb0
		cpi	11
		jnz	cmd_rm1
		lxi	b,msg_all	; "all files?"
		call	ln_print
		call	readcom
		lxi	h,buflen
		dcr	m
		jnz	cli
		inx	h
		mov	a,m
		cpi	'Y'
		jnz	cli
		inx	h
		shld	comaddr
		lxi	h,comfcb
		mvi	m,'?'
cmd_rm1:	call	set_disk
		lxi	d,comfcb
		call	erasef
		inr	a
		cz	err_nofile
		jmp	cmd_exit

msg_all:	db	'ALL FILES (Y/N)?$'

;----------------------------------------------------------------------

cmd_type:
		call	fillfcb0
		jnz	comerr
		call	set_disk
		call	openc		; open the file
		jz	typerr
		call	crlf
		lxi	h,bptr
		mvi	m,0FFh
type_loop:	lxi	h,bptr
		mov	a,m
		cpi	128		; end buffer?
		jc	cmd_t3
		push	h
		call	readc		; read the comfcb file
		pop	h
		jnz	typeof
		xra	a
		mov	m,a
cmd_t3:		inr	m
		lxi	h,cpm_bfr	; 0080H
		call	add_hla
		mov	a,m
		cpi	1Ah		; end of text file?
		jz	cmd_exit
		call	printchar
		call	break_key
		jnz	cmd_exit
		jmp	type_loop

;----------------------------------------------------------------------

typeof:
		dcr	a
		jz	cmd_exit
		call	err_read
typerr:		call	reset_disk
		jmp	comerr

;----------------------------------------------------------------------

cmd_ren:
		call	fillfcb0
		jnz	comerr		; must be unambiguous
		lda	sdisk
		push	psw
		call	set_disk
		call	srchcom
		jnz	err_exists
		lxi	h,comfcb
		lxi	d,comfcb+10h	; fcb 1 + 16
		mvi	b,16
		call	copy
		lhld	comaddr
		xchg	
		call	skip_spc
		cpi	'='
		jz	cmd_r1
		cpi	'_'
		jnz	cmd_r2
cmd_r1:		xchg	
		inx	h
		shld	comaddr
		call	fillfcb0
		jnz	cmd_r2
		pop	psw
		mov	b,a
		lxi	h,sdisk
		mov	a,m
		ora	a
		jz	cmd_r3
		cmp	b
		mov	m,b
		jnz	cmd_r2
cmd_r3:		mov	m,b
		xra	a
		sta	comfcb
		call	srchcom
		jz	cmd_r4
		lxi	d,comfcb
		call	irename
		jmp	cmd_exit

cmd_r4:		call	err_nofile
		jmp	cmd_exit

cmd_r2:		call	reset_disk
		jmp	comerr

err_exists:
		lxi	b,f_exists
		call	ln_print
		jmp	cmd_exit

f_exists:	db	'FILE EXISTS$'

;----------------------------------------------------------------------

cmd_run:
		lda	comfcb+1
		cpi	' '
		jnz	cmd_x1
		lda	sdisk
		ora	a
		jz	cmd_exit1
		dcr	a
		sta	cur_disk
		sta	cpm_disk
		call	seldsk
		jmp	cmd_exit1

cmd_x1:		call	set_disk
		call	openc		; open the file
		jz	cmd_x2
		lxi	h,0
		shld	word_55
		call	load
		jz	cmd_x2
		lhld	word_4
		mov	a,h
		ora	l
		jnz	cmd_x3
		lhld	word_50
		shld	word_4
cmd_x3:		call	reset_disk
		call	fillfcb0
		lxi	h,sdisk
		push	h
		mov	a,m
		sta	comfcb
		mvi	a,16
		call	fillfcb
		pop	h
		mov	a,m
		sta	comfcb+10h
		xra	a
		sta	comrec		; comfcb rc byte
		lxi	d,cpm_fcb	; 005CH
		lxi	h,comfcb
		mvi	b,33
		call	copy
		lxi	h,combuf
cmd_x4:		mov	a,m
		ora	a
		jz	cmd_x5
		cpi	' '
		jz	cmd_x5
		inx	h
		jmp	cmd_x4

cmd_x5:		mvi	b,0
		lxi	d,cpm_bfr+1
cmd_x6:		mov	a,m
		stax	d
		ora	a
		jz	cmd_x7
		inr	b
		inx	h
		inx	d
		jmp	cmd_x6

cmd_x7:		mov	a,b
		sta	cpm_bfr
		call	crlf
		lda	cur_disk
		sta	cpm_disk
		lxi	d,cpm_bfr	; 0080H
		call	isetdma
		call	loc_63
		lxi	h,pgm_return	; return address
		push	h
		call	setup_40h
		lhld	word_3
		mov	a,h
		ora	l
		jz	cmd_x8
		pchl	

cmd_x8:		lhld	word_4
		pchl	

;----------------------------------------------------------------------

pgm_return:
		lxi	sp,stack
		call	res_40h
		lda	cur_disk
		call	seldsk
		jmp	cli

;----------------------------------------------------------------------

cmd_x2:
		call	reset_disk
		jmp	comerr

;----------------------------------------------------------------------

		lxi	b,ld_err
		call	ln_print
		jmp	cmd_exit

ld_err:		db	'LOAD ERROR$'

;----------------------------------------------------------------------

cmd_exit:
		call	reset_disk
cmd_exit1:
		call	fillfcb0
		lda	comfcb+1
		sui	20h
		lxi	h,sdisk
		ora	m
		jnz	comerr
		jmp	cli

;----------------------------------------------------------------------

loc_64:
		lhld	fd_ptr
		lxi	d,21h
		dad	d
		mov	c,m
		inx	h
		mov	b,m
		inx	h
		mov	e,m		; DE = fd bfr addr
		inx	h
		mov	d,m
		lhld	word_65
		xchg	
		ret	

;----------------------------------------------------------------------

loc_66:
		lhld	word_65
		mov	a,l
		sub	e
		mov	l,a
		mov	a,h
		sbb	d
		mov	h,a		; HL = HL - DE
		shld	word_67
		lhld	fd_ptr
		lxi	d,21h
		dad	d
		mov	m,c
		inx	h
		mov	m,b
		ret	

;----------------------------------------------------------------------

loc_68:
		lhld	fd_ptr		; fd
		xchg	
		lxi	h,0Ch		; fcb ex
		dad	d
		mov	b,m
		lxi	h,20h		; fcb cr
		dad	d
		mov	c,m
		lxi	h,21h		; fcb r0
		dad	d
		mov	a,m
		mov	l,b
		mvi	h,0
		dad	h
		dad	h
		dad	h
		dad	h
		dad	h
		dad	h
		dad	h		; *128 (rec size)
		mvi	b,0
		dad	b
		cpi	80h
		jc	loc_69
		inx	h
		sui	80h
loc_69:		mov	e,a
		mvi	d,0
		lda	byte_70
		ani	3		; check mode bits
		cpi	1		; write?
		jnz	loc_71
		dcx	h
loc_71:		shld	num_recs
		mov	a,e
		sta	lrec_bcnt	; last record byte count
		ret	

;----------------------------------------------------------------------

loc_72:
		call	loc_68
		mov	b,a
		xra	a
		mov	a,h
		rar	
		mov	e,a
		mov	a,l
		rar	
		mov	h,a
		rar	
		ani	80h
		ora	b
		mov	l,a
		push	h
		push	d
		lhld	fd_ptr
		xchg	
		lxi	h,27h		; fd last record byte cnt
		dad	d
		mov	a,m
		lxi	h,25h		; fd num of records
		dad	d
		mov	e,m
		inx	h
		mov	d,m
		mov	h,a
		xra	a
		mov	a,d
		rar	
		mov	b,a
		mov	a,e
		rar	
		mov	c,a
		rar	
		ani	80h
		ora	h
		pop	d
		pop	h
		ora	a
		sub	l
		mov	l,a
		mov	a,c
		sbb	h
		mov	h,a
		mov	a,b
		sbb	e
		mov	e,a
		ret	

;----------------------------------------------------------------------

loc_73:
		mov	a,l
		ani	7Fh
		mov	c,a
		mov	a,l
		add	a
		mov	a,h
		ral	
		mov	b,a
		ret	

;----------------------------------------------------------------------

loc_74:
		push	h
		push	b
		call	isetdma
		lhld	fd_ptr
		push	h
		xchg	
		call	readf
		pop	h
		jnz	loc_75
		lxi	d,20h
		dad	d
		dcr	m
loc_75:		pop	b
		pop	h
		ret	

;----------------------------------------------------------------------

loc_76:
		push	h
		push	b
		call	isetdma
		lhld	fd_ptr		; fcb addr
		xchg	
		call	readf		; bdos read record
		pop	b
		pop	h
		ret	

;----------------------------------------------------------------------

loc_77:
		push	b
		push	d
		push	h
		xchg	
		call	isetdma
		lhld	fd_ptr		; fcb addr
		xchg	
		call	writef
		pop	h
		pop	d
		pop	b
		ret	

;----------------------------------------------------------------------

loc_78:
		call	loc_72
		jnc	loc_79
		lxi	h,0
		shld	word_65
		jmp	loc_80

loc_79:		jnz	loc_80
		xchg	
		lhld	word_65
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	loc_80
		xchg	
		shld	word_65
loc_80:		call	loc_64
		push	h
		lhld	word_81
		xthl	
		xra	a
		sta	byte_82
		lda	byte_70
		ani	3
		cpi	3
		jnz	loc_83
		mov	a,d
		ora	a
		jnz	loc_84
		mvi	a,80h
		sub	c
		sub	e
		jnc	loc_83
loc_84:		call	loc_77		; write record, HL = buffer
		mvi	a,0FFh
		sta	byte_82
loc_83:		mov	a,c
		ora	a
		jm	loc_85
		mov	a,d
		ora	e
		jz	loc_86
		push	h
		dad	b
		mov	a,m
		pop	h
		inx	b
		xthl	
		mov	m,a
		inx	h
		xthl	
		dcx	d
		jmp	loc_83

loc_85:		mov	a,d
		ora	a
		jnz	loc_87
		mov	a,e
		ora	a
		jm	loc_87
		jz	loc_86
		push	d
		mov	d,h
		mov	e,l
		call	loc_76		; read record, DE = bfr
		pop	d
		jnz	loc_86
		lxi	b,0
		jmp	loc_83

loc_87:		xthl	
		push	d
		mov	d,h
		mov	e,l
		call	loc_76		; read record, DE = buffer
		pop	d
		dad	b
		xthl	
		jnz	loc_86
		push	h
		lxi	h,0FF80h
		dad	d
		xchg	
		pop	h
		jmp	loc_85

loc_86:		lda	byte_82
		ora	a
		jz	loc_88
		mov	a,c
		ora	a
		jp	loc_89
		push	d
		mov	d,h
		mov	e,l
		call	loc_76		; read record, DE = buffer
		pop	d
		lxi	b,0
		jnz	loc_88
loc_89:		push	d
		push	h
		lhld	fd_ptr
		lxi	d,20h
		dad	d
		dcr	m
		pop	h
		pop	d
loc_88:		pop	h
		call	loc_66
		call	dma80		; set dma to default 0080H
		ret	

;----------------------------------------------------------------------

loc_90:
		call	loc_72
		jc	loc_91
		jnz	loc_92
		mov	a,h
		ora	l
		jz	loc_91
loc_92:		call	loc_64
		mov	a,c
		ora	a
		jp	loc_93
		mov	d,h
		mov	e,l
		call	loc_76		; read record, DE = buffer
		push	psw
		call	dma80		; set dma to default 0080H
		pop	psw
		jnz	loc_91
		lxi	b,0
loc_93:		dad	b
		mov	a,m
		lhld	fd_ptr
		lxi	d,21h
		dad	d
		inx	b
		mov	m,c
		inx	h
		mov	m,b
		ani	7Fh
		ret	

loc_91:		mvi	a,1Ah
		ret	

;----------------------------------------------------------------------

loc_94:
		lhld	fd_ptr
		lxi	d,0Dh
		dad	d
		mvi	m,0
		call	loc_64
		push	h
		lhld	word_81
		xthl	
loc_95:		mov	a,c
		ora	a
		jz	loc_96
		jp	loc_97
		push	d
		mov	d,h
		mov	e,l
		call	loc_77		; write record, HL = buffer
		pop	d
		lxi	b,0
		jnz	loc_98
		jmp	loc_96

loc_97:		mov	a,e
		ora	d
		jz	loc_99
		xthl	
		mov	a,m
		inx	h
		xthl	
		push	h
		dad	b
		mov	m,a
		pop	h
		inx	b
		dcx	d
		jmp	loc_95

loc_96:		mov	a,d
		ora	a
		jnz	loc_100
		mov	a,e
		ora	a
		jm	loc_100
		push	psw
		lda	byte_70
		ani	3
		cpi	3
		jnz	loc_101
		push	d
		mov	d,h
		mov	e,l
		call	loc_74
		pop	d
loc_101:	pop	psw
		jz	loc_99
loc_102:	xthl	
		mov	a,m
		inx	h
		xthl	
		push	h
		dad	b
		mov	m,a
		pop	h
		inx	b
		dcx	d
		mov	a,e
		ora	d
		jnz	loc_102
		jmp	loc_99

loc_100:	xthl	
		push	h
		call	loc_77		; write record, HL = buffer
		pop	h
		xthl	
		jnz	loc_98
		lxi	b,80h
		xthl	
		dad	b
		xthl	
		lxi	b,0FF80h
		xchg	
		dad	b
		xchg	
		lxi	b,0
		jmp	loc_96

loc_98:		mvi	a,0FFh
		sta	byte_103
loc_99:		pop	h
		call	loc_66
		call	dma80		; set dma to default 0080H
		lhld	fd_ptr
		xchg	
		lxi	h,21h
		dad	d
		mvi	a,80h
		sub	m
		cpi	80h
		rz	
		lxi	h,0Dh
		dad	d
		mov	m,a
		ret	

;----------------------------------------------------------------------

loc_104:
		push	b
		lhld	word_105
		lxi	d,21h
		dad	d
		mov	c,m
		inx	h
		mov	b,m
		inx	h
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		mov	a,c
		ora	a
		jp	loc_106
		push	h
		xchg	
		call	isetdma
		lhld	word_105
		push	h
		lxi	d,0Dh
		dad	d
		mvi	m,0
		pop	d
		call	writef
		pop	h
		jnz	loc_107
		lxi	b,0
loc_106:	dad	b
		pop	d
		mov	m,e
		lhld	word_105
		xchg	
		lxi	h,21h
		dad	d
		inx	b
		mov	m,c
		inx	h
		mov	m,b
		lxi	h,0Dh
		dad	d
		mvi	a,80h
		sub	c
		mov	m,a
		lxi	h,27h
		dad	d
		inr	m
		mov	a,m
		sui	80h
		rc	
		mov	m,a
		lxi	h,25h
		dad	d
		inr	m
		rnz	
		inx	h
		inr	m
		ret	

loc_107:	pop	d
		lxi	h,byte_103
		mvi	m,0FFh
		ret	

;----------------------------------------------------------------------

set_iobyte:
		push	psw
		lda	iobyte
		sta	old_iobyte
		pop	psw
		sta	iobyte
		ret	

;----------------------------------------------------------------------

res_iobyte:
		lda	old_iobyte
		sta	iobyte
		ret	

;----------------------------------------------------------------------

loc_63:
		lxi	h,f_dscrptrs
		lxi	d,28h		; 40 - size of struct fd
		mvi	c,6
loc_108:	mvi	m,0E5h
		dad	d
		dcr	c
		jnz	loc_108
		lxi	h,fd_tab
		lxi	d,byte_109
		mvi	c,8
		xra	a
loc_110:	mov	m,a
		stax	d
		inx	d
		inx	h
		dcr	c
		jnz	loc_110
		mvi	a,6
		sta	fd_tab
		mvi	a,5
		sta	fd_tab+1
		lxi	h,0
		shld	word_111
		lxi	h,loc_57	; 3100H
loc_112:	push	h
		lhld	word_50
		xchg	
		lhld	bdos+1
		call	cmp_hlde	; CY if HL > DE
		jc	loc_113
		xchg	
loc_113:	pop	h
		push	h
loc_114:	lxi	b,80h
		dad	b
		call	cmp_hlde	; CY if HL > DE
		pop	d
		jc	loc_115
		lhld	word_111
		xchg	
		shld	word_111
		mov	m,e
		inx	h
		mov	m,d
		lxi	d,7Fh
		dad	d
		jmp	loc_112

loc_115:	lxi	h,unk_116
		lxi	d,buflen
		ldax	d
		mov	m,a
		inr	m
		inr	m
		mov	b,a
loc_117:	inx	d
		inx	h
		mov	a,b
		ora	a
		jz	loc_118
		dcr	b
		ldax	d
		mov	m,a
		jmp	loc_117

loc_118:	mvi	m,0Dh		; cr
		inx	h
		mvi	m,0Ah		; lf
		lxi	h,unk_119
		mvi	b,0
loc_120:	mov	a,m
		cpi	0Dh		; cr
		jz	loc_121
		cpi	' '
		jz	loc_121
		inx	h
		inr	b
		jmp	loc_120

loc_121:	lxi	h,unk_122
		mov	m,b
		inx	h
		mvi	m,7Eh
		ret	

;----------------------------------------------------------------------

loc_123:
		lhld	word_111
		mov	a,l
		ora	h
		rz	
		mov	e,m
		inx	h
		mov	d,m
		dcx	h
		xchg	
		shld	word_111
		ret	

;----------------------------------------------------------------------

loc_124:
		lhld	word_111
		xchg	
		shld	word_111
		mov	m,e
		inx	h
		mov	m,d
		ret	

;----------------------------------------------------------------------

loc_125:
		lxi	h,f_dscrptrs
		mvi	b,6		; 6 fd's
loc_126:	lxi	d,comfcb
		mvi	c,11		; filename length (8+3)
		push	h
		mvi	a,0E5h
		cmp	m		; empty fd?
		jz	loc_127		; yes -> try next
loc_128:	ldax	d
		cmp	m		; same file name?
		jnz	loc_127		; no -> try next
		inx	d
		inx	h
		dcr	c
		jnz	loc_128
		pop	h
		ret	

loc_127:	pop	h
		lxi	d,28h		; 40 - sizeof struct fd
		dad	d
		dcr	b
		jnz	loc_126
		inr	b
		ret	

;----------------------------------------------------------------------

loc_129:
		call	dma80		; set dma to default 0080H
		lxi	d,comfcb
		call	fsize		; compute file size
		xra	a
		sta	comfcb+0Ch	; set ex = 0
		sta	lrec_bcnt	; last record byte count
		mov	l,a
		mov	h,a
		shld	num_recs
		lxi	d,comfcb
		call	openf
		rz	
		lhld	comrnd		; get the file size from r0,r1
		mov	a,h
		ora	l		; file has zero records?
		jz	loc_130		; yes -> exit
		push	h
		dcx	h
		shld	comrnd
		lxi	d,comfcb
		call	rndrd		; read the last record
		pop	h
		lda	comfcb+0Dh	; s1 byte (last record byte count?)
		ora	a
		jz	loc_131
		dcx	h
		mov	b,a
		mvi	a,80h
		sub	b
loc_131:	sta	lrec_bcnt	; last record byte count
		shld	num_recs
		lxi	h,0
		shld	comrnd
		lxi	d,comfcb
		call	rndrd		; read the first record
loc_130:	xra	a
		dcr	a
		ret	

;----------------------------------------------------------------------

close_fd:
		lxi	h,f_dscrptrs
		lxi	d,28h		; 40 - size of struct fd
loc_132:	ora	a
		jz	loc_133
		dad	d
		dcr	a
		jmp	loc_132

loc_133:	shld	fd_ptr		; save fd address
		mov	a,m
		cpi	0E5h		; in use?
		jz	loc_134
		mov	a,b
		lxi	d,21h		; offset to r0,r1,r2 in fcb
		dad	d
		mov	c,m
		inx	h
		mov	b,m
		inx	h
		mov	e,m
		inx	h
		mov	d,m
		ani	3
		cpi	1
		jz	loc_135
		mov	a,b
		ora	c
		jz	loc_135
		push	d
		xchg	
		dad	b
		mov	a,c
loc_136:	cpi	80h
		jz	loc_137
		mvi	m,1Ah
		inr	a
		inx	h
		jmp	loc_136

loc_137:	pop	h
		push	h
		call	loc_77		; write record, HL = buffer
		pop	d
		jz	loc_135
		call	loc_124
		mvi	b,1
		jmp	loc_138

loc_135:	push	d
		lhld	fd_ptr
		xchg	
		call	closef		; close the file
		pop	d
		mvi	b,30		; error code = close error
		jz	loc_138
		call	loc_124
		call	dma80		; set dma to default 0080H
loc_134:	mvi	b,0		; no error
loc_138:	lhld	fd_ptr
		mvi	m,0E5h		; mark the fd as unused
		ret	

;----------------------------------------------------------------------

store_word:
		push	d
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		pop	d
		mov	m,a
		inx	h
		mvi	m,0
		ret	

;----------------------------------------------------------------------

loc_139:
		mov	e,a
		cpi	1		; :CI: ?
		jnz	loc_140
		lxi	d,unk_122
		ora	a
		ret	

loc_140:	lxi	h,byte_109
		call	add_hla
		mov	a,m
		ora	a
		rz	
		mvi	d,0
		lxi	h,word_141
		dad	d
		dad	d
		mov	e,m
		inx	h
		mov	d,m
		dcx	h
		ret	

;----------------------------------------------------------------------

next_arg:				; get word pointed by pgm_de
		lhld	pgm_de
		mov	e,m
		inx	h
		mov	d,m
		inx	h
		shld	pgm_de
		ret	

;----------------------------------------------------------------------

get_filename:
		call	next_arg	; get word pointed by pgm_de
		mvi	c,16		; max isis filespec length
		lxi	h,buflen
		mov	m,c
get_fn0:	inx	h
		ldax	d
		mov	m,a
		inx	d
		dcr	c
		jnz	get_fn0
		jmp	noread		; uppercase the buffer

;----------------------------------------------------------------------

get_rw_args:
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		sta	fileno
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	word_81		; save ptr to buffer
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	word_65		; save count
		cpi	8		; fileno > 7 ?
		jnc	loc_142		; yes -> error
		lxi	h,fd_tab
		call	add_hla
		mov	a,m
		ora	a		; free fd ?
		jz	loc_142		; yes -> error
		sta	byte_70		; save byte from fd_tab
		ret			; returns nz

loc_142:	mvi	b,2
		xra	a
		ret	

;----------------------------------------------------------------------

find_fd:
		lxi	h,f_dscrptrs
		lxi	d,28h		; 40 - size of struct fd
find_fd0:	ora	a
		rz	
		dad	d
		dcr	a
		jmp	find_fd0

;----------------------------------------------------------------------

dev_read:
		lxi	h,byte_143
		mov	e,m
		lxi	h,idrv_tbl
		mvi	d,0
		dad	d
		dad	d
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		pchl	

;----------------------------------------------------------------------

idrv_tbl:	dw	loc_144
		dw	con_input
		dw	rdr_input
		dw	tty_input
		dw	crt_input
		dw	uc1_input
		dw	ptr_input
		dw	ur1_input
		dw	ur2_input
		dw	emp_input

;----------------------------------------------------------------------

con_in:
		mvi	c,1		; console input
		call	bdos
		mov	e,a
		ret	

;----------------------------------------------------------------------

rdr_in:
		mvi	c,3		; reader input
		call	bdos
		mov	e,a
		ret

;----------------------------------------------------------------------

loc_144:
		call	loc_90
		jmp	io_ex2

;----------------------------------------------------------------------

con_input:
		call	con_in
		jmp	io_ex1

;----------------------------------------------------------------------

rdr_input:
		call	rdr_in
		jmp	io_ex1

;----------------------------------------------------------------------

tty_input:
		mvi	a,0		; TTY:
		call	set_iobyte
		call	con_in
		jmp	io_exit

;----------------------------------------------------------------------

crt_input:
		mvi	a,1		; CRT:
		call	set_iobyte
		call	con_in
		jmp	io_exit

;----------------------------------------------------------------------

uc1_input:
		mvi	a,3		; UC1:
		call	set_iobyte
		call	con_in
		jmp	io_exit

;----------------------------------------------------------------------

ptr_input:
		mvi	a,4		; PTR:
		call	set_iobyte
		call	rdr_in
		jmp	io_exit

;----------------------------------------------------------------------

ur1_input:
		mvi	a,8		; UR1:
		call	set_iobyte
		call	rdr_in
		jmp	io_exit

;----------------------------------------------------------------------

ur2_input:
		mvi	a,0Ch		; UR2:
		call	set_iobyte
		call	rdr_in
		jmp	io_exit

;----------------------------------------------------------------------

emp_input:
		mvi	e,1Ah
		jmp	io_ex1

;----------------------------------------------------------------------

io_exit:
		call	res_iobyte
io_ex1:		mov	a,e
io_ex2:		cpi	1Ah
		jnz	io_return
		lxi	h,byte_145
		mvi	m,0FFh
io_return:	ret
	
;----------------------------------------------------------------------

dev_write:
		lxi	h,byte_146
		mov	e,m
		lxi	h,odrv_tbl
		mvi	d,0
		dad	d
		dad	d
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		mov	e,c
		pchl	

;----------------------------------------------------------------------

odrv_tbl:	dw	loc_147
		dw	con_output
		dw	lst_output
		dw	pun_output
		dw	tty_output
		dw	crt_output
		dw	uc1_output
		dw	lpt_output
		dw	ul1_output
		dw	ptp_output
		dw	up1_output
		dw	up2_output
		dw	emp_output

;----------------------------------------------------------------------

con_out:
		mvi	c,2		; console output
		jmp	bdos

;----------------------------------------------------------------------

pun_out:
		mvi	c,4		; punch output
		jmp	bdos

;----------------------------------------------------------------------

lst_out:
		mvi	c,5		; list output
		jmp	bdos

;----------------------------------------------------------------------

loc_147:
		call	loc_104
		jmp	o_return

;----------------------------------------------------------------------

con_output:
		call	con_out
		jmp	o_return

;----------------------------------------------------------------------

lst_output:
		call	lst_out
		jmp	o_return

;----------------------------------------------------------------------

pun_output:
		call	pun_out
		jmp	o_return

;----------------------------------------------------------------------

tty_output:
		mvi	a,0		; TTY:
		call	set_iobyte
		call	con_out
		jmp	o_exit

;----------------------------------------------------------------------

crt_output:
		mvi	a,1		; CRT:
		call	set_iobyte
		call	con_out
		jmp	o_exit

;----------------------------------------------------------------------

uc1_output:
		mvi	a,3		; UC1:
		call	set_iobyte
		call	con_out
		jmp	o_exit

;----------------------------------------------------------------------

lpt_output:
		mvi	a,80h		; LPT:
		call	set_iobyte
		call	lst_out
		jmp	o_exit

;----------------------------------------------------------------------

ul1_output:
		mvi	a,0C0h		; UL1:
		call	set_iobyte
		call	lst_out
		jmp	o_exit

;----------------------------------------------------------------------

ptp_output:
		mvi	a,10h		; PTP:
		call	set_iobyte
		call	pun_out
		jmp	o_exit

;----------------------------------------------------------------------

up1_output:
		mvi	a,20h		; UP1:
		call	set_iobyte
		call	pun_out
		jmp	o_exit

;----------------------------------------------------------------------

up2_output:
		mvi	a,30h		; UP2:
		call	set_iobyte
		call	pun_out
		jmp	o_exit

;----------------------------------------------------------------------

emp_output:
		jmp	o_return

;----------------------------------------------------------------------

o_exit:					; restore original iobyte value
		call	res_iobyte
o_return:
		ret	

;----------------------------------------------------------------------

idos_ept:				; isis dos entry point
		xchg	
		shld	pgm_de		; save DE
		mov	a,c
		sta	pgm_c		; save C
		lxi	h,0
		dad	sp
		shld	pgm_sp		; save program SP
		lxi	sp,stack
		call	res_40h		; restore the original ram contents at 0040H
		lda	pgm_c
		cpi	0Fh
		jc	loc_148
		mvi	a,18		; error code
		jmp	error

;----------------------------------------------------------------------

loc_148:
		lda	byte_62
		ora	a
		jz	loc_149
		call	break_key
		jz	loc_149
		call	get_trlvl	; get trace level
loc_149:	xra	a
		sta	byte_23
		lda	tr_level
		ora	a
		jz	no_trace
		call	tr_dump		; trace dump
no_trace:	lda	pgm_c
		lxi	h,ifn_tbl
		mov	e,a
		mvi	d,0
		dad	d
		dad	d
		mov	a,m
		inx	h
		mov	d,m
		mov	e,a
		lhld	pgm_de
		xchg	
		pchl	

;----------------------------------------------------------------------

ifn_tbl:	dw	fn_open
		dw	fn_close
		dw	fn_delete
		dw	fn_read
		dw	fn_write
		dw	fn_seek
		dw	fn_load
		dw	fn_rename
		dw	fn_console
		dw	fn_exit
		dw	fn_attrib
		dw	fn_rescan
		dw	fn_error
		dw	fn_whocon
		dw	fn_spath

;----------------------------------------------------------------------

fn_open:
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	fileno		; ptr to fileno
		call	get_filename
		call	next_arg	; get access
		mov	a,e
		ora	a
		jz	fn_open_err22
		cpi	4
		jnc	fn_open_err22
		sta	byte_70
		cpi	3
		jz	fn_open_file
		call	loc_37		; test for device name
		jz	fn_open_file
		cpi	0FFh
		mvi	b,5		; error: invalid device name
		jz	fn_open_ex1
		cpi	2
		jnc	loc_150
		lda	byte_70
		cpi	1
		jz	loc_151
		xra	a
loc_151:	lhld	fileno		; ptr to fileno
		mov	m,a
		mvi	b,0		; no error
		inx	h
		mov	m,b
		jmp	fn_open_ex1	; exit with no error

loc_150:	add	a
		add	a
		jmp	loc_152

;----------------------------------------------------------------------

fn_open_file:
		call	fillfcb0
		lda	comfcb+1
		cpi	' '		; empty fcb?
		mvi	b,23		; error: bad file name
		jz	fn_open_ex1
		call	loc_125		; file already open?
		mvi	b,12		; error: file already open
		jz	fn_open_ex1	; yes -> error
		lda	byte_70		; file access
		cpi	2
		jnz	loc_153
		lxi	d,comfcb
		call	erasef
		jmp	loc_154

loc_153:	call	loc_129		; open the file and get the file size
		mvi	b,13		; error: file not found
		jnz	loc_155
		lda	byte_70		; file access
		cpi	3
		jnz	fn_open_ex1
loc_154:	lxi	d,comfcb
		call	makef
		inr	a
		mvi	b,9		; error: can't create file
		jz	fn_open_ex1
		lxi	h,0
		shld	num_recs
		xra	a
		sta	lrec_bcnt	; last record byte count
loc_155:	xra	a
		sta	comrec		; comfcb rc byte
		lxi	h,f_dscrptrs	; find a free fd
		lxi	d,28h
		lxi	b,6
		mvi	a,0E5h
loc_156:	cmp	m
		jz	loc_157
		inr	b
		dad	d
		dcr	c
		jnz	loc_156
		mvi	b,3		; error: not enough fd's
		jmp	fn_open_ex1

loc_157:	mvi	c,33		; fcb length
		lxi	d,comfcb
loc_158:	ldax	d
		mov	m,a		; copy the fcb to the fd
		inx	d
		inx	h
		dcr	c
		jnz	loc_158
		lxi	d,0
		lda	byte_70		; file access
		cpi	1
		jnz	loc_159
		lxi	d,80h
loc_159:	mov	m,e
		inx	h
		mov	m,d
		inx	h
		push	h
		call	loc_123
		pop	h
		jnz	loc_160
		mvi	b,1		; error code
		jmp	fn_open_ex1

loc_160:	mov	m,e
		inx	h
		mov	m,d
		inx	h
		xchg	
		lhld	num_recs
		xchg	
		mov	m,e
		inx	h
		mov	m,d
		inx	h
		lda	lrec_bcnt	; last record byte count
		mov	m,a
		mov	a,b		; B = fd number
		add	a
		add	a		; shift left two bits
		ori	80h		; set "has fd" bit
loc_152:	lxi	h,byte_70	; file access
		ora	m		; add the file access bits
		mov	m,a
		lxi	h,fd_tab
		xra	a
		lxi	b,8
loc_161:	cmp	m		; search for an empty entry in fd_tab
		jz	loc_162
		inr	b
		inx	h
		dcr	c
		jnz	loc_161
		mvi	b,3		; error: not enough fd's
		jmp	fn_open_ex1

loc_162:	lda	byte_70
		mov	m,a		; save entry in fd_tab
		mov	a,b
		lhld	fileno		; ptr to fileno
		mov	m,a		; set the fileno return value
		inx	h
		mvi	m,0
		sta	fileno		; change to fileno value
		call	next_arg	; get echo mode
		lxi	h,byte_109
		call	add_hla
		mvi	m,0
		mov	a,e
		cpi	8
		jnc	fn_open_err25
		ora	a
		jz	fn_open_ok
		push	h
		lxi	h,fd_tab
		call	add_hla
		mov	a,m
		ani	3
		pop	h
		cpi	2
		jnz	fn_open_err25
		push	d
		push	h
		call	loc_123
		pop	h
		pop	b
		jnz	loc_163
		mvi	a,1		; error code
		jmp	fn_open_exit

loc_163:	mov	m,c
		push	d
		lda	fileno
		call	loc_139
		pop	d
		mov	m,e
		inx	h
		mov	m,d
		xchg	
		xra	a
		mov	m,a
		inx	h
		mvi	m,78h
		inx	h
		mov	m,a

fn_open_ok:	mvi	a,0		; no error
		jmp	fn_open_exit

;----------------------------------------------------------------------

fn_open_err25:
		mvi	a,25		; error code
fn_open_exit:
		lhld	pgm_de
		call	store_word
		jmp	idos_exit

;----------------------------------------------------------------------

fn_open_err22:
		mvi	b,22		; error: invalid access
fn_open_ex1:
		call	next_arg	; skip echo parameter
		mov	a,b
		call	store_word
		jmp	idos_exit

;----------------------------------------------------------------------

fn_close:
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		cpi	8		; valid file numbers = 0..7
		jnc	fn_clserr
		cpi	2
		jc	fn_clsok	; don't close :CI: and :CO:
		lxi	h,fd_tab
		call	add_hla
		mov	a,m
		mvi	m,0		; clear the fd entry in fd_tab
		ora	a
		jz	fn_clsok	; return if already closed
		push	psw
		mov	a,e
		call	loc_139
		cnz	loc_124
		pop	psw
		jp	fn_clsok	; return if not a disk file
		push	psw
		ani	3
		mov	b,a
		pop	psw
		rrc	
		rrc	
		ani	1Fh		; get the number of the associated file descriptor (fcb)
		call	close_fd
		jmp	fn_clsexit

fn_clsok:	mvi	b,0
		jmp	fn_clsexit

fn_clserr:	mvi	b,9		; error: invalid file number
fn_clsexit:	lhld	pgm_de
		mov	a,b
		call	store_word	; store the return value
		jmp	idos_exit

;----------------------------------------------------------------------

fn_delete:
		call	get_filename
		call	fillfcb0
		lxi	d,comfcb
		call	erasef
		xra	a		; no error
		lhld	pgm_de
		call	store_word	; store the return code
		jmp	idos_exit

;----------------------------------------------------------------------

fn_read:
		call	get_rw_args
		jz	fn_rderr
		lda	byte_70		; byte from fd_tab
		ani	3		; mask file access bits
		cpi	2		; read allowed?
		jnz	loc_164
		mvi	b,8		; error: bad file access
		jmp	fn_rderr

loc_164:	lda	byte_70
		ora	a		; fd (fcb) associated ?
		jp	loc_165		; no ->
		rar	
		rar	
		ani	1Fh
		call	find_fd
		shld	fd_ptr
		xra	a
		jmp	loc_166

loc_165:	rar	
		rar	
		ani	1Fh
loc_166:	sta	byte_143
		xra	a
		sta	byte_145
		sta	byte_103
		lhld	word_81
		shld	dmp_from
		lxi	h,0
		shld	word_67
		lda	fileno
		cpi	1		; :CI: ?
		jnz	loc_167
		lxi	h,unk_122
		shld	word_168
		mov	a,m
		inx	h
		inx	h
		cmp	m
		jnz	loc_169
		mvi	c,0Ah		; read console buffer
		lxi	d,unk_170
		call	bdos
		lxi	h,unk_122
		mvi	m,0
		inx	h
		inx	h
		mov	a,m		; chars read
		inr	m
		inr	m		; add two extra chars: cr and lf
		inx	h
		call	add_hla
		mvi	m,0Dh		; cr
		inx	h
		mvi	m,0Ah		; lf
		call	crlf
		jmp	loc_169

loc_167:	lxi	h,byte_109
		call	add_hla
		mov	a,m
		ora	a
		jz	loc_171
		sta	byte_146
		lda	fileno
		call	loc_139
		xchg	
		shld	word_168
		mov	a,m
		inx	h
		inx	h
		cmp	m
		jnz	loc_169
		lda	byte_146
		lxi	h,fd_tab
		call	add_hla
		mov	a,m
		ora	a
		jm	loc_172
		rar	
		rar	
		ani	1Fh
		jmp	loc_173

loc_172:	rar	
		rar	
		ani	1Fh
		call	find_fd
		shld	word_105
		xra	a
loc_173:	sta	byte_146
		mvi	c,0
		lhld	word_168
		mov	m,c
		inx	h
		inx	h
		mov	m,c
loc_174:	lhld	word_168
		inx	h
		mov	b,m
		inx	h
		mov	a,m
		cmp	b
		jnc	loc_169
		inr	m
		call	add_hla
		inx	h
		push	h
		mov	a,c
		ora	a
		jnz	loc_175
loc_176:	call	dev_read
		cpi	0Ah
		jz	loc_176
loc_175:	pop	h
		mov	m,a
		mov	c,a
		push	b
		call	dev_write
		pop	b
		lda	byte_103
		ora	a
		mvi	b,7
		jnz	loc_177
		mov	a,c
		mvi	c,0
		cpi	0Ah		; lf
		jz	loc_178
		cpi	0Dh		; cr
		jnz	loc_174
		mvi	c,0Ah		; lf
		jmp	loc_174

loc_178:	lhld	word_168
		inx	h
		inx	h
		mov	a,m
		cpi	3
		jnz	loc_169
		inx	h
		mov	a,m
		cpi	1Ah
		jnz	loc_169
		dcx	h
		mvi	m,0
loc_169:	lhld	word_168
		mov	b,m
		inx	h
		inx	h
		mov	a,m
		sub	b
		mov	b,a
		lhld	word_65
		xchg	
loc_179:	mov	a,b
		ora	a
		jz	loc_180
		mov	a,d
		ora	e
		jz	loc_180
		dcr	b
		dcx	d
		lhld	word_168
		mov	a,m
		inr	m
		inx	h
		inx	h
		inx	h
		call	add_hla
		mov	a,m
		lhld	word_81
		mov	m,a
		inx	h
		shld	word_81
		cpi	1Ah
		jnz	loc_179
loc_180:	lhld	word_65
		mov	a,l
		sub	e
		mov	l,a
		mov	a,h
		sbb	d
		mov	h,a
		shld	word_67
		jmp	loc_181

;----------------------------------------------------------------------

loc_171:
		lda	byte_143
		ora	a
		jnz	loc_182
		call	loc_78
		jmp	loc_181

loc_182:	lda	byte_145
		ora	a
		jnz	loc_181
		lhld	word_65
		mov	a,l
		ora	h
		jz	loc_177
		dcx	h
		shld	word_65
		call	dev_read
		lhld	word_81
		mov	m,a
		inx	h
		shld	word_81
		lhld	word_67
		inx	h
		shld	word_67
		jmp	loc_182

loc_181:	mvi	b,0		; no error
loc_177:	call	next_arg	; get word pointed by pgm_de
		lhld	word_67
		xchg	
		mov	m,e
		inx	h
		mov	m,d
		lhld	pgm_de
		mov	a,b
		call	store_word
		lda	tr_level
		ani	8
		jz	idos_exit
		call	crlf
		lhld	dmp_from
		xchg	
		lhld	word_67
		mov	a,l
		ora	h
		jz	idos_exit
		dad	d
		dcx	h
		shld	dmp_to
		call	dump_mem
		call	crlf
		jmp	idos_exit

;----------------------------------------------------------------------

fn_rderr:
		call	next_arg	; skip next word
		mov	a,b
		call	store_word	; store the return code
		jmp	idos_exit

;----------------------------------------------------------------------

fn_write:
		call	get_rw_args
		jz	loc_183
		lda	byte_70		; byte from fd_tab
		ani	3		; mask access bits
		cpi	1
		jnz	loc_184
		mvi	b,6		; error: bad file access
		jmp	loc_183

loc_184:	lda	byte_70
		ora	a		; fd (fcb) associated?
		jp	loc_185		; no ->
		rar	
		rar	
		ani	1Fh
		call	find_fd
		shld	fd_ptr
		xra	a
		jmp	loc_186

loc_185:	rar	
		rar	
		ani	1Fh
loc_186:	sta	byte_146
		xra	a
		sta	byte_103
		lda	tr_level	; check trace level
		ani	10h
		jz	loc_187
		call	crlf
		lhld	word_65
		mov	a,l
		ora	h
		jz	loc_187
		xchg	
		lhld	word_81
		shld	dmp_from
		dad	d
		dcx	h
		shld	dmp_to
		call	dump_mem
		call	crlf
loc_187:	lda	byte_146
		ora	a
		jnz	loc_188
		call	loc_94
		lda	byte_103
		ora	a
		jz	loc_189
		mvi	b,7
		jmp	loc_183

loc_189:	call	loc_68
		mov	c,l
		mov	b,h
		lhld	fd_ptr
		lxi	d,25h
		dad	d
		mov	a,m
		sub	c
		mov	e,a
		inx	h
		mov	a,m
		sbb	b
		jc	loc_190
		ora	e
		jnz	loc_191
		lda	lrec_bcnt	; last record byte count
		mov	c,a
		lhld	fd_ptr
		lxi	d,27h
		dad	d
		mov	a,m
		sub	c
		jnc	loc_191
		mov	m,c
		jmp	loc_191

loc_190:	mov	m,b
		dcx	h
		mov	m,c
		lhld	fd_ptr
		lxi	d,27h
		dad	d
		lda	lrec_bcnt	; last record byte count
		mov	m,a
		jmp	loc_191

loc_188:	lda	byte_103
		ora	a
		mov	b,a
		jnz	loc_183
		lhld	word_65
		mov	a,l
		ora	h
		jz	loc_191
		dcx	h
		shld	word_65
		lhld	word_81
		mov	c,m
		inx	h
		shld	word_81
		call	dev_write
		jmp	loc_188

loc_191:	mvi	b,0		; no error
loc_183:	lhld	pgm_de
		mov	a,b
		call	store_word	; store the return code
		jmp	idos_exit

;----------------------------------------------------------------------

fn_seek:
		call	dma80		; set dma to default 0080H
		xra	a
		sta	byte_192
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		sta	fileno
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		sta	seek_mode
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	word_193	; block ptr
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		shld	word_194	; block value
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	word_195	; byte ptr
		mov	e,m
		inx	h
		mov	d,m
		xchg	
		shld	word_196	; byte value
		lda	seek_mode
		dcr	a
		cpi	3
		jnc	loc_197
		lxi	h,word_196	; byte value
		mov	a,m
		ani	7Fh
		mov	c,a
		mov	a,m
		rlc	
		ani	1
		mov	e,a
		mov	m,c
		inx	h
		mov	a,m
		mvi	m,0
		add	a
		push	psw
		ora	e
		mov	e,a
		pop	psw
		rlc	
		ani	1
		mov	d,a
		lhld	word_194	; block value
		dad	d
		shld	word_194
loc_197:	lda	fileno
		cpi	8
		mvi	b,2		; error: bad file number
		jnc	loc_198
		lxi	h,fd_tab
		call	add_hla
		mov	a,m
		mov	c,a
		ani	3		; mask access bits
		jz	loc_198
		mvi	b,31		; error code
		cpi	2
		jz	loc_198
		sta	byte_70
		mov	a,c
		add	a
		mvi	b,2
		jnc	loc_198
		mov	a,c
		rar	
		rar	
		ani	1Fh
		call	find_fd
		shld	fd_ptr		; fd
		call	loc_68
		lda	seek_mode
		ora	a
		jnz	loc_199
		push	h
		lhld	word_195	; byte ptr
		mov	m,e
		inx	h
		mov	m,d
		pop	d
		lhld	word_193	; block ptr
		mov	m,e
		inx	h
		mov	m,d
		jmp	loc_200

loc_199:	dcr	a
		jnz	loc_201
		push	h
		lxi	h,word_196
		mov	a,e
		sub	m
		pop	b
		jp	loc_202
		dcx	h
		adi	80h
loc_202:	mov	e,a
		lxi	h,word_194
		mov	a,c
		sub	m
		mov	c,a
		inx	h
		mov	a,b
		sbb	m
		mov	h,a
		mov	l,c
		jp	loc_203
		mvi	a,14h
		sta	byte_192
		lxi	h,0
		mov	e,l
		jmp	loc_203

loc_201:	dcr	a
		jnz	loc_204
		lhld	word_196
		xchg	
		lxi	h,word_194
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		jmp	loc_203

loc_204:	dcr	a
		jnz	loc_205
		push	h
		lxi	h,word_196
		mov	a,e
		add	m
		pop	h
		cpi	80h
		jc	loc_206
		inx	h
		sui	80h
loc_206:	mov	e,a
		mov	c,l
		mov	b,h
		lxi	h,word_194
		mov	a,m
		add	c
		mov	c,a
		inx	h
		mov	a,m
		adc	b
		mov	h,a
		mov	l,c
		jmp	loc_203

loc_205:	dcr	a
		mvi	b,27		; error code
		jnz	loc_198
		lhld	fd_ptr
		xchg	
		lxi	h,25h
		dad	d
		mov	c,m
		inx	h
		mov	b,m
		lxi	h,27h
		dad	d
		mov	e,m
		mvi	d,0
		mov	h,b
		mov	l,c
loc_203:	push	d
		push	h
		lhld	fd_ptr
		xchg	
		lxi	h,25h
		dad	d
		shld	word_193
		lxi	h,27h
		dad	d
		shld	word_195
		pop	h
		pop	d
		lda	byte_70
		cpi	1
		jz	loc_207
		jmp	loc_208

;----------------------------------------------------------------------

loc_209:
		lxi	h,21h
		dad	d
		mov	a,m
		ora	a
		rz	
		lxi	h,23h
		dad	d
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		call	loc_77		; write record, HL = buffer
		rz	
		mvi	b,7
		jmp	loc_198

;----------------------------------------------------------------------

loc_210:
		push	h
		lhld	word_193
		mov	a,m
		inx	h
		mov	b,m
		pop	h
		sub	l
		mov	c,a
		mov	a,b
		sbb	h
		rc	
		ora	c
		rnz	
		push	h
		lhld	word_195
		mov	a,m
		pop	h
		sub	e
		ret	

;----------------------------------------------------------------------

loc_208:
		call	loc_73
		push	h
		push	d
		lhld	fd_ptr
		xchg	
		lxi	h,0Ch
		dad	d
		mov	a,b
		cmp	m
		jnz	loc_211
		lxi	h,20h
		dad	d
		mov	a,c
		cmp	m
		jnz	loc_212
		lxi	h,21h
		dad	d
		pop	d
		mov	m,e
		pop	h
		jmp	loc_200

;----------------------------------------------------------------------

loc_212:
		call	loc_209
		jmp	loc_213

;----------------------------------------------------------------------

loc_211:
		call	loc_209
		call	closef
		mvi	b,9
		jz	loc_198
loc_213:	pop	d
		pop	h
		call	loc_210
		jnc	loc_214
		push	d
		push	h
		lhld	word_195
		mov	e,m
		mvi	d,0
		lhld	word_193
		mov	a,m
		inx	h
		mov	h,m
		mov	l,a
		call	loc_73
		lhld	fd_ptr
		shld	word_105
		xchg	
		lxi	h,0Ch
		dad	d
		mov	a,b
		cmp	m
		jz	loc_215
		mov	m,a
		push	b
		push	d
		call	openf
		mvi	b,19		; error code
		jz	loc_198
		pop	d
		pop	b
loc_215:	lxi	h,20h
		dad	d
		mov	m,c
		push	h
		push	d
		lxi	h,23h
		dad	d
		mov	a,m
		inx	h
		mov	d,m
		mov	e,a
		call	isetdma
		pop	d
		push	d
		call	readf
		pop	d
		pop	h
		ora	a
		jnz	loc_216
		dcr	m
loc_216:	xra	a
		sta	byte_103
		lhld	word_195
		mov	c,m
		lxi	h,21h
		dad	d
		mov	m,c
		pop	h
		pop	d
loc_217:	call	loc_210
		jnc	loc_218
		push	d
		push	h
		mvi	c,0
		call	loc_104
		pop	h
		pop	d
		lda	byte_103
		sta	byte_192
		ora	a
		jz	loc_217
loc_218:	jmp	loc_200

;----------------------------------------------------------------------

loc_214:
		call	loc_73
		push	d
		push	h
		lhld	fd_ptr
		xchg	
		lxi	h,0Ch
		dad	d
		mov	a,b
		cmp	m
		jz	loc_219
		mov	m,a
		push	b
		push	d
		push	d
		lxi	d,80h
		call	isetdma
		pop	d
		call	openf
		mvi	b,19		; error code
		jz	loc_198
		pop	d
		pop	b
loc_219:	lxi	h,20h
		dad	d
		mov	m,c
		lxi	h,23h
		dad	d
		push	d
		mov	e,m
		inx	h
		mov	d,m
		call	loc_74
		pop	d
		lxi	h,21h
		dad	d
		pop	b
		pop	d
		mov	m,e
		jmp	loc_200

;----------------------------------------------------------------------

loc_220:
		push	d
		lxi	h,23h		; fd bfr addr
		dad	d
		mov	e,m
		inx	h
		mov	d,m
		call	loc_76		; read record, DE = buffer
		pop	d
		ret	

;----------------------------------------------------------------------

loc_207:
		xchg	
		push	h
		lhld	word_193
		mov	a,m
		inx	h
		mov	b,m
		sub	e
		mov	c,a
		mov	a,b
		sbb	d
		pop	h
		xchg	
		mvi	b,33		; error code
		jc	loc_198
		ora	c
		jnz	loc_221
		push	h
		lhld	word_195
		mov	a,m
		pop	h
		sub	e
		jc	loc_198
loc_221:	call	loc_73
		lxi	h,lrec_bcnt	; last record byte count
		mov	m,e
		lhld	fd_ptr
		xchg	
		lxi	h,0Ch		; fcb ex
		dad	d
		mov	a,b
		cmp	m
		jz	loc_222
		push	b
		mov	m,a
		push	d
		call	openf
		inr	a
		mvi	b,19		; error code
		jz	loc_198
		pop	d
		pop	b
		lxi	h,20h		; fcb cr
		dad	d
		mvi	m,0
		lxi	h,21h
		dad	d
		mvi	m,80h
loc_222:	lxi	h,21h
		dad	d
		mov	a,m
		cpi	80h
		jc	loc_223
		lxi	h,20h
		dad	d
		mov	a,c
		cmp	m
		jnz	loc_224
		call	loc_220
		jmp	loc_225

loc_223:	lxi	h,20h
		dad	d
		mov	a,c
		inr	a
		cmp	m
		jz	loc_225
loc_224:	mov	m,c
		call	loc_220		; read record
loc_225:	lxi	h,21h
		dad	d
		lda	lrec_bcnt	; last record byte count
		mov	m,a
loc_200:	mvi	b,0
loc_198:	mov	a,b
		lxi	h,byte_192
		ora	m
		lhld	pgm_de
		call	store_word	; store return value
		call	dma80		; set dma to default 0080H
		jmp	idos_exit

;----------------------------------------------------------------------

fn_load:				; set dma to default 0080H
		call	dma80
		call	get_filename
		call	next_arg	; get word pointed by pgm_de
		xchg	
		shld	word_55
		call	fillfcb0
		mvi	b,4		; error code
		jnz	loc_226
		call	openc		; open comfcb
		mvi	b,13		; error code
		jz	loc_226
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		cpi	2
		jnc	loc_226
		push	d
		call	next_arg	; get word pointed by pgm_de
		push	d
		call	load
		mvi	b,15		; error code
		jz	loc_227
		call	dma80		; set dma to default 0080H
		pop	d
		pop	b
		mov	a,c
		ora	a
		jnz	loc_228
		lhld	word_4
		xchg	
		mov	m,e
		inx	h
		mov	m,d
		mov	b,a
		jmp	loc_226

loc_228:	lhld	word_4
		mov	a,h
		ora	l
		jnz	loc_229
		lhld	word_50
loc_229:	push	h
		lxi	h,0
		dad	sp
		shld	pgm_sp
		jmp	idos_exit

loc_226:	lhld	pgm_de
		mov	a,b
		call	store_word
		jmp	idos_exit

loc_227:	jmp	comerr

;----------------------------------------------------------------------

fn_rename:
		call	dma80		; set dma to default 0080H
		call	get_filename
		call	fillfcb0
		mvi	b,4		; error code
		jnz	loc_230
		lda	comfcb+1
		cpi	20h
		mvi	b,4		; error code
		jz	loc_230
		call	get_filename
		mvi	a,10h
		call	fillfcb
		mvi	b,4		; error code
		jnz	loc_231
		lxi	d,comfcb+10h
		call	srchfst
		mvi	b,11		; error code
		jnz	loc_231
		call	srchcom
		mvi	b,13		; error code
		jz	loc_231
		lxi	h,comfcb
		lda	sdisk
		cmp	m
		mvi	b,4		; error code
		jnz	loc_230
		xchg	
		call	irename
		mvi	b,0		; no error
		jmp	loc_231

loc_230:	call	next_arg	; get word pointed by pgm_de
loc_231:	lhld	pgm_de
		mov	a,b
		call	store_word
		jmp	idos_exit

;----------------------------------------------------------------------

fn_console:
		jmp	idos_exit

;----------------------------------------------------------------------

fn_exit:
		lxi	h,fd_tab
		lxi	b,8		; close all open files
close_all:
		mov	a,b
		cpi	2
		jc	dont_close	; don't close :CI: and :CO:
		mov	a,m
		ora	a
		jz	fn_ex_freefd
		push	h
		push	b
		mov	a,b
		call	loc_139
		cnz	loc_124
		pop	b
		pop	h
		mov	a,m
		ora	a
		jp	fn_ex_freefd
		mov	a,m
		mov	b,a
		rar	
		rar	
		ani	1Fh
		push	h
		push	b
		call	close_fd
		pop	b
		pop	h
fn_ex_freefd:	mvi	m,0		; mark entry in fd_tab as unused
dont_close:	inr	b
		inx	h
		dcr	c
		jnz	close_all
		call	dma80		; set dma to default 0080H
		jmp	cli		; transfer control to the command processor

;----------------------------------------------------------------------

fn_attrib:
		jmp	idos_exit

;----------------------------------------------------------------------

fn_rescan:
		call	next_arg	; get word pointed by pgm_de
		mov	a,e
		call	loc_139
		mvi	b,21		; error code
		jz	loc_232
		mvi	a,0
		stax	d
		mov	b,a		; no error
loc_232:	lhld	pgm_de
		mov	a,b
		call	store_word	; store the return value
		jmp	idos_exit

;----------------------------------------------------------------------

fn_error:
		lxi	h,2
		dad	d		; HL - ptr to return var, keep DE
		xra	a
		call	store_word	; return value = 0
		ldax	d		; get error code
error:		push	psw
		lxi	b,errmsg	; "error "
		call	ln_print
		pop	psw
		call	adec		; print error code
		lxi	d,atpcmsg	; "at user PC "
		call	putstr
		lhld	pgm_sp
		inx	h
		mov	a,m		; print program PC from stack
		push	h
		call	ahex
		pop	h
		dcx	h
		mov	a,m
		call	ahex
		call	crlf
		jmp	idos_exit

;----------------------------------------------------------------------

errmsg:		db	'ERROR $'
atpcmsg:	db	', AT USER PC $'

;----------------------------------------------------------------------

fn_whocon:				; not implemented
		jmp	idos_exit

;----------------------------------------------------------------------

fn_spath:
		call	get_filename
		mvi	a,1
		call	loc_37
		jz	loc_233
		inr	a
		jz	loc_233
		sui	2
		mvi	b,1
		jmp	loc_234

loc_233:	lxi	h,combuf
		shld	comaddr
		mvi	a,2
		call	loc_37
		jz	loc_235
		inr	a
		jz	loc_236
		adi	7
		mvi	b,0
loc_234:	lxi	h,byte_43
		call	add_hla
		mov	a,m
		call	next_arg	; get word pointed by pgm_de
		push	d
		stax	d
		xchg	
		xra	a
		mvi	c,9
loc_237:	inx	h
		mov	m,a
		dcr	c
		jnz	loc_237
		inx	h
		mov	m,b
		inx	h
		mvi	m,0FFh
		jmp	loc_238

loc_235:	call	fillfcb0
		lda	comfcb+1
		cpi	' '
		jz	loc_236
		lda	comfcb
		dcr	a
		jp	loc_239
		lda	cur_disk
loc_239:	call	next_arg	; get word pointed by pgm_de
		stax	d
		push	d
		mov	b,a
		mvi	c,6
		lxi	h,comfcb
loc_240:	inx	d
		inx	h
		mov	a,m
		cpi	' '
		jnz	loc_241
		xra	a
loc_241:	stax	d
		dcr	c
		jnz	loc_240
		lxi	h,comfcb+8
		mvi	c,3
loc_242:	inx	d
		inx	h
		mov	a,m
		cpi	' '
		jnz	loc_243
		xra	a
loc_243:	stax	d
		dcr	c
		jnz	loc_242
		xchg	
		inx	h
		mvi	m,3
		inx	h
		mvi	m,1
		mov	a,b
		cpi	10h
		jc	loc_238
		mvi	m,0
loc_238:	pop	h
		lda	tr_level
		ora	a
		jz	loc_244
		shld	dmp_from
		lxi	d,11
		dad	d
		shld	dmp_to
		call	dump_mem
		call	crlf
loc_244:	xra	a
		jmp	loc_245

;----------------------------------------------------------------------

loc_236:
		mvi	a,4
		call	next_arg	; get word pointed by pgm_de
loc_245:	lhld	pgm_de
		call	store_word
		jmp	idos_exit

idos_exit:	call	sub_27
		call	setup_40h
		lhld	pgm_sp
		sphl	
		ret	

;----------------------------------------------------------------------

		dw	0,0,0,0,0,0,0,0
		dw	0,0,0,0,0,0,0,0
		dw	0,0,0,0,0,0,0,0

stack		equ	$

save_40:	db	0,0,0		; save here the original contents of the jmp vector at 0040H

submit:		db	0		; submit file present flag

subfcb:		db	0
		db	'$$$     SUB'
		db	0
		db	0
submod:		db	0  
subrc:		db	0
		db	0,0,0,0		; ds 16 (fcb block map)
		db	0,0,0,0
		db	0,0,0,0
		db	0,0,0,0
subcr:		db	0

comfcb:		db	0,0,0,0,0
		db	0,0,0,0,0
		db	0,0,0,0,0
		db	0,0,0,0,0
		db	0,0,0,0,0
		db	0,0,0,0,0
		db	0,0
comrec:		db	0		; comfcb rc byte
comrnd:		dw	0		; comfcb r0,r1,r2
		db	0

rbuff:		db	126
buflen:		db	0
combuf:		db	126,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7Eh,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

comaddr:	dw	0
staddr:		dw	0
byte_23:	db	0
byte_62:	db	0
word_24:	dw	0,0,0,0,0
dmp_from:	dw	0
dmp_to:		dw	0
word_15:	dw	0
word_17:	dw	0
i_dcnt:		db	0		; bdos return code
cur_disk:	db	0		; current disk
sdisk:		db	0		; disk code, for cli means that disk was
					; explicitely specified on command line
bptr:		dw	0		; buffer pointer
save_sp:	dw	0		; saved SP for some r/w routines
word_55:	dw	0
word_50:	dw	0
pgm_sp:		dw	0
pgm_de:		dw	0
pgm_c:		db	0
old_iobyte:	db	0
byte_70:	db	0
fileno:		db	0		; current fileno value, or fileno_ptr (fn_open)
seek_mode:	db	0		; seek mode or hi(fileno_ptr)
fd_tab:		db	0,0,0,0,0,0,0,0
byte_109:	db	0,0,0,0,0,0,0,0
word_141:	dw	0,0,0,0,0,0,0,0
unk_122:	db	0  
unk_170:	db	0  
unk_116:	db	0  

unk_119:	ds	128

word_81:	dw	0
word_65:	dw	0
word_67:	dw	0
fd_ptr:		dw	0		; pointer to fd (fcb)
word_105:	dw	0
word_168:	dw	0
byte_143:	db	0
byte_146:	db	0
byte_145:	db	0
byte_103:	db	0
word_111:	dw	0
		db	0  
byte_82:	db	0
		db	0  
		db	0  
		db	0  
num_recs:	dw	0
lrec_bcnt:	db	0		; last record byte count
word_193:	dw	0
word_195:	dw	0
word_194:	dw	0
word_196:	dw	0
byte_192:	db	0
f_dscrptrs:	db	0		; space for 6 file desciptors of 40 bytes each
					; = 240 (F0H) bytes total, this overwrites main
					; which is not longer needed.
		db	0  
		db	0  
		db	0  

;----------------------------------------------------------------------

main:
		lhld	wboot+1
		dcx	h
		dcx	h
		dcx	h		; HL = base of BIOS
		lxi	d,0F700h
		mov	a,l
		sub	e
		mov	a,h
		sbb	d		; BIOS base > F700 ?
		jc	main1		; yes -> main1
		push	h
		lxi	h,3
		dad	d
		shld	wboot+1
		pop	h
		mvi	c,33h
biosv_move:	mov	a,m
		stax	d
		inx	h
		inx	d
		dcr	c
		jnz	biosv_move
main1:		lxi	b,80h
		lxi	h,loc_57	; 3100H
		lxi	d,0F800h
mdsv_move:	mov	a,c
		ora	b
		jz	isx_start
		dcx	b
		mov	a,m
		stax	d
		inx	h
		inx	d
		jmp	mdsv_move

;----------------------------------------------------------------------

;		ds	199

;----------------------------------------------------------------------

		org	3100h

loc_57:
		jmp	0F826h		; F800 - error
		jmp	0F829h		; F803 - console input
		jmp	0F82Fh		; F806 - error
		jmp	0F832h		; F809 - console output
		jmp	0F838h		; F80C - punch output
		jmp	0F83Eh		; F80F - list output
		jmp	0F844h		; F812 - console status
		jmp	0F84Ah		; F815 - get i/o byte
		jmp	0F84Fh		; F818 - set i/o byte
		jmp	0F854h		; F81B - get mem top
		jmp	0F85Bh		; F81E - error
		jmp	0F85Eh		; F821 - error

;----------------------------------------------------------------------

		db	0  
		db	0  

;----------------------------------------------------------------------

;0F826h:				; error
		jmp	0F86Ah

;0F829h:				; console input
		lxi	h,6
		jmp	0F878h

;0F82Fh:				; error
		jmp	0F86Ah

;0F832h:				; console output
		lxi	h,9
		jmp	0F878h

;0F838h:				; punch output
		lxi	h,0Fh
		jmp	0F878h

;0F83Eh:				; list output
		lxi	h,0Ch
		jmp	0F878h

;0F844h:				; console status
		lxi	h,3
		jmp	0F878h

;0F84Ah:				; get I/O byte
		lxi	h,3
		mov	m,c
		ret	

;0F84Fh:				; set I/O byte
		lxi	h,3
		mov	a,m
		ret	

;0F854h:				; get mem top
		lhld	bdos+1		; 0006H
		dcx	h
		mov	a,l
		mov	b,h
		ret	

;0F85Bh:				; error
		jmp	0F86Ah

;0F85Eh:				; error
		jmp	0F86Ah

;0F861h:
		lhld	word_3		; 0107H
		mov	a,l
		ora	h
		jz	0F86Ah
		rst	7
;0F86Ah:
		mvi	c,0Ch		; isis error
		lxi	d,0F872h
		jmp	vec_40		; 0040H

;0F872h:
		dw	255
		dw	0F876h
;0F876h:
		dw	0

;0F878h:
		xchg	
		lhld	wboot+1
		dad	d
		pchl	

;----------------------------------------------------------------------

		db	0  
		db	0  
		db	0  

		end	start

