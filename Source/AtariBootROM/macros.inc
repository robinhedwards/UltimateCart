;	@com.wudsn.ide.asm.mainsourcefile=_boot.s

ldax .macro	" "	; load a,x pair
	.if :1 = '#'
		lda #< :2
		ldx #> :2
	.else
		lda :2
		ldx :2+1
	.endif
	.endm



ldyx .macro	" "	; load y,x pair
	.if :1 = '#'
		ldy #< :2
		ldx #> :2
	.else
		ldy :2
		ldx :2+1
	.endif
	.endm
;

stax	.macro
	sta :1
	stx :1+1
	.endm
	
	
eqax	.macro	" "	; check if a,x is equal to arg
	.if :1 = '#'
		cmp #< :2
		bne @+
		cpx #> :2
	.else
		cmp :2
		bne @+
		cpx :2+1
	.endif
@
	.endm
	
	
	
mda	.macro
	ldy #3
?1
	lda :1,y
	sta :2,y
	dey
	bpl ?1
	.endm
	

//
//	Menu jump table
//

Target	.macro
	.word :1-1
	.byte :2
	.endm
	