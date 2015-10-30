/* Ultimate SD Cartridge - Atari 400/800/XL/XE Multi-Cartridge
   Copyright (C) 2015 Robin Edwards

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

   Boot.asm 
   --------
   This file builds with WUDSN/MADS into an 8K Atari ROM.
   It needs converted to a hex file for inclusion in the Quartus project.
   This can be done with avr-objcopy.exe -I binary -O ihex boot.rom boot_rom.hex
*/

;@com.wudsn.ide.asm.outputfileextension=.rom
;CARTCS	= $bffa 			;Start address vector, used if CARTFG has CARTFG_START_CART bit set
;CART	= $bffc				;Flag, must be zero for modules
;CARTFG	= $bffd				;Flags or-ed together, indicating how to start the module.
;CARTAD	= $bffe				;Initialization address vector

CARTFG_DIAGNOSTIC_CART = $80		;Flag value: Directly jump via CARTAD during RESET.
CARTFG_START_CART = $04			;Flag value: Jump via CARTAD and then via CARTCS.
CARTFG_BOOT = $01			;Flag value: Boot peripherals, then start the module.

COLDSV = $E477				; Coldstart (powerup) entry point
WARMSV = $E474				; Warmstart entry point
CH = $2FC				; Internal hardware value for the last key pressed
BOOT = $09
CASINI = $02

color1 = $2c5				; Shadow of colpf1
color2 = $2c6				; Shadow of colpf2
color4 = $2c8				; Shadow of colbk

rowcrs = $54				; cursor row byte 0..23
colcrs = $55				; word 0..39

sm_ptr = $58				; screen memory

; Atari -> FPGA commands (Sent as D510 access)
; 1-20 select item n
; 64 disable cart
; 127 prev page
; 128 next page
; 129 up directory
; 130 reset
; 255 acknowledge
D500_DISABLE_BYTE = 64
D500_PREV_PAGE_BYTE = 127
D500_NEXT_PAGE_BYTE = 128
D500_UP_DIR_BYTE = 129
D500_RESET_BYTE = 130

; FPGA -> Atari command (in ULTIMATE_CART_CMD_BYTE)
; 0 nothing to do
; 1 atari should display new directory entries (atari sends ack back to say done)
; 2 error (message at $B300)
; 255 reboot
ULTIMATE_CART_CMD_BYTE = $AFF0

; Directory list Flag
; bit 0 - more files above, bit 1 - more files below
ULTIMATE_CART_LIST_FLAG_BYTE = $AFF1


; ************************ VARIABLES ****************************
character 	= $80
ypos 		= $81
dir_ptr		= $82	// word
dir_entry	= $84
shortcut_key    = $85
tmp_ptr		= $90	// word
text_out_x	= $92	// word
text_out_y	= $94	// word
text_out_ptr	= $96	// word
text_out_len	= $98
shortcut_buffer	= $9a	// word
; ************************ CODE ****************************
	opt h-				;Disable Atari COM/XEX file headers

	org $a000			;RD5 cartridge base
	opt f+				;Activate fill mode

init	.proc 				;Cartridge initalization
	rts				;Only the minimum of the OS initialization is complete, you don't want to code here normally.
.endp
	
start	.proc 				;Cartridge start, RAM, graphics 0 and IOCB no for the editor (E:) are ready

; ************************ MAIN ****************************
main	.proc 
; set up the colors
	jsr set_colours
	mva #$FF CH		; set last key pressed to none
	jsr copy_wait_for_reboot
	mva #3 BOOT ; patch reset - from mapping the atari (revised) appendix 11
	mwa #reset_routine CASINI
	jsr clear_screen
	jsr output_header
	jsr output_footer
	
; main loop
main_loop
	lda ULTIMATE_CART_CMD_BYTE
	; update display?
	cmp #$01
	beq display_cmd
	; error?
	cmp #$02
	beq display_error
	; reboot?
	cmp #$FF
	beq reboot_cmd
	; check for user pressing a key
	jmp read_keyboard
	
display_cmd
	jsr output_directory_entries
; wait for the FPGA to clear the cmd byte
	jsr send_fpga_ack_wait_clear
	jmp main_loop

display_error
	jsr show_error
; wait for the FPGA to clear the cmd byte
	jsr send_fpga_ack_wait_clear
	jsr clear_screen
	jsr set_colours	; restore normal colours
	jmp main_loop
	
reboot_cmd
	jsr send_fpga_ack_wait_clear
	sei	; prevent GINTLK check in deferred vbi
	jsr $600

read_keyboard
	ldx CH
	cpx #$FF
	bne key_pressed
	jmp end_key
; key pressed
key_pressed
	mva #$FF CH		; set last key pressed to none
	lda scancodes,x
	cmp #$FF
	bne check_reboot
	jmp end_key
; check for X (reboot)
check_reboot
	cmp #"X"
	bne check_up
	lda #D500_DISABLE_BYTE
	jsr send_fpga_cmd
	jmp end_key
check_up
; check for U (up dir)
	cmp #"U"
	bne check_space
	jsr change_dir_message
	lda #D500_UP_DIR_BYTE
	jsr send_fpga_cmd
	jmp end_key
check_space
; check_for space (next page)
	cmp #" "
	bne check_z
	lda ULTIMATE_CART_LIST_FLAG_BYTE	; are there more files?
	and #$02
	beq end_key				; no
	jsr next_page_message			; yes there are, display message
	lda #D500_NEXT_PAGE_BYTE
	jsr send_fpga_cmd
	jmp end_key
check_z
; check_for z (prev page)
	cmp #"Z"
	bne check_item
	lda ULTIMATE_CART_LIST_FLAG_BYTE	; are there previous files?
	and #$01
	beq end_key				; no
	jsr prev_page_message			; yes there are, display message
	lda #D500_PREV_PAGE_BYTE
	jsr send_fpga_cmd
	jmp end_key
check_item
; check between A & T (item)
	cmp #"A"
	bmi end_key
	cmp #"T"+1
	bpl end_key
; we've selected an item
	sub #("A"-1)
	pha
; find out what kind of item it is (file/dir/blank)
	tax
	mwa #$b000 dir_ptr
find_loop
	dex
	cpx #0
	beq check_target_entry
	adw dir_ptr #32
	jmp find_loop
check_target_entry	
	ldy #0
	lda (dir_ptr),y
	cmp #1
	bne check_dir
	; its a file
	jsr starting_cartridge_message
	jmp send_selection
check_dir
	cmp #2
	bne end_key
	; its a directory
	jsr change_dir_message
	jmp send_selection
send_selection
	pla
	jsr send_fpga_cmd

end_key
	jmp main_loop
	.endp	; proc main

	.endp	; proc start

; ************************ SUBROUTINES ****************************
; send a byte to the FPGA (byte in Accumulator)
.proc	send_fpga_cmd
	sta $D510
	rts
	.endp

.proc send_fpga_ack_wait_clear
	lda #$FF	; ack
	jsr send_fpga_cmd
wait_clear
	lda ULTIMATE_CART_CMD_BYTE
	bne wait_clear
	rts
	.endp
	
.proc	reset_routine
	mva #3 BOOT
	; tell the FPGA we've done a reset
	lda #D500_RESET_BYTE
	jsr send_fpga_cmd
	rts
	.endp

.proc	output_header
	mva #0 text_out_x
	mva #0 text_out_y
	mwa #top_text text_out_ptr
	mva #(.len top_text) text_out_len
	jsr output_text_inverted
	rts
	.endp

.proc	output_list_arrows
	mwa sm_ptr tmp_ptr
up_arrow
	lda ULTIMATE_CART_LIST_FLAG_BYTE
	and #$01
	beq down_arrow
	ldy #0
	lda #92	; up arrow
	ora #$80
	sta (tmp_ptr),y
down_arrow
	lda ULTIMATE_CART_LIST_FLAG_BYTE
	and #$02
	beq exit
	ldy #1
	lda #93	; down arrow
	ora #$80
	sta (tmp_ptr),y
exit
	rts
	.endp

.proc	output_footer
	mva #0 text_out_x
	mva #23 text_out_y
	mwa #bottom_text text_out_ptr
	mva #(.len bottom_text) text_out_len
	jsr output_text_inverted
	rts
	.endp

.proc	show_error
	mva #$31 color2		// background -> red
	jsr clear_screen
	jsr output_header
	
	mva #3 text_out_y
	mva #2 text_out_x
	mwa #error_text text_out_ptr
	mva #(.len error_text) text_out_len
	jsr output_text
	
	mva #4 text_out_y
	mva #32 text_out_len
	mwa #$B300 text_out_ptr
	jsr output_text
	
	mva #$FF CH		; set last key pressed to none
wait_key
	ldx CH
	cpx #$FF
	beq wait_key
	
	mva #$FF CH		; set last key pressed to none
	rts
	.endp

.proc	set_colours
	mva #$81 color2		// background
	mva #$0F color1		// foreground (luma)
	mva #$00 color4		// border
	rts
	.endp

.proc	output_directory_entries
	jsr clear_screen
	jsr output_header
	jsr output_list_arrows
	jsr output_footer
	
	mwa #$b000 dir_ptr
	mva #0 dir_entry
	mva #1 ypos
	mva #'A' shortcut_key
next_entry
	ldy dir_entry
	cpy #20
	bmi next
	jmp end_of_page
next
	inc ypos
	mva ypos text_out_y
; output the keyboard shortcut
	mva #2 text_out_x
	mva shortcut_key shortcut_buffer
	mva #'-' shortcut_buffer+1
	mwa #shortcut_buffer text_out_ptr
	mva #2 text_out_len
	jsr output_text_inverted
; output the directory entry
	mva #5 text_out_x
; is it a file or folder?
	ldy #0
	lda (dir_ptr),y
	cmp #1
	beq out_name
	cmp #2
	beq out_dir
	jmp out_end
out_dir
	mwa dir_ptr text_out_ptr
	adw text_out_ptr #1
	mva #31 text_out_len
	jsr output_text_inverted
	jmp out_end
out_name
	mwa dir_ptr text_out_ptr
	adw text_out_ptr #1
	mva #31 text_out_len
	jsr output_text
out_end
	inc dir_entry
	inc shortcut_key
	adw dir_ptr #32
	jmp next_entry
end_of_page
	rts
	.endp

.proc	starting_cartridge_message
	mva #11 text_out_y
	mva #10 text_out_x
	mwa #loading_text text_out_ptr
	mva #(.len loading_text) text_out_len
	jsr output_text_inverted
	rts
	.endp

.proc	change_dir_message
	mva #11 text_out_y
	mva #10 text_out_x
	mwa #directory_text text_out_ptr
	mva #(.len directory_text) text_out_len
	jsr output_text_inverted
	rts
	.endp
	
.proc	next_page_message
	mva #11 text_out_y
	mva #13 text_out_x
	mwa #next_page_text text_out_ptr
	mva #(.len next_page_text) text_out_len
	jsr output_text_inverted
	rts
	.endp
	
.proc	prev_page_message
	mva #11 text_out_y
	mva #13 text_out_x
	mwa #prev_page_text text_out_ptr
	mva #(.len prev_page_text) text_out_len
	jsr output_text_inverted
	rts
	.endp

; clear screen
clear_screen .proc
	mwa sm_ptr tmp_ptr
	ldx #24	; lines
yloop	lda #0
	ldy #39
xloop	sta (tmp_ptr),y
	dey
	bpl xloop
	adw tmp_ptr #40
	dex
	bne yloop
	rts
	.endp
	
; output text in text_out_ptr at (cur_x, cur_y)
output_text .proc
	mwa sm_ptr tmp_ptr
; add the cursor y offset
	ldy text_out_y
yloop	dey
	bmi yend
	adw tmp_ptr #40
	jmp yloop
yend	adw text_out_x tmp_ptr tmp_ptr ; add the cursor x offset
; text output loop
	ldy #0
nextchar ; text output loop
	lda (text_out_ptr),y
	beq endoftext ; end of line?
	cmp #96; convert ascii->internal
	bcs lower
	sec
	sbc #32
lower	sta (tmp_ptr),y
	iny
	cpy text_out_len
	bne nextchar
endoftext	
	rts
	.endp

; output text in text_out_ptr at (cur_x, cur_y)
output_text_inverted .proc 
	mwa sm_ptr tmp_ptr
; add the cursor y offset
	ldy text_out_y
yloop	dey
	bmi yend
	adw tmp_ptr #40
	jmp yloop
yend	adw text_out_x tmp_ptr tmp_ptr ; add the cursor x offset
; text output loop
	ldy #0
nextchar ; text output loop
	lda (text_out_ptr),y
	beq endoftext ; end of line?
	cmp #96; convert ascii->internal
	bcs lower
	sec
	sbc #32
lower	ora #$80
	sta (tmp_ptr),y
	iny
	cpy text_out_len
	bne nextchar
endoftext	
	rts
	.endp

; copy the wait and reboot routing to RAM so we're not running from ROM when the FPGA switches it
.proc	copy_wait_for_reboot
;wait at least one frame then reboot
;	lda:cmp:req 20
;	lda:cmp:req 20
;	jmp COLDSV
	lda #$A5
	sta $600
	lda #$14
	sta $601
	lda #$C5
	sta $602
	lda #$14
	sta $603
	lda #$F0
	sta $604
	lda #$FC
	sta $605
	lda #$A5
	sta $606
	lda #$14
	sta $607
	lda #$C5
	sta $608
	lda #$14
	sta $609
	lda #$F0
	sta $60A
	lda #$FC
	sta $60B
	lda #$4C
	sta $60C
	lda #$77
	sta $60D
	lda #$E4
	sta $60E
	rts
	.endp
	
; ************************ DATA ****************************
	
	.local top_text
	.byte '       Ultimate Cartridge Menu      v1.1'
	.endl
	.local bottom_text
	.byte 'U=UpDir, SPACE/Z=Page Down/Up, X=Disable'
	.endl
	
	.local loading_text
	.byte ' Starting Cartridge... '
	.endl
	
	.local directory_text
	.byte ' Changing Directory... '
	.endl
	
	.local prev_page_text
	.byte ' Prev page... '
	.endl
	
	.local next_page_text
	.byte ' Next page... '
	.endl
	
	.local error_text
	.byte 'Error:'
	.endl	
	
scancodes .array [256] = $ff
	[63]:[127] = "A"              ; "" = internal code '' = ATASCII
	[21]:[85]  = "B"
	[18]:[82]  = "C"
	[58]:[122] = "D"
	[42]:[106] = "E"
	[56]:[120] = "F"
	[61]:[125] = "G"
	[57]:[121] = "H"
	[13]:[77]  = "I"
	[1] :[65]  = "J"
	[5] :[69]  = "K"
	[0] :[64]  = "L"
	[37]:[101] = "M"
	[35]:[99]  = "N"
	[8] :[72]  = "O"
	[10]:[74]  = "P"
	[47]:[111] = "Q"
	[40]:[104] = "R"
	[62]:[126] = "S"
	[45]:[109] = "T"
	[11]:[75]  = "U"
	[16]:[80]  = "V"
	[46]:[110] = "W"
	[22]:[86]  = "X"
	[43]:[107] = "Y"
	[23]:[87]  = "Z"
	[33]:[97]  = " "
	[52]:[180] = $7e
	[12]:[76]  = $9b
	.enda

	org $aff0
	.byte 0,0,0,0
	
	org $b000
	.local dir_entries			; test data
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0	; 32 chars long
	.endl
	
	org $b300
	.byte 'Test error message',0
	
; ************************ CARTRIDGE CONTROL BLOCK *****************

	org $bffa			;Cartridge control block
	.word start			;CARTCS
	.byte 0				;CART
	.byte CARTFG_START_CART		;CARTFG
	.word init			;CARTAD

