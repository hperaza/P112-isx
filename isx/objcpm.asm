; Disassembly of OBJCPM.COM 
; (an ISX utility to convert ISIS executables to CP/M .COM files)

		cseg

wboot		equ	0
bdos		equ	5
cpm_fcb		equ	5Ch

cpm_bfr		equ	80h
cmd_str		equ	81h

;----------------------------------------------------------------------

start:		jmp	main

copyrt:		db	' COPYRIGHT (C) 1977,1978 DIGITAL RESEARCH '


main:		lxi	h,0
		dad	sp
		shld	cpm_sp
		lxi	sp,stack
		mvi	c,8
		lxi	d,out_fn
		lxi	h,cpm_fcb+11h	; fcb2 name
		mov	a,m
		cpi	'$'		; option?
		jnz	loc_6
		mvi	m,' '
loc_6:		mov	a,m
		cpi	' '
		mvi	a,0FFh
		jz	loc_7
		xra	a
loc_7:		sta	byte_8		; output file not specified flag
cp_fname:	mov	a,m
		stax	d
		inx	h
		inx	d
		dcr	c
		jnz	cp_fname
		call	parse_cmd
		lda	cmd_p		; printer echo flag
		ora	a
		jz	loc_9
		lda	cmd_s		; produce .SYM file flag
		lxi	h,cmd_l		; produce .LIN file flag
		ora	m
		jz	loc_9
		mvi	m,0
loc_9:		jmp	loc_10

;----------------------------------------------------------------------

copy:		mov	a,m
		stax	d
		inx	h
		inx	d
		dcr	c
		jnz	copy
		ret	

;----------------------------------------------------------------------

loc_10:		lxi	h,cpm_fcb
		lxi	d,inp_fcb
		mvi	c,12
		call	copy
		jmp	open_inp0

;----------------------------------------------------------------------

inp_fcb:	db	0,'           '
byte_11:	db	0		; inp_fcb ex
		db	0,0,0
		ds	16
byte_12:	db	0Fh		; inp_fcb cr

i_bfr:		dw	inp_bfr
word_4:		dw	800h
word_1:		ds	2

;----------------------------------------------------------------------

open_inp0:
		jmp	open_inp

;----------------------------------------------------------------------

rd_inp:
		lhld	word_4
		xchg	
		lhld	word_1
		mov	a,l
		sub	e
		mov	a,h
		sbb	d
		jc	loc_13
		lxi	h,0
		shld	word_1
loc_5:		xchg	
		lhld	word_4
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	loc_3
		lhld	i_bfr
		dad	d
		xchg	
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	d,inp_fcb
		mvi	c,14h		; read
		call	bdos
		ora	a
		jnz	loc_2
		lxi	d,80h
		lhld	word_1
		dad	d
		shld	word_1
		jmp	loc_5

loc_2:		lhld	word_1
		shld	word_4
loc_3:		lxi	d,cpm_bfr
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	h,0
		shld	word_1
loc_13:		xchg	
		lhld	i_bfr
		dad	d
		xchg	
		lhld	word_4
		mov	a,l
		ora	h
		mvi	a,1Ah
		rz	
		ldax	d
		lhld	word_1
		inx	h
		shld	word_1
		ret	

;----------------------------------------------------------------------

open_inp:
		xra	a
		sta	byte_11		; inp_fcb ex
		sta	byte_12		; inp_fcb cr
		lxi	h,800h
		shld	word_4
		shld	word_1
		mvi	c,0Fh		; open file
		lxi	d,inp_fcb
		call	bdos
		inr	a
		jnz	open_ok
		mvi	c,9		; print string
		lxi	d,no_obj
		call	bdos
		jmp	wboot

no_obj:		db	0Dh,0Ah,'NO OBJECT FILE$'

;----------------------------------------------------------------------

open_ok:
		lda	cmd_s		; produce .SYM file flag
		ora	a
		jz	sopen_ok
		lxi	h,cpm_fcb
		lxi	d,sym_fcb
		mvi	c,9
		call	copy
		jmp	open_sym0

;----------------------------------------------------------------------

sym_fcb:	db	0,'        SYM'
byte_14:	db	0		; sym_fcb ex
		db	0,0,0
		ds	16
byte_15:	db	0FEh		; sym_fcb cr

s_bfr:		dw	sym_bfr
word_16:	dw	800h
word_17:	ds	2

;----------------------------------------------------------------------

open_sym0:
		jmp	open_sym

;----------------------------------------------------------------------

wr_sym:
		push	psw
		lhld	word_16
		xchg	
		lhld	word_17
		mov	a,l
		sub	e
		mov	a,h
		sbb	d
		jc	loc_18
		lxi	h,0
		shld	word_17
loc_19:		xchg	
		lhld	word_16
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	loc_20
		lhld	s_bfr
		dad	d
		xchg	
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	d,sym_fcb
		mvi	c,15h		; write
		call	bdos
		ora	a
		jnz	loc_21
		lxi	d,80h
		lhld	word_17
		dad	d
		shld	word_17
		jmp	loc_19

loc_21:		mvi	c,9		; print string
		lxi	d,d_full
		call	bdos
		pop	psw
		jmp	wboot

d_full:		db	0Dh,0Ah,'DISK FULL: SYM$'

;----------------------------------------------------------------------

loc_20:
		lxi	d,cpm_bfr
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	h,0
		shld	word_17
loc_18:		xchg	
		lhld	s_bfr
		dad	d
		xchg	
		pop	psw
		stax	d
		lhld	word_17
		inx	h
		shld	word_17
		ret	

;----------------------------------------------------------------------

open_sym:
		xra	a
		sta	byte_14		; sym_fcb ex
		sta	byte_15		; sym_fcb cr
		lxi	h,800h
		shld	word_16
		lxi	h,0
		shld	word_17
		mvi	c,13h		; delete file
		lxi	d,sym_fcb
		call	bdos
		mvi	c,16h		; make file
		lxi	d,sym_fcb
		call	bdos
		inr	a
		jnz	sopen_ok
		mvi	c,9		; print string
		lxi	d,dir_spc
		call	bdos
		jmp	wboot

dir_spc:	db	0Dh,0Ah,'NO DIR SPACE: SYM$'

;----------------------------------------------------------------------

sopen_ok:
		lda	cmd_l		; produce .LIN file flag
		ora	a
		jz	lopen_ok
		lxi	h,cpm_fcb
		lxi	d,lin_fcb
		mvi	c,9
		call	copy
		jmp	open_lin0

;----------------------------------------------------------------------

lin_fcb:	db	0,'        LIN'
byte_22:	db	0		; lin_fcb ex
		db	0,0,0
		ds	16
byte_23:	db	0		; lin_fcb cr

l_bfr:		dw	lin_bfr
word_24:	dw	800h
word_25:	ds	2

;----------------------------------------------------------------------

open_lin0:
		jmp	open_lin

;----------------------------------------------------------------------

wr_lin:
		push	psw
		lhld	word_24
		xchg	
		lhld	word_25
		mov	a,l
		sub	e
		mov	a,h
		sbb	d
		jc	loc_26
		lxi	h,0
		shld	word_25
loc_27:		xchg	
		lhld	word_24
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	loc_28
		lhld	l_bfr
		dad	d
		xchg	
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	d,lin_fcb
		mvi	c,15h		; write
		call	bdos
		ora	a
		jnz	err_dlfull
		lxi	d,80h		; rec size
		lhld	word_25
		dad	d
		shld	word_25
		jmp	loc_27

err_dlfull:	mvi	c,9		; print string
		lxi	d,dl_full
		call	bdos
		pop	psw
		jmp	wboot

dl_full:	db	0Dh,0Ah,'DISK FULL: LIN$'

;----------------------------------------------------------------------

loc_28:
		lxi	d,cpm_bfr
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	h,0
		shld	word_25
loc_26:		xchg	
		lhld	l_bfr
		dad	d
		xchg	
		pop	psw
		stax	d
		lhld	word_25
		inx	h
		shld	word_25
		ret	

;----------------------------------------------------------------------

open_lin:
		xra	a
		sta	byte_22		; lin_fcb ex
		sta	byte_23		; lin_fcb cr
		lxi	h,800h
		shld	word_24
		lxi	h,0
		shld	word_25
		mvi	c,13h		; delete file
		lxi	d,lin_fcb
		call	bdos
		mvi	c,16h		; make file
		lxi	d,lin_fcb
		call	bdos
		inr	a
		jnz	lopen_ok
		mvi	c,9		; print string
		lxi	d,ldir_sp
		call	bdos
		jmp	wboot

ldir_sp:	db	0Dh,0Ah,'NO DIR SPACE: LIN$'

;----------------------------------------------------------------------

lopen_ok:
		lda	cmd_c		; produce .COM file flag
		ora	a
		jz	copen_ok
		lxi	h,cpm_fcb
		lxi	d,com_fcb
		mvi	c,9
		call	copy
		jmp	open_com0

;----------------------------------------------------------------------

com_fcb:	db	0,'        COM'
byte_29:	db	0		; com_fcb ex
		db	0,0,0
		ds	16
byte_30:	db	0		; com_fcb cr

c_bfr:		dw	com_bfr
word_31:	dw	800h
word_32:	ds	2

;----------------------------------------------------------------------

open_com0:
		jmp	open_com

;----------------------------------------------------------------------

wr_com:
		push	psw
		lhld	word_31
		xchg	
		lhld	word_32
		mov	a,l
		sub	e
		mov	a,h
		sbb	d		; (0498) > (049A) ?
		jc	loc_33		; yes ->
		lxi	h,0
		shld	word_32
loc_34:		xchg	
		lhld	word_31
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		jnc	loc_35
		lhld	c_bfr
		dad	d
		xchg	
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	d,com_fcb
		mvi	c,15h		; write
		call	bdos
		ora	a
		jnz	err_dcfull
		lxi	d,80h
		lhld	word_32
		dad	d
		shld	word_32
		jmp	loc_34

err_dcfull:	mvi	c,9		; print string
		lxi	d,dc_full
		call	bdos
		pop	psw
		jmp	wboot

dc_full:	db	0Dh,0Ah,'DISK FULL: COM$'

;----------------------------------------------------------------------

loc_35:
		lxi	d,cpm_bfr
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	h,0
		shld	word_32
loc_33:		xchg	
		lhld	c_bfr
		dad	d
		xchg	
		pop	psw
		stax	d
		lhld	word_32
		inx	h
		shld	word_32
		ret	

;----------------------------------------------------------------------

open_com:
		xra	a
		sta	byte_29		; com_fcb ex
		sta	byte_30		; com_fcb cr
		lxi	h,800h
		shld	word_31
		lxi	h,0
		shld	word_32
		mvi	c,13h		; delete file
		lxi	d,com_fcb
		call	bdos
		mvi	c,16h		; make file
		lxi	d,com_fcb
		call	bdos
		inr	a
		jnz	copen_ok
		mvi	c,9		; print string
		lxi	d,cdir_sp
		call	bdos
		jmp	wboot

cdir_sp:	db	0Dh,0Ah,'NO DIR SPACE: COM$'

;----------------------------------------------------------------------

copen_ok:
		xra	a
		sta	byte_36
		sta	lst_x		; current LST column
		sta	byte_37
		sta	byte_38
		sta	byte_39
		sta	byte_40
		lxi	h,0
		shld	nxtaddr
		shld	baddr
		shld	staddr
		call	load
		push	psw
		xra	a		; write to .SYM
		sta	out_redir
		call	crlf
		mvi	a,2		; write to .LIN
		sta	out_redir
		call	crlf
		mvi	a,1		; write to console (default)
		sta	out_redir
		pop	psw
		lxi	h,bad_ldm
		cz	put_str
		lda	cmd_s		; produce .SYM file flag
		ora	a
		jz	close_lin
close_sym:
		lhld	word_17
		mov	a,l
		ani	7Fh
		jnz	loc_41
		shld	word_16
loc_41:		mvi	a,1Ah
		push	psw
		call	wr_sym		; fill the end of the sector with ^Z
		pop	psw
		jnz	close_sym
		mvi	c,10h		; close file
		lxi	d,sym_fcb
		call	bdos
		inr	a
		jnz	close_lin
		mvi	c,9		; print string
		lxi	d,sym_cls
		call	bdos
		jmp	close_lin

sym_cls:	db	0Dh,0Ah,'CANNOT CLOSE SYM$'

;----------------------------------------------------------------------

close_lin:
		lda	cmd_l		; produce .LIN file flag
		ora	a
		jz	close_com
loc_42:		lhld	word_25
		mov	a,l
		ani	7Fh
		jnz	loc_43
		shld	word_24
loc_43:		mvi	a,1Ah
		push	psw
		call	wr_lin		; fill the remaining of the sector with ^Z
		pop	psw
		jnz	loc_42
		mvi	c,10h		; close file
		lxi	d,lin_fcb
		call	bdos
		inr	a
		jnz	close_com
		mvi	c,9		; print string
		lxi	d,lin_cls
		call	bdos
		jmp	close_com

lin_cls:	db	0Dh,0Ah,'CANNOT CLOSE LIN$'

;----------------------------------------------------------------------

close_com:
		lda	cmd_c		; produce .COM file flag
		ora	a
		jz	summary
loc_44:		lhld	word_32
		mov	a,l
		ani	7Fh
		jnz	loc_45
		shld	word_31
loc_45:		mvi	a,1Ah
		push	psw
		call	wr_com		; fill the end of the sector with ^Z
		pop	psw
		jnz	loc_44
		mvi	c,10h		; close file
		lxi	d,com_fcb
		call	bdos
		inr	a
		jnz	loc_46
		mvi	c,9		; print string
		lxi	d,com_cls
		call	bdos
		jmp	loc_46

com_cls:	db	0Dh,0Ah,'CANNOT CLOSE COM$'

;----------------------------------------------------------------------

loc_46:
		lhld	baddr		; base address
		mov	a,l
		cpi	3
		jnz	summary
		xra	a
		sta	byte_29		; com_fcb ex
		lxi	d,cpm_bfr
		mvi	c,1Ah		; set dma
		call	bdos
		lxi	d,com_fcb
		mvi	c,0Fh		; open file
		call	bdos
		inr	a
		jz	summary
		xra	a
		sta	byte_30		; com_fcb cr
		lxi	d,com_fcb
		mvi	c,14h		; read in the first sector of the .COM file
		call	bdos
		jnz	summary
		lhld	staddr
		shld	cmd_str		; cpm_bfr+1
		xra	a
		sta	byte_30		; com_fcb cr
		lxi	d,com_fcb
		mvi	c,15h		; write
		call	bdos
summary:
		call	crlf
		lhld	baddr
		call	hlhex		; print base address
		lxi	h,base_ad
		call	put_str
		call	crlf
		lhld	staddr
		call	hlhex		; print start address
		lxi	h,st_addr
		call	put_str
		call	crlf
		lhld	nxtaddr
		call	hlhex		; print next empty address
		lxi	h,nxt_ad
		call	put_str
		lhld	cpm_sp
		sphl	
		ret			; return to CP/M

;----------------------------------------------------------------------

parse_cmd:
		mvi	a,0FFh
		sta	cmd_c		; produce .COM file flag
		sta	cmd_l		; produce .LIN file flag
		sta	cmd_s		; produce .SYM file flag
		sta	cmd_b
		xra	a
		sta	cmd_p		; printer echo flag
		lxi	h,cpm_bfr
cmd_loop:	inx	h
		mov	a,m
		ora	a
		rz	
		cpi	'$'
		jnz	cmd_loop
		mvi	b,0FFh		; default is turn on the option
next_opt:	inx	h
		mov	a,m
		ora	a
		rz	
		cpi	'-'
		jnz	cmd_1
		mvi	b,0		; '-' : turn next option off
		jmp	next_opt

cmd_1:		cpi	'+'
		jnz	cmd_2
		mvi	b,0FFh		; '+' : turn option on
		jmp	next_opt

cmd_2:		lxi	d,cmd_c		; produce .COM file flag
		cpi	'C'
		jz	set_opt
		lxi	d,cmd_p		; printer echo flag
		cpi	'P'
		jz	set_opt
		lxi	d,cmd_l		; produce .LIN file flag
		cpi	'L'
		jz	set_opt
		lxi	d,cmd_b
		cpi	'B'
		jz	set_opt
		jmp	next_opt

set_opt:	mov	a,b
		stax	d
		jmp	next_opt

;----------------------------------------------------------------------

bad_ldm:	db	0Dh,0Ah,'BAD LOAD MODULE',0
base_ad:	db	' = BASE ADDRESS',0
st_addr:	db	' = STARTING ADDRESS',0
nxt_ad:		db	' = NEXT EMPTY ADDRESS',0

;----------------------------------------------------------------------

out_char:
		push	psw
		lda	cmd_p		; printer echo flag
		ora	a
		jz	out3
		pop	psw
		push	psw
		cpi	9
		jnz	out1
outtab:		mvi	a,' '		; expand tabs to spaces on printer
		push	psw
		mvi	c,5		; list output
		mov	e,a
		call	bdos
		pop	psw
		lxi	h,lst_x		; current LST column
		inr	m
		mov	a,m
		ani	7
		jnz	outtab
		jmp	out3

out1:		cpi	0Ah		; lf
		jnz	out2
		lxi	h,lst_x		; current LST column
		mvi	m,0FFh		; -1
out2:		push	psw
		mvi	c,5		; list output
		mov	e,a
		call	bdos
		pop	psw
		lxi	h,lst_x		; current LST column
		inr	m
out3:		lda	out_redir	; output redirection flag
		ora	a
		jnz	out4
		lda	cmd_s		; produce .SYM file flag
		ora	a
		jz	out_ret
		pop	psw
		call	wr_sym
		ret	

out4:		dcr	a
		jnz	out5
		pop	psw
		push	psw
		mvi	c,2		; console output
		mov	e,a
		call	bdos
		pop	psw
		ret	

out5:		lda	cmd_l		; produce .LIN file flag
		ora	a
		jz	out_ret
		pop	psw
		call	wr_lin
		ret	

out_ret:	pop	psw
		ret	

;----------------------------------------------------------------------

outchr_a:
		push	b
		push	d
		push	h
		push	psw
		cpi	9
		jnz	no_tab
		lxi	h,tab_cnt
		inr	m
		pop	psw
		jmp	pop_n_ret

no_tab:		cpi	' '		; ascii ?
		jc	no_ascii
type_tabs:	lda	tab_cnt		; yes, output the stored tabs...
		ora	a
		jz	type_char
		dcr	a
		sta	tab_cnt
		mvi	a,9
		call	out_char
		jmp	type_tabs

type_char:	pop	psw
		call	out_char	; ...then output the character
		jmp	pop_n_ret

no_ascii:	xra	a
		sta	tab_cnt
		pop	psw
		call	out_char
pop_n_ret:	pop	h
		pop	d
		pop	b
		ret	

;----------------------------------------------------------------------

put_tab:
		mvi	a,9
		call	outchr_a
		ret	

;----------------------------------------------------------------------

put_spc:
		mvi	a,' '
		call	outchr_a
		ret	

;----------------------------------------------------------------------

crlf:		mvi	a,0Dh		; cr
		call	outchr_a
		mvi	a,0Ah		; lf
		call	outchr_a
		ret	

put_str:	mov	a,m
		ora	a
		rz	
		push	h
		call	outchr_a
		pop	h
		inx	h
		jmp	put_str

;----------------------------------------------------------------------

hex_nibble:	ani	0Fh
		cpi	10
		jc	hex_nb1
		adi	37h
		jmp	outchr_a

hex_nb1:	adi	'0'
		jmp	outchr_a

; Display A as hexadecimal byte

ahex:		push	psw
		rrc	
		rrc	
		rrc	
		rrc	
		call	hex_nibble
		pop	psw
		call	hex_nibble
		ret	

; Display HL as hexadecimal word

hlhex:		push	h
		mov	a,h
		call	ahex
		pop	h
		mov	a,l
		call	ahex
		ret	

;----------------------------------------------------------------------

; Display HL as decimal value

hldec:		push	b
		push	d
		mvi	b,85h
		push	h		; save value
		lxi	h,div_tab	; decimal divisor table
hldec0:		mov	e,m
		inx	h
		mov	d,m		; divisor into DE
		inx	h
		xthl			; fetch value, save table ptr
		mvi	c,'0'
hldec1:		mov	a,l
		sub	e
		mov	l,a
		mov	a,h
		sbb	d
		mov	h,a
		jc	hldec2
		inr	c
		jmp	hldec1

hldec2:		dad	d
		mov	a,b
		ora	a
		jp	hldec3
		push	psw
		mov	a,c
		cpi	'0'
		jz	hldec4
		call	outchr_a
		pop	psw
		ani	7Fh
		mov	b,a
		jmp	hldec5

hldec3:		mov	a,c
		call	outchr_a
		jmp	hldec5

hldec4:		pop	psw
		ani	7Fh
		cpi	1
		jnz	hldec5
		mov	b,a
		jmp	hldec3

hldec5:		xthl	
		dcr	b
		jnz	hldec0
		pop	d
		pop	d
		pop	b
		ret	

div_tab:	dw	10000		; decimal divisor table
		dw	1000
		dw	100
		dw	10
		dw	1

;----------------------------------------------------------------------

is_de_1:				; returns Z if DE=0001
		mov	a,d
		ora	a
		rnz	
		mov	a,e
		dcr	a
		ret	

;----------------------------------------------------------------------

cmp_hlde:				; returns CY if HL > DE
		mov	a,e
		sub	l
		mov	a,d
		sbb	h
		ret

;----------------------------------------------------------------------

wr_com1:
		push	b
		push	d
		push	h
		call	wr_com
		pop	h
		pop	d
		pop	b
		ret	

;----------------------------------------------------------------------

get_byte:
		push	h
		push	d
		push	b
		call	rd_inp
		jz	load_err
		pop	b
		pop	d
		mov	l,a
		add	c		; update checksum
		mov	c,a
		dcx	d
		mov	a,d		; decr segment length counter
		ora	e
		mov	a,l
		pop	h
		ret	

;----------------------------------------------------------------------

get_word:				; read word into HL
		call	get_byte
		jz	load_err
		push	psw
		call	get_byte
		jz	load_err
		mov	h,a
		pop	psw
		mov	l,a
		ret

;----------------------------------------------------------------------

loc_47:		call	get_byte
		lxi	h,name_bfr
		cpi	16
		jc	loc_48
		mvi	a,16		; limit the size to 16 bytes
loc_48:		mov	m,a
		mov	b,a
loc_49:		call	get_byte
		inx	h
		mov	m,a
		dcr	b
		jnz	loc_49
		push	b
		push	d
		mvi	a,0		; write to .SYM
		sta	out_redir
		lda	byte_36
		ora	a
		cnz	crlf
		xra	a
		sta	byte_37
		lhld	nxtaddr		; write symbol table entry
		call	hlhex		; i.e. 'nnnn symname'
		call	put_spc
		lxi	h,name_bfr
		mov	b,m
pname1:		inx	h
		mov	a,m
		call	outchr_a
		dcr	b
		jnz	pname1
		call	crlf
		mvi	a,2		; write to .LIN
		sta	out_redir
		lda	byte_39
		ora	a
		cnz	crlf
		xra	a
		sta	byte_38
		lhld	nxtaddr
		call	hlhex
		call	put_spc
		lxi	h,name_bfr
		mov	b,m
pname2:		inx	h
		mov	a,m
		call	outchr_a
		dcr	b
		jnz	pname2
		mvi	a,'#'
		call	outchr_a
		call	crlf
		xra	a
		sta	byte_36
		lxi	h,out_fn
		mov	a,m
		cpi	' '
		jz	loc_50
		xra	a
		sta	byte_8		; output file not specified flag
		lxi	d,name_bfr
		ldax	d
		mov	b,a
cmp_name1:	inx	d
		ldax	d
		cmp	m
		jnz	loc_50
		inx	h
		dcr	b
		jnz	cmp_name1
		mvi	a,0FFh
		sta	byte_8		; output file not specified flag
loc_50:		pop	d
		pop	b
		ret	

;----------------------------------------------------------------------

load:		lxi	h,0
		shld	baddr
		shld	staddr
		shld	nxtaddr
		dad	sp
		shld	load_sp
next_rec:	mvi	c,0
		lxi	d,0FFFFh
		call	get_byte	; get object record type
		push	psw
		call	get_word	; get object record length
		xchg	
		pop	psw
		cpi	2		; 02 - module header
		jnz	load1
		call	loc_47
		jmp	skip_seg

load1:		cpi	10h		; 10 - block name?
		jnz	load2
		call	loc_47
		jmp	skip_seg

load2:		cpi	4		; 04 - module end
		jnz	load3
		call	get_byte
		cpi	1
		jnz	skip_seg
		call	get_byte
		call	get_word	; read word into HL
		shld	staddr
		jmp	skip_seg

load3:		cpi	18h		; 18 - exernal defs
		jnz	load4
		jmp	skip_seg

load4:		cpi	16h		; 16 - public symbols
		jnz	load5
		jmp	skip_seg

load5:		cpi	6		; 06 - content data
		jnz	load6
		lda	cmd_c		; produce .COM file flag
		ora	a
		jz	skip_seg
		call	get_byte
		ora	a
		jnz	load_err
		call	get_word	; read word into HL
		push	d
		push	h
		dad	d
		xchg	
		lhld	nxtaddr
		call	cmp_hlde	; CY if HL > DE
		jc	loc_51
		xchg	
		shld	nxtaddr
		xchg	
loc_51:		pop	d
		push	d
		lda	byte_40
		ora	a
		jnz	loc_52
		mvi	a,0FFh
		sta	byte_40
		lda	cmd_b
		ora	a
		jz	loc_52
		mov	a,e
		mov	l,e
		mov	h,d
		shld	baddr
		shld	word_53
		cpi	3
		jnz	loc_52
		mvi	a,0C3h		; jmp
		call	wr_com1
		xra	a
		call	wr_com1
		xra	a
		call	wr_com1
loc_52:		lhld	baddr
		call	cmp_hlde	; CY if HL > DE
		jnc	loc_54
		xchg	
		shld	baddr
loc_54:		lhld	word_53
		call	cmp_hlde	; CY if HL > DE
		jc	load_err
loc_55:		mov	a,e
		cmp	l
		jnz	loc_56
		mov	a,d
		cmp	h
		jz	loc_57
loc_56:		xra	a
		call	wr_com1
		inx	h
		jmp	loc_55

loc_57:		lhld	nxtaddr
		dcx	h
		shld	word_53
		pop	h
		pop	d
loc_58:		push	h
		call	get_byte
		pop	h
		jz	check_sum
		call	wr_com1
		inx	h
		jmp	loc_58

load6:		cpi	8		; 08 - fixup record
		jnz	load7
		lda	byte_8		; output file not specified flag
		ora	a
		jz	skip_seg
		mvi	a,2		; write to .LIN
		sta	out_redir
		lda	byte_38
		sta	tab_cnt
		call	get_byte
loc_59:		call	is_de_1		; returns Z if DE=0001
		jz	loc_60
		lxi	h,byte_39
		mov	a,m
		cpi	5
		jc	loc_61
		call	crlf
		mvi	m,0
loc_61:		inr	m
		call	get_word	; read word into HL
		call	hlhex
		call	put_spc
		call	get_word	; read word into HL
		push	h
		call	hldec
		call	put_tab
		pop	h
		mov	a,h
		ora	a
		jnz	loc_59
		mov	a,l
		cpi	64h		; 100
		jnc	loc_59
		call	put_tab
		jmp	loc_59

loc_60:		lda	tab_cnt
		sta	byte_38
		jmp	skip_seg

load7:		cpi	12h		; 12 - debug items
		jnz	load8
		lda	byte_8		; output file not specified flag
		ora	a
		jz	skip_seg
		xra	a		; write to .SYM
		sta	out_redir
		lda	byte_37
		sta	tab_cnt
		call	get_byte
loc_62:		call	is_de_1		; returns Z if DE=0001
		jz	loc_63
		call	get_word	; read word into HL
		push	h
		call	get_byte
		mov	b,a
		lda	byte_36
		ora	a
		jz	loc_64
		mvi	a,9		; tab
		call	outchr_a
		lxi	h,byte_36
		mov	a,m
		ani	0F8h
		adi	8
		mov	m,a
		ani	0Fh
		jz	loc_64
		mvi	a,8
		add	m
		mov	m,a
		mvi	a,9		; tab
		call	outchr_a
loc_64:		lda	byte_36
		add	b
		adi	5
		cpi	50h		; 80
		jc	loc_65
		call	crlf
		xra	a
		sta	byte_36
loc_65:		pop	h
		call	hlhex
		call	put_spc
		lxi	h,byte_36
		mov	a,m
		adi	5
		add	b
		mov	m,a
loc_66:		call	get_byte
		call	outchr_a	; output the symbol name
		dcr	b
		jnz	loc_66
		call	get_byte
		jmp	loc_62

loc_63:		lda	tab_cnt
		sta	byte_37
		jmp	skip_seg

load8:		cpi	0Eh		; eof segment?
		jnz	skip_seg
		lda	cmd_c		; produce .COM file flag
		ora	a
		jz	skip_seg
		lda	byte_40
		ora	a
		jz	load_err
		ret	

skip_seg:	call	get_byte
		jnz	skip_seg

check_sum:	mov	a,c		; segment checksum must be zero
		ora	a
		jz	next_rec
load_err:	lhld	load_sp
		sphl	
		xra	a
		ret	

;----------------------------------------------------------------------

out_fn:		ds	8	; output file name, if specified
name_bfr:	ds	17
byte_8:		db	0	; output file not specified flag
nxtaddr:	dw	0	; next empty address
baddr:		dw	0	; base address
staddr:		dw	0	; starting address
word_53:	dw	0
byte_40:	db	0
load_sp:	dw	0
cpm_sp:		dw	0
tab_cnt:	db	0	; tab counter, tabs are written to the output
				; only if they are followed by an ascii character
byte_37:	db	0
byte_38:	db	0
byte_36:	db	0
byte_39:	db	0
lst_x:		db	0	; current LST column
cmd_c:		db	0	; produce .COM file flag
cmd_p:		db	0	; printer echo flag
cmd_l:		db	0	; produce .LIN file flag
cmd_s:		db	0	; produce .SYM file flag (never set???)
cmd_b:		db	0
out_redir:	db	0	; out_char output redirection:
				;   00 - to .SYM file
				;   01 - to console
				;   02 - to .LIN file

		ds	64
stack		equ	$

		ds	128

inp_bfr:	ds	800h
sym_bfr:	ds	800h
lin_bfr:	ds	800h
com_bfr:	ds	800h


		end	start
