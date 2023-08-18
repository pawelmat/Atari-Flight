; *********************************************
; Flight Over Unknown Land - 256b Atari XE/XL mini-demo
; Kane / Suspect
; 17-18/08/2023, Kaszuby
; Copyright (C) 2023 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
; Assemble using MADS
; 
; Silly Venture 2023 Summer Edition (18-20/08/2023) Atari 256-bytes compo entry
; *********************************************

start 	= $4000		; do not change as the DL list is assumed to be in $40H
scr		= $5000
width	= 32
heigth	= 32

	icl "Includes/registers.asm"
	icl "Includes/zeropage.asm"

	org	start

	// create display list
	ldx	#heigth+>scr-1
dlcreate
	ldy #3
dlc1
	jsr	dl_elem_add
	dey
	bpl dlc1
	dex
	cpx #>scr
	bpl	dlcreate

	dec	SDMCTL		; $21 = narrow playfield	
	lda	#<dl
	sta	SDLSTL
	lda #$40
	sta	SDLSTH
	sta GPRIOR		; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	lda	#$10		; TBD, could be removed or replaced by lsr #2?
	sta COLOR4

;init
	lda	#10
	sta	t1
	sta	t3
	sta	AUDC1		; audio volume
	lda	#84
	sta	t2
	sta	t4

; main loop
mainloop:
; 	lda	#100			; remove?
; vsync:
; 	cmp	VCOUNT
; 	bne	vsync

	dec	t1
	dec	t2
	inc t3
	inc t4

	lda t2
	sta	AUDF1		; audio frequency

	inc	t20
	lda	t20
	cmp	#32
	bmi	posstep
	cmp	#63
	bne	negstep
	lda	#0
	sta	t20
	inc	t2				; every zoom move the map a bit
	dec	t3

posstep:
	inc	t1
	dec	t2
	inc	t3
	dec	t4
	bne	cont1
negstep:
	dec	t1
	inc	t2
	dec	t3
	inc	t4
cont1:
	clc
	lda	t2
	sbc	t1
	sta	t10
	clc
	lda	t4
	sbc	t3
	sta	t11

	lda	t3
	sta	t6			; y0

	.proc polygons
	ldy	#heigth+>scr-1
polyY:
	sty setpix+2
	lda	t1
	sta	t5			; x0
	ldx #width-1
polyX:
	lda	#0
	sta	t7			; x
	sta	t8			; y
	sta	t9			; color
conv1:				; while ((t7 + t8 <= 0) && (t9<15))
	lda	t7
;	clc
	adc	t8
	bmi	conv2

	lda	t7
;	clc
	sbc	t8
;	clc
	adc	t5
	sta	t19

	lda	t7
;	clc
	adc	t8
;	clc
	adc	t6
	sta	t8

	lda	t19
	sta	t7

	lda	t9
	clc				; leave this one
	adc	#$11
	sta	t9
	cmp	#$ee
	bne	conv1

conv2:
	lda	t9
setpix:
	sta	scr,x

	lda	t12
	adc	t10
	cmp	#width
	bmi	x1
	sbc	#width
	inc	t5
x1:	sta	t12

	dex
	bne	polyX

	lda	t13
	adc	t11
	cmp	#heigth
	bmi	x2
	sbc	#heigth
	inc	t6
x2:	sta	t13

	dey
	cpy #>scr
	bne	polyY
	.endp			; end of polygons

 	jmp mainloop

; add Display List element - one mode 15 line and one blank line
dl_elem_add:
	lda	#$4f
	jsr	s1
	txa
		
s1:	sta dl1			; for this to work, "dl" must start on an even address
	inc s1+1
	bne s2
	inc s1+2
s2:
	inc s1+1
	rts

 	.align 2,0			; TBD - remove
	;.byte	$70, $4F, a(scr), 0, $4F, a(scr), 0, $41, a(dl)
dl:	.byte 	$70			; MUST be at even address
dl1:

endmain1:

;	org	dl1+[2*4*heigth]
	org	dl1+[4*4*heigth]
	
dl2	.byte	$41, a(dl)

endmain2:

	.print	"----------------------------"
	.print	"Start: ", start, " DL: ", endmain1, " End: ", endmain2, " (Len: ", endmain1-start+endmain2-dl2, ")"
	.print	"File:  ", endmain1-start+endmain2-dl2+10  ; this includes org markers etc.
	.print	"----------------------------"
	