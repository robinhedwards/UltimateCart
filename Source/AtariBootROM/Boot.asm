/* Ultimate SD Cartridge - Atari 400/800/XL/XE Multi-Cartridge
   Copyright (C) 2015 Robin Edwards and Jonathan Halliday

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

	icl 'boot.inc'
	icl 'macros.inc'
	
VER_MAJ	equ $01
VER_MIN	equ $02

	opt h-				;Disable Atari COM/XEX file headers

	org $a000			;RD5 cartridge base
	opt f+				;Activate fill mode

init	.proc 				;Cartridge initalization
	rts				;Only the minimum of the OS initialization is complete, you don't want to code here normally.
.endp
	
start	.proc 				;Cartridge start, RAM, graphics 0 and IOCB no for the editor (E:) are ready


//
//	Main
//

main	.proc 
	lda #0
	sta RevFlag
	sta WaitCmdFlag
	sta DirLevel			; start in root directory
	sta MenuUpFlag
	lda #$FF
	sta CH				; set last key pressed to none
	sta BootFlag
	jsr copy_wait_for_reboot
	jsr CopyXEXLoader
	mva #3 BOOT			; patch reset - from mapping the atari (revised) appendix 11
	mwa #reset_routine CASINI
	jsr InitJoystick
	jsr SetUpDisplay
	jsr clear_screen
	jsr DisplayFooter
	jsr HomeSelection
main_loop
	jsr HighlightCurrentEntry
PollLoop
	bit BootFlag
	bpl @+
	jsr CheckSoftBoot
	jmp GotCmd
@
	lsr BootFlag
	lda ULTIMATE_CART_CMD
GotCmd
	lsr BootFlag
	cmp #CMD.Refresh
	beq display_cmd
	cmp #CMD.LoadXEX
	beq LoadXEX
	cmp #CMD.Error
	beq display_error
	cmp #CMD.Reboot
	beq reboot_cmd
	bit WaitCmdFlag
	bmi PollLoop
	jmp Read_keyboard
	
LoadXEX				; load XEX
	jsr CleanUp
	sei				; prevent GINTLK check in deferred VBI
	jsr send_fpga_ack_wait_clear
	jmp LoadBinaryFile
	
display_cmd
	sec
	ror MenuUpFlag
	jsr RefreshList
	jsr send_fpga_ack_wait_clear	; wait for the FPGA to clear the cmd byte
	jmp main_loop

display_error
	jsr show_error
	jsr send_fpga_ack_wait_clear	; wait for the FPGA to clear the cmd byte
	jsr clear_screen
	jsr set_colours			; restore normal colours
	jmp main_loop
	
reboot_cmd
	jsr CleanUp
	jsr send_fpga_ack_wait_clear
	sei				; prevent GINTLK check in deferred VBI
	jsr $100

read_keyboard
	bit MenuUpFlag			; make sure we don't accept input until menu is displayed
	bpl Main_Loop
	jsr CheckJoyStick
	cmp #$FF
	bne @+
	jsr GetKey
	beq Main_Loop
@
	jsr ToUpper
	cmp #'T'+1			; check for slot shortcut
	bcs @+
	cmp #'A'			
	bcc @+
	sbc #'A'			; carry is set
	cmp Entries			; see if we overshot the end of the list
	jcs Main_Loop
	jmp DoShortcut
@
	pha
	lsr MessageFlag
	lda KeyList			; number of entries
	asl @
	clc
	adc KeyList			; multiply entries by 3
	tax
	pla
ScanLoop
	cmp KeyList,x
	beq KeyFound
	dex
	dex
	dex
	bne ScanLoop
	jmp Main_Loop
KeyFound
	lda #>[Main_Loop-1]
	pha
	lda #<[Main_Loop-1]
	pha
	lda KeyList-1,x
	pha
	lda KeyList-2,x
	pha
	rts
KeyList
	.byte 13
	Target LaunchItem,Key.Return
	Target CursorUp,Key.Up
	Target CursorDown,Key.Down
	Target CursorLeft,Key.Left
	Target CursorRight,Key.Right
	Target Reboot,Key.X
	Target UpDir,Key.U
	Target NextPage,Key.Space
	Target PageUp,Key.Z
	Target NextPage,Key.CtrlDn
	Target PageUp,Key.CtrlUp
	Target ListTop,Key.CtrlShiftUp
	Target ListEnd,Key.CtrlShiftDown
	.endp
	

.proc Reboot				; Reboot
	lda #CCTL.DISABLE
	jmp send_fpga_cmd
	.endp
	
	
	
.proc UpDir				; Back up one level in directory tree
	lda DirLevel
	beq Done
	lsr MenuUpFlag
	jsr change_dir_message
	jsr HomeSelection
	lda #CCTL.UP_DIR
	jsr send_fpga_cmd
	sec
	ror WaitCmdFlag
	dec DirLevel			; say we backed up the directory tree
Done
	rts
	.endp
	
	
.proc ListTop
	jsr ListTopMessage
Loop
	jsr PrevPage
	beq Done
@
	lda ULTIMATE_CART_CMD
	cmp #Cmd.Refresh
	bne @-
	jsr send_fpga_ack_wait_clear	; wait for the FPGA to clear the cmd byte
	beq Loop
Done
	jsr CountEntries
@
	jsr CursorUp
	bne @-
	mva CurrEntry PrevEntry
	lsr WaitCmdFlag
	mwa #DIR_BUFFER CurrEntryPtr
	sec
	ror MenuUpFlag
	jmp RefreshList
	.endp
	
	
.proc ListEnd
	jsr ListEndMessage
Loop
	jsr NextPage
	beq Done
@
	lda ULTIMATE_CART_CMD
	cmp #Cmd.Refresh
	bne @-
	jsr send_fpga_ack_wait_clear	; wait for the FPGA to clear the cmd byte
	beq Loop
Done
	jsr CountEntries
@
	jsr CursorDown
	bne @-
	mva CurrEntry PrevEntry
	lsr WaitCmdFlag
	sec
	ror MenuUpFlag
	jmp RefreshList
	.endp
	
	
.proc PrevPage
	lda ULTIMATE_CART_LIST_FLAG
	and #ListFlags.FilesBefore	; see if there are any prior entries
	beq Done			; returns Z=1 if no prior entries
	lsr MenuUpFlag
	jsr EndSelection
	lda #CCTL.PREV_PAGE
	jsr send_fpga_cmd
	sec
	ror WaitCmdFlag			; this sets Z=0
Done
	rts
	.endp
	

	
.proc NextPage				; Display next page of entries
	lda ULTIMATE_CART_LIST_FLAG
	and #ListFlags.FilesAfter	; see if there are any more entries
	beq Done			; returns Z=1 if no prior entries
	lsr MenuUpFlag
	jsr HomeSelection
	lda #CCTL.NEXT_PAGE
	jsr send_fpga_cmd
	sec
	ror WaitCmdFlag			; this sets Z=0
Done
	rts
	.endp
	
	
	
.proc PageUp
	jsr PrevPage
	beq @+				; if PrevPage didn't do anything
	jsr HomeSelection		; otherwise home the cursor
@
	rts
	.endp
	
	

	
.proc DoShortcut			; Launch item via shortcut (pass item 0-19 in A)
	sta tmp3			; save item
Loop
	jsr HighlightCurrentEntry	; move highlight bar
	jsr WaitForSync			; give us time to see it
	lda tmp3
	cmp CurrEntry			; see if we need to move the selection bar
	beq Done
	bcs MoveDown
UpLoop					; move the cursor up
	jsr PrevItem
	jmp Loop
MoveDown
	jsr NextItem
	jmp Loop
Done
	jsr LaunchItem			; now the target item is selected, launch it
	jmp Main.Main_Loop
	.endp
	
	
	
.proc CursorUp
	lda CurrEntry
	bne PrevItem
	jmp PrevPage
	.endp
	
	
.proc CursorDown
	lda Entries
	cmp #2
	bcc @+
	sbc #1
	cmp CurrEntry			; is Entry < Entries - 1 ?
	beq IsLastEntry
	bcs NextItem
@
	rts
IsLastEntry				; if we're at the final entry, load next page of list
	jmp NextPage
	.endp
	
	
.proc CursorLeft
	jmp UpDir
	.endp
	
	
.proc CursorRight
	rts
	.endp
	
	
.proc PrevItem				; select previous item in list
	dec CurrEntry
	sbw CurrEntryPtr #$20
	lda #1 				; say OK
	rts
	.endp
	
	
.proc NextItem				; select next item in list
	inc CurrEntry
	adw CurrEntryPtr #$20
	lda #1				; say OK
	rts
	.endp
	
	
//
//	Launch highlighted item
//
	
.proc LaunchItem			
	ldy #0
	lda (CurrEntryPtr),y		; find out what the item is
	beq Abort
	lsr MenuUpFlag
	cmp #EntryType.Dir
	beq IsDir
	cmp #EntryType.XEX
	beq IsXEX
	jsr starting_cartridge_message	; not Nul and not Dir, so must be a file
	ldy CurrEntry
	jmp SendSelection
IsXEX
	jsr StartingXEXLoaderMessage
	ldy CurrEntry
	jmp SendSelection
IsDir
	jsr change_dir_message		; it's a directory
	inc DirLevel			; keep track of where we are in the tree
	lda CurrEntry
	pha
	jsr HomeSelection
	pla
	tay
SendSelection
	iny				; FPGA expects 1-20, so bump value
	tya
	jsr send_fpga_cmd
Abort
	rts
	.endp

	.endp	; proc start



//
//	Block waiting for key
//

.proc	WaitKey
	jsr GetKey
	beq WaitKey
	rts
	.endp
	

//
//	Scan keyboard (returns N = 1 for no key pressed, else ASCII in A)
//

.proc	GetKey
	ldx CH
	cpx #$FF
	beq NoKey
	mva #$FF CH		; set last key pressed to none
	lda scancodes,x
	cmp #$FF
NoKey
	rts
	.endp
	
	
//
//	Initialize Joystick
//

.proc InitJoystick
	mva #$0F StickState
	mva #$01 TriggerState
	rts
	.endp
	
	
//
//	Read Joystick
//

.proc CheckJoyStick
	lda Trig0
	cmp TriggerState
	bne TriggerChange	; trigger change
;	lda PORTA
	lda STICK0
	and #$0F
	cmp StickState
	bne StickChange		; stick change
	ldy Timer
	beq StickChange
Return
	lda #$FF
	rts

StickChange			; stick direction changed
	sta StickState
	ldy #6
	sty Timer
	cmp #$0F		; is stick centred?
	beq Return		; if yes, do nothing
	pha
	lda TriggerState
	tay
	lsr @
	lsr @
	eor #$80
	sta MotionFlag		; if we moved stick with trigger down, set flag to prevent button action on release
	tya
	asl @
	asl @
	tay
	pla			; get stick direction bits
	lsr @			; test up bit
	bcc @+
	iny			; down
	lsr @
	bcc @+
	iny			; left
	lsr @
	bcc @+
	iny			; right
@
	lda StickTable,y
	rts
StickTable
	.byte Key.CtrlUp,Key.CtrlDn,Key.CtrlShiftUp,Key.CtrlShiftDown
	.byte Key.Up,Key.Down,Key.Left,Key.Right


TriggerChange			; trigger has either gone up or down
	sta TriggerState
	cmp #0
	beq Done
	bit MotionFlag		; if button has come up without any stick movement, issue a return key
	bmi Done
	lda #Key.Return
	rts
Done
	lsr MotionFlag
	lda #$FF
	rts
	.endp
	
	

//
// poll command register for a second to see if cart was run by soft reboot
//

.proc CheckSoftBoot
	ldy #100
Loop
	jsr WaitForSync
	lda ULTIMATE_CART_CMD
	cmp #Cmd.Refresh
	beq @+
	cmp #Cmd.Error
	beq @+
	cmp #Cmd.Reboot
	dey
	bne Loop
	lda #CCTL.Reset
	jsr Send_FPGA_Cmd
	lsr BootFlag
	bcc CheckSoftBoot
@
	rts
	.endp
	

//
// Send a byte to the FPGA (byte in A)
//

.proc	send_fpga_cmd
	lsr WaitCmdFlag
	sta FPGA_CTRL
	rts
	.endp


.proc send_fpga_ack_wait_clear
	lda #$FF	; ack
	jsr send_fpga_cmd
wait_clear
	lda ULTIMATE_CART_CMD
	bne wait_clear
	rts
	.endp
	
	
	
//
//	Tell FPGA we've done a reset
//

.proc	reset_routine
	mva #3 BOOT
	lda #CCTL.RESET
	jmp send_fpga_cmd
	.endp




.proc	show_error
	ldax #ErrorMsg
	jsr ShowMsg
	jmp *
;	ldx #70
;@
;	jsr WaitForSync
;	dex
;	bpl @-
;	rts
	.endp
	


.proc	ListTopMessage
	ldax #ListTopMsg
	bne ShowMsg
	.endp
	
	
.proc	ListEndMessage
	ldax #ListEndMsg
	bne ShowMsg
	.endp
	
	

.proc	starting_cartridge_message
	ldax #StartCartMsg
	bne ShowMsg
	.endp
	
	
.proc	StartingXEXLoaderMessage
	ldax #StartXEXMsg
	bne ShowMsg
	.endp

.proc	change_dir_message
	ldax #ChangeDirMsg
	bne ShowMsg
	.endp
	
	
	
.proc ShowMsg
	stax MsgPtr
	jsr SetUpMessageBox
	adb TextLineCount #2 Height
	jsr OpenWindow
	ldax MsgPtr
	jmp PrintMessageBoxText
	.endp



;.proc	DisplayHeader
;	lda #0
;	sta cx
;	sta cy
;	ldax #txtHeader
;	jmp PutString
;	.endp


.proc	DisplayFooter
	mva #20 cy
	mva #0 cx
	ldax #txtFooter
	jmp PutString
	.endp
	
	
	
.proc	ClearFooter
	mva #21 cy
	mva #0 cx
	lda #32
@
	jsr PutChar
	lda cx
	cmp #40
	bcc @-
	rts
	.endp


.proc	Cleanup				; clean up prior to launching cart
	jsr WaitForSync
	sei
	mva #$0 NMIEN			; disable interrupts
	mwa OSVBI VVBLKI		; restore OS VBL
	mwa OSDLI VDSLST		; reinstate OS DLI vector
	lda #0
	sta SDMCTL
	sta DMACTL			; make sure screen blanks out immediately
;	mva #$40 NMIEN			; enable VBI, disable DLI
;	cli
	rts
	.endp



//
//	Count entries on current page
//

.proc CountEntries
	mwa #DIR_BUFFER dir_ptr
	lda #0
	sta CurrEntry
	sta Entries
	tay
Loop
	lda (dir_ptr),y
	beq Done
	adw dir_ptr #$20	; bump filename pointer
	inc Entries		; bump total entries
	lda Entries
	cmp #20
	bcc Loop
Done
	mwa #DIR_BUFFER dir_ptr
	rts
	.endp
	
	
	
	
//
//	Display page of FAT filenames
//
	
.proc RefreshList
	mva #'A' tmp2		; shortcut key
	mwa #DIR_BUFFER dir_ptr
	lda #0
	sta cx
	sta Entry
	sta Entries
	mva #0 cy
Loop
	ldy #0
	lda (dir_ptr),y
	beq Done
	jsr DisplayEntry
	adw dir_ptr #$20	; bump filename pointer
	inc Entry		; bump entry number
	inc Entries		; bump total entries
	inc tmp2		; bump shortcut key
	inc cy
	lda cy
	cmp #20
	bcc Loop
Done
	lda cy
	cmp #20			; did we fill the screen?
	bcs Finished
	mva #0 cx
	jsr PadLine
	inc cy
	bne Done
Finished
	jmp DisplayScrollIndicators
	.endp
	
	
//
//	Display file list entry
//
	
.proc DisplayEntry
	lda #0
	sta RevFlag
	sta cx
	lda #1
	jsr PutChar
	lda tmp2
	eor #$80
	jsr PutChar
	lda #2
	jsr PutChar
	cpb Entry CurrEntry
	bne @+
	lda #1
	jsr PutChar
	ldx #128
	stx RevFlag
	jsr PutFileName
	jsr PadFileName
	lda #2
	jmp PutChar
@
	lda #$20
	jsr PutChar
	jsr PutFileName
	jsr PadFileName
	lda #$20
	jmp PutChar
	.endp
	
	
//
//	Highlight current entry
//

.proc HighlightCurrentEntry
	lda PrevEntry		; see if we need to un-highlight old entry
	cmp CurrEntry
	beq Done
	ldx #0
	jsr ReverseItem
	lda CurrEntry
	ldx #128
	jsr ReverseItem
	mva CurrEntry PrevEntry
Done
	rts
	.endp
	
	
//
//	Reverse out an entry (pass entry in A)
//

.proc	ReverseItem
	stx tmp1
;	clc
;	adc #1
	tay
	lda LineTable.Lo,y
	clc
	adc #3
	sta ScrPtr
	lda LineTable.Hi,y
	adc #0
	sta ScrPtr+1
	ldy #34
	lda #0
	bit tmp1
	spl
	lda #66
	sta (ScrPtr),y
	dey
@
	lda (ScrPtr),y
	eor #$80
	sta (ScrPtr),y
	dey
	bne @-
	lda #0
	bit tmp1
	spl
	lda #65
	sta (ScrPtr),y
	rts
	.endp
	
//
//	Cursor home
//

.proc HomeSelection
	mwa #DIR_BUFFER CurrEntryPtr
	lda #0
	sta CurrEntry
	sta PrevEntry
	rts
	.endp
	
//
//	Cursor home
//

.proc EndSelection
	mwa #DIR_BUFFER+[19*32] CurrEntryPtr
	lda #19
	sta CurrEntry
	sta PrevEntry
	rts
	.endp	
	
	
	
//
//	Wait for sync
//
	
.proc WaitForSync
	lda VCount
	rne
	lda VCount
	req
	rts
	.endp
	
	
//
//	Convert ATASCII to uppercase
//
	
.proc ToUpper
	cmp #'z'+1
	bcs @+
	cmp #'a'
	bcc @+
	sbc #32
@
	rts
	.endp

//
//	Copy the wait and reboot routing to RAM so we're not running from ROM when the FPGA switches it
//

.proc	copy_wait_for_reboot
	ldy #.len[RebootCode]
@
	lda RebootCode-1,y
	sta $100-1,y
	dey
	bne @-
	rts
	.endp
	
.proc RebootCode
	ldx #1
	lda VCount
@
	cmp VCount
	req
	cmp VCount
	rne
	dex
	bpl @-
	jmp $E477
	.endp
	
	
//
//	Force OS to cold boot
//

	
	.local ForceColdStart
	lda #0
	sta NMIEN
	tax
@
	sta $0000,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	inx
	bne @-
@
	mva #$FF $0244
	rts
	.endl
	


//
//	XEX Loader
//

.proc CopyXEXLoader
	mwa #LoaderCodeStart ptr1
	mwa #LoaderAddress ptr2
	mwa #[EndLoaderCode-LoaderCode] ptr3
	jmp UMove
	.endp
	

	
//
//	Move bytes from ptr1 to ptr2, length ptr3
//


.proc UMove
	lda ptr3
	eor #$FF
	adc #1
	sta ptr3
	lda ptr3+1
	eor #$FF
	adc #0
	sta ptr3+1
	
	ldy #0
Loop
	lda (ptr1),y
	sta (ptr2),y
	iny
	bne @+
	inc ptr1+1
	inc ptr2+1
@
	inc ptr3
	bne Loop
	inc ptr3+1
	bne Loop
	rts
	.endp
		
	

	
	
; ************************ DATA ****************************
	
;txtHeader
;	.byte '  Ultimate SD Cartridge Menu',0
txtFooter
	.byte 32,28+128,29+128,'-Move ',30+128,'-Up Dir ','Return'*,'-Select ','X'+128,'-Reboot'
	.byte 32,32,32,'Ct'*,'+',28+128,29+128,'-Page Up/Dn ','Sh'*,'+','Ct'*,'+',28+128,29+128,'-Start/End',0
	
StartXEXMsg
	.byte 'Starting XEX Loader...',0
StartCartMsg
	.byte 'Starting Cartridge...',0
ChangeDirMsg
	.byte 'Changing Directory...',0
NextPageMsg
	.byte 'Next page...',0
PrevPageMsg
	.byte 'Previous page...',0
ListTopMsg
	.byte 'Start of list...',0
ListEndMsg
	.byte 'End of list...',0

txtEllipsis	equ *-4

	.align $100

	

	icl 'Display.s'
		
	
scancodes
	ins 'keytable.bin'
	

	org COMMAND_BUFFER
	.byte 0,0,0,0
	
	org DIR_BUFFER
	.local dir_entries
	.rept 32*20			; dir entries are 32 bytes long
	.byte 0
	.endr
	.endl
	
	org ERROR_MSG_BUFFER-7
	
ErrorMsg
	.byte 'Error: '

	.ds 40

	.align $0200	
	
FontData
	ins 'sdcart.fnt'
	
	
LoaderCodeStart

	opt f-
	org LoaderAddress
	opt f+
	
LoaderCode
	.byte 'L'
	.byte VER_MAJ
	.byte VER_MIN

	.proc LoadBinaryFile
	jsr InitLoader
Loop
	mwa #Return IniVec	; reset init vector
	jsr ReadBlock
	bmi Error
	cpw RunVec #Return
	bne @+
	mwa BStart RunVec	; set run address to start of first block
@
	jsr DoInit
	jmp Loop
Error
	jmp (RunVec)
Return
	rts
	.endp
	
	
//
//	Jump through init vector
//
	
	.proc DoInit
	jmp (IniVec)
	.endp


//
//	Read block from executable
//

	.proc ReadBlock
	jsr ReadWord
	bmi Error
	lda HeaderBuf
	and HeaderBuf+1
	cmp #$ff
	bne NoSignature
	jsr ReadWord
	bmi Error
NoSignature
	mwa HeaderBuf BStart
	jsr ReadWord
	bmi Error
	sbw HeaderBuf BStart BLen
	inw BLen
	mwa BStart IOPtr
	jsr ReadBuffer
Error
	rts
	.endp
	
	
	
	
//
//	Read word from XEX
//

	.proc ReadWord
	mwa #HeaderBuf IOPtr
	mwa #2 BLen		; fall into ReadBuffer
	.endp



//
//	Read buffer from XEX
//	Returns Z=1 on EOF
//
	
	.proc ReadBuffer
	jsr SetSegment
Loop
	lda BLen
	ora BLen+1
	beq Done
	
	lda FileSize		; first ensure we're not at the end of the file
	ora FileSize+1
	ora FileSize+2
	ora FileSize+3
	beq EOF

	inc BufIndex
	bne NoBurst			; don't burst unless we're at the end of the buffer
	
BurstLoop
	inc SegmentLo			; bump segment if we reached end of buffer
	bne @+
	inc SegmentHi
@
	jsr SetSegment

	lda Blen+1		; see if we can burst read the next 256 bytes
	beq NoBurst
	lda FileSize+1	; ensure buffer and remaining bytes in file are both >= 256
	ora FileSize+2
	ora FileSize+3
	beq NoBurst

	ldy #0			; read a whole page into RAM
@
	lda $D500,y		; doesn't matter about speculative reads (?)
	sta (IOPtr),y
	iny
	bne @-
	inc IOPtr+1		; bump address for next time

	ldx #3			; y is already 0
	sec
@
	lda FileSize,y	; reduce file size by 256
	sbc L256,y
	sta FileSize,y
	iny
	dex
	bpl @-
	dec Blen+1		; reduce buffer length by 256
	dec BufIndex
	bne ReadBuffer

NoBurst
	lda $D500
BufIndex	equ *-2
	ldy #0
	sta (IOPtr),y
	inw IOPtr
	dew BLen
	
	ldx #3		; y is already 0
	sec
@
	lda FileSize,y
	sbc L1,y
	sta FileSize,y
	iny
	dex
	bpl @-
	bmi Loop
	
Done
	ldy #1
	rts
EOF
	ldy #IOErr.EOF
	rts
	
SetSegment
	ldy #0
SegmentLo equ *-1
	ldx #0
SegmentHi equ *-1
	sty $D500
	stx $D501
	rts
L1
	.dword 1
L256
	.dword 256
	.endp


HeaderBuf	.word 0
BStart		.word 0
BLen		.word 0



; Everything beyond here can be obliterated safely during the load
	
//
//	Loader initialisation
//
	
	.proc InitLoader
	ldx #2
	lda VCount			; wait 2 frames so that cart is disabled
@
	cmp VCount
	req
	cmp VCount
	rne
	dex
	bpl @-

	jsr SetGintlk
	jsr BasicOff
	cli
	jsr OpenEditor
	mwa #EndLoaderCode MEMLO
	mwa #LoadBinaryFile.Return RunVec	; reset run vector
	ldy #0
	tya
@
	sta $80,y
	iny
	bpl @-
	jsr ClearRAM
	
	ldy #3
@
	lda $D500,y
	sta FileSize,y
	dey
	bpl @-
	mva #3 ReadBuffer.BufIndex
	rts
	.endp

	
	
	.proc BASICOff
	mva #$01 $3f8
	mva #$C0 $6A
	lda portb
	ora #$02
	sta portb
	rts
	.endp
	
	

	.proc SetGintlk
	sta WSYNC
	sta WSYNC
	lda TRIG3
	sta GINTLK
	rts
	.endp
	
	
	
	.proc ClearRAM
	mwa #EndLoaderCode ptr1
;	sbw $c000 ptr1 ptr2
	sbw SDLSTL ptr1 ptr2		; clear up to display list address
	
	lda ptr2
	eor #$FF
	clc
	adc #1
	sta ptr2
	lda ptr2+1
	eor #$FF
	adc #0
	sta ptr2+1
	ldy #0
	tya
Loop
	sta (ptr1),y
	iny
	bne @+
	inc ptr1+1
@
	inc ptr2
	bne Loop
	inc ptr2+1
	bne Loop
	rts
	.endp
	
	
	
	.proc OpenEditor
	ldx #0
	lda #$0c
	sta iocb[0].Command
	jsr ciov
	mwa #EName iocb[0].Address
	mva #$0C iocb[0].Aux1
	mva #$00 iocb[0].Aux2
	mva #$03 iocb[0].Command
	jmp ciov

EName
	.byte 'E:',$9B

	.endp
	


	.if 0
//
//	Wait for sync
//

	.proc WaitForSync2
	lda VCount
	rne
	lda VCount
	req
	rts
	.endp
	
	.endif
	

	

EndLoaderCode ; end of relocated code

LoaderCodeSize	= EndLoaderCode-LoaderCode
	
	opt f-
	org LoaderCodeStart + LoaderCodeSize
	opt f+
	
; ************************ CARTRIDGE CONTROL BLOCK *****************

	org $bffa			;Cartridge control block
	.word start			;CARTCS
	.byte 0				;CART
	.byte CARTFG_START_CART		;CARTFG
	.word init			;CARTAD

