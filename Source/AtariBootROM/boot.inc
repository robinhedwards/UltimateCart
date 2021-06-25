;	@com.wudsn.ide.asm.mainsourcefile=_boot.s

;CARTCS	= $bffa 			;Start address vector, used if CARTFG has CARTFG_START_CART bit set
;CART	= $bffc				;Flag, must be zero for modules
;CARTFG	= $bffd				;Flags or-ed together, indicating how to start the module.
;CARTAD	= $bffe				;Initialization address vector

CARTFG_DIAGNOSTIC_CART	equ $80		;Flag value: Directly jump via CARTAD during RESET.
CARTFG_START_CART		equ $04		;Flag value: Jump via CARTAD and then via CARTCS.
CARTFG_BOOT				equ $01		;Flag value: Boot peripherals, then start the module.

COLDSV		equ $E477		; Coldstart (powerup) entry point
WARMSV		equ $E474		; Warmstart entry point
CH		equ $2FC		; Internal hardware value for the last key pressed

drkmsk		equ $4E
colrsh		equ $4F

color1		equ $2c5		; Shadow of colpf1
color2		equ $2c6		; Shadow of colpf2
color4		equ $2c8		; Shadow of colbk

rowcrs		equ $54			; cursor row byte 0..23
colcrs		equ $55			; word 0..39

sm_ptr		equ $58			; screen memory


FPGA_CTRL	equ $D510

; Atari -> FPGA commands (Sent as D5xx access)
; 1-20 select item n
; 64 disable cart
; 128 next page
; 129 up directory
; 130 reset
; 255 acknowledge

	.enum CCTL
DISABLE		= 64
PREV_PAGE	= 127
NEXT_PAGE	= 128
UP_DIR		= 129
RESET		= 130
ACK			= 255
	.ende
	
	
	.enum CMD
Refresh		= 1
Error		= 2
LoadXEX		= 3
Reboot		= 255
	.ende
	
	
	.enum ListFlags
FilesBefore	= 1
FilesAfter	= 2
	.ende
	

	.enum EntryType
Nul		= 0
File	= 1
Dir		= 2
XEX		= 3
	.ende
	
LoaderAddress	equ $700
	
MenuLines	equ 20


; FPGA -> Atari command (in ULTIMATE_CART_CMD_BYTE)
; 0 nothing to do
; 1 atari should display new directory entries (atari sends ack back to say done)
; 2 error (message at $B300)
; 255 reboot

ULTIMATE_CART_CMD		equ $AFF0
ULTIMATE_CART_LIST_FLAG equ $AFF1 ; bit 0 = more files below, bit 1 = more files above
DIR_BUFFER			equ $B000
ERROR_MSG_BUFFER	equ $B300
COMMAND_BUFFER		equ $AFF0

//
// Variables
//

	org $80
	
cx		.ds 1
cy		.ds 1
character	.ds 1
ypos		.ds 1
dir_ptr		.ds 2
dir_entry	.ds 1
shortcut_key    .ds 1
tmp_ptr		.ds 2
text_out_x	.ds 2
text_out_y	.ds 2
text_out_ptr	.ds 2
text_out_len	.ds 2
shortcut_buffer	.ds 2
RevFlag		.ds 1		; bit 7 = 1: display reverse video
ScrPtr		.ds 2		; current display data
tmp		.ds 1
tmp1		.ds 1
tmp2		.ds 1
tmp3		.ds 1
tmp4		.ds 1
DLICount	.ds 1
PrevEntry	.ds 1		; previously highlighted item
CurrEntry	.ds 1		; selected item (0-19)
CurrEntryPtr	.ds 2		; pointer to selected item
Entry		.ds 1		; current item being displayed
Entries		.ds 1		; total number of entries in list
MessageFlag	.ds 1
TriggerState	.ds 1
StickState	.ds 1
MotionFlag	.ds 1
Timer		.ds 1
BootFlag	.ds 1
MenuUpFlag	.ds 1
DirLevel	.ds 1		; keeps track of where we are in the directory tree
WaitCmdFlag	.ds 1
MsgPtr		.ds 2
TextLineCount	.ds 1
TempPtr		.ds 2
WinY		.ds 1
Height		.ds 1



DOSINI	equ $0C
MEMLO	equ $02E7
RunVec	equ $02E0
IniVec	equ $02E2

CIOV	equ $E456
GINTLK	equ	$03FA
TRIG3	equ $D013

FMSZPG	equ	$43
Critic	equ $42

COLDST	equ $0244
BASICF	equ $3f8
RAMTOP	equ $6A
WARMST	equ $08
DOSVEC	equ $0A
RAMSIZ	equ $02E4
MEMTOP	equ $02E5

BOOT		equ $09
CASINI		equ $02

IOPtr		equ FMSZPG
FileSize	equ FMSZPG+2 ; .ds 4
ptr1		equ FMSZPG
ptr2		equ FMSZPG+2
ptr3		equ FMSZPG+4


	.struct IOCBlock
ID		.byte
DevNum	.byte
Command	.byte
Status	.byte
Address	.word
Put		.word	; put byte address
Len		.word
Aux1	.byte 	
Aux2	.byte
Aux3	.byte
Aux4	.byte
Aux5	.byte
Aux6	.byte
	.ends
	
	org $0340

IOCB	dta IOCBlock [8]

;	CIO commands

	.enum IOCommand
Open	= $03
GetText	= $05
Read	= $07
PutText	= $09
Write	= $0B
Close	= $0C
Status	= $0D
	.ende
	
;	CIO aux values

	.enum IOMode
Read	= $04
Dir		= $06
Create	= $08
Append	= $09
Update	= $0C
	.ende
	
	
;	CIO Error Codes

	.enum IOErr
AlreadyOpen	= 129
NotOpen		= 133
EOF			= 136
NAK			= 139
NoFunction	= 146
BadName		= 165
NotFound	= 170
	.ende

//
// Display List constants
//

.enum	DL
	Mode2	= $02
	Mode3	= $03
	ModeE	= $0E
	ModeF	= $0F
	LMS	= $40
	NMI	= $80
	Blank1	= $00
	Blank2	= $10
	Blank3	= $20
	Blank4	= $30
	Blank5	= $40
	Blank6	= $50
	Blank7	= $60
	Blank8	= $70
	VBL	= $41
.ende



.enum	Key
	Esc	= 27
	X	= 88
	Z	= 90
	U	= 85
	Up	= 45
	Down	= 61
	Left	= 43
	Right	= 42
	Space	= 32
	CtrlUp	= 28
	CtrlDn	= 29
	CtrlLt	= 30
	CtrlRt	= 31
	Return	= 155
	Delete	= 126
	CtrlShiftUp	= 156
	CtrlShiftDown	= 157
	.ende

TextLineLenTab	equ $1F00
ColourTable	equ $1F80
OSVBI		equ $1FF0
OSDLI		equ $1FF2
FrameBuffer	equ $2000		; keep this low so it works on a 600XL

//
//	OS Equats
//

// POKEY

POKEY1	equ	$D200
POKEY2	equ	$D210
KBCODE	equ	$D209
IRQEN	equ	$D20E
IRQST	equ	$D20E
SKSTAT	equ	$D20F
SKCTL	equ	$D20F


// ANTIC

DMACTL	equ	$D400
CHRCTL	equ	$D401
DLPTR	equ	$D402
HSCROL	equ	$D404
VSCROL	equ	$D405
PMBASE	equ	$D407
CHBASE	equ	$D409
WSYNC	equ	$D40A
VCOUNT	equ	$D40B
LPENH	equ	$D40C
LPENV	equ	$D40D
NMIEN	equ	$D40E
NMIST	equ	$D40F
NMIRES	equ	$D40F


// GTIA

HPosP0	equ $D000
HPosP1	equ $D001
HPosP2	equ $D002
HPosP3	equ $D003
HPosM0	equ $D004
HPosM1	equ $D005
HPosM2	equ $D006
HPosM3	equ $D007

SizeP0	equ $D008
SizeP1	equ $D009
SizeP2	equ $D00A
SizeP3	equ $D00B
SizeM	equ $D00C
GrafP0	equ $D00D
GrafP1	equ $D00E
GrafP2	equ $D00F
GrafP3	equ $D010
Trig0	equ $D010

ColPM0	equ $D012
ColPM1	equ $D013
ColPM2	equ $D014
ColPM3	equ $D015
COLPF0	equ $D016
COLPF1	equ $D017
COLPF2	equ $D018
COLPF3	equ $D019
COLBAK	equ $D01A
Prior	equ $D01B
VDelay	equ $D01C
Gractl	equ $D01D
CONSOL	equ $D01F

// PIA

PORTA	equ	$D300
PORTB	equ	$D301
PACTL	equ	$D302
PBCTL	equ	$D303

// Shadow registers

VDSLST	equ	$200
VKEYBD	equ	$208
VIMIRQ	equ 	$216
VVBLKI	equ	$222
VVBLKD	equ	$224
GPRIOR	equ	$26F
SDMCTL	equ 	$22F
SDLSTL	equ	$230
STICK0	equ	$278
STICK1	equ	$279
STRIG0	equ	$284
STRIG1	equ	$285
CHBAS	equ	$2F4





