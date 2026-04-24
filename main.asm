.include "m328pdef.inc"
.dseg
.equ w=16
.equ r=8
.equ b=12
.equ t=2*(r+1)	; t = 18

.equ p=0xB7E1
.equ q=0x9E37



key: .byte b
s: .byte 36



.cseg
.org 0x0000
rjmp init

init:
    ; point Z to flash source
	ldi ZL, low(encryption_key*2)
    ldi ZH, high(encryption_key*2)

;,,,,,key_ptr => x ,,,, s_ptr => y
ldi xl, low(key)
ldi xh, high(key)

ldi yl, low(s)
ldi yh, high(s)

ldi r16, 12

key_init:
    lpm r17, Z+
    st X+, r17
    dec r16
    brne key_init



; initializing s ----
.def pl = r16
.def ph = r17
.def ql = r18
.def qh = r19
.def s_im1l=r0
.def s_im1h=r1
.def lp_cntr_i=r20
.def lp_cntr_j=r21



ldi pl, low(p)
ldi ph, high(p)
ldi ql, low(q)
ldi qh, high(q)
ldi lp_cntr_i, t-1


st y+, pl
st y+, ph
movw s_im1l,pl

s_init:
	add s_im1l, ql
	adc s_im1h, qh

	st y+, s_im1l
	st y+, s_im1h

	dec lp_cntr_i
	brne s_init

;...key mixing...
.def al=r2
.def ah=r3
.def bl=r4
.def bh=r5
.equ c=b/(w/8)	; c = 6
.def n=r22
.def zro_reg=r6

clr al
clr ah
clr bl
clr bh
clr lp_cntr_i
clr lp_cntr_j


ldi n, t
ldi r23, c
cp n,r23
brlo c_g
ldi n, t*3
rjmp cont
c_g:
	ldi n, c*3
cont:
ldi xl, low(key)
ldi xh, high(key)
ldi yl, low(s)
ldi yh, high(s)

;...mixing loop...
clr zro_reg
key_mix:
	ld s_im1l, y+
	ld s_im1h, y+
	add s_im1l, al
	adc s_im1h, ah
	add s_im1l, bl
	adc s_im1h, bh
	ldi r23, 3
	rol3:
		lsl s_im1l
		rol s_im1h
		adc s_im1l, zro_reg
		dec r23
		brne rol3

	movw al, s_im1l
	st -y, s_im1h
	st -y, s_im1l

	ld s_im1l, x+
	ld s_im1h, x+
	add s_im1l, al
	adc s_im1h, ah
	add s_im1l, bl
	adc s_im1h, bh
	movw r25:r24, al
	add r24, bl

	;........and to decrease rotation parameter....;
	andi r24, $0f
	breq skp_rol_ab
	clr zro_reg
	rol_ab:
		lsl s_im1l
		rol s_im1h
		adc s_im1l, zro_reg
		dec r24				;	r24 < 16
		brne rol_ab

	skp_rol_ab:
	movw bl, s_im1l
	st -x, s_im1h
	st -x, s_im1l

	inc lp_cntr_i
	inc lp_cntr_j

	mod_lp_i:
		cpi lp_cntr_i, t
		brlo mod_i_done
		subi lp_cntr_i, t
		rjmp mod_lp_i

	mod_i_done:
	tst lp_cntr_i
	breq rst_i
	rjmp skp_rst_i
	rst_i:
		ldi yl, low(s)
		ldi yh, high(s)
	skp_rst_i:
	mod_lp_j:
		cpi lp_cntr_j, c
		brlo mod_j_done
		subi lp_cntr_j, c
		rjmp mod_lp_j

	mod_j_done:
	tst lp_cntr_j
	breq rst_j
	rjmp skp_rst_j
	rst_j:
		ldi xl, low(key)
		ldi xh, high(key)
	skp_rst_j:
	cpse lp_cntr_j, zro_reg
	adiw xl, 2
	cpse lp_cntr_i, zro_reg
	adiw yl, 2
	dec n
	brne key_mix



;........Encryption............;
clr al
clr ah
clr bl
clr bh

ldi lp_cntr_i, $55
ldi lp_cntr_j, $55
movw al, lp_cntr_i

ldi lp_cntr_i, $66
ldi lp_cntr_j, $66
movw bl, lp_cntr_i



ldi yl, low(s)
ldi yh, high(s)

ld s_im1l, y+
ld s_im1h, y+
add al, s_im1l
adc ah, s_im1h

ld s_im1l, y+
ld s_im1h, y+
add bl, s_im1l
adc bh, s_im1h

clr n
;...encrpt_loop....
clr zro_reg
encrypt:
	eor al, bl
	eor ah, bh

	mov r24, bl
	andi r24, $0f
	breq skp_rol_b
	rol_b:
		lsl al
		rol ah
		adc al, zro_reg
		dec r24				;	r24 < 16
		brne rol_b

	skp_rol_b:
	;ldi yl, low(s)
	;ldi yh, high(s)

	subi n, -2

	ld s_im1l, y+
	ld s_im1h, y+
	add al, s_im1l
	adc ah, s_im1h


	eor bl, al
	eor bh, ah

	mov r24, al
	andi r24, $0f
	breq skp_rol_a
	rol_a:
		lsl bl
		rol bh
		adc bl, zro_reg
		dec r24				;	r24 < 16
		brne rol_a

	skp_rol_a:
	ld s_im1l, y+
	ld s_im1h, y+
	add bl, s_im1l
	adc bh, s_im1h

	cpi n, r*2
	brne encrypt


;........decryption.........
ldi n, r

decrypt:
	ld s_im1h, -y
	ld s_im1l, -y

	sub bl, s_im1l
	sbc bh, s_im1h

	mov r24, al
	andi r24, $0f
	breq skp_ror_a
	ror_a:
		bst bh, 0
		lsr bl
		ror bh
		bld bl, 7
		dec r24				;	r24 < 16
		brne ror_a

	skp_ror_a:
	eor bl, al
	eor bh, ah

	ld s_im1h, -y
	ld s_im1l, -y

	sub al, s_im1l
	sbc ah, s_im1h

	mov r24, bl
	andi r24, $0f
	breq skp_ror_b
	ror_b:
		bst ah, 0
		lsr al
		ror ah
		bld al, 7
		dec r24				;	r24 < 16
		brne ror_b

	skp_ror_b:
	eor al, bl
	eor ah, bh

	dec n
	brne decrypt

ld s_im1h, -y
ld s_im1l, -y

sub bl, s_im1l
sbc bh, s_im1h

ld s_im1h, -y
ld s_im1l, -y

sub al, s_im1l
sbc ah, s_im1h


l1: rjmp l1

encryption_key:
    .db "cyberPhantom"