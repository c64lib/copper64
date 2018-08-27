/*
 * c64lib/copper64/examples/e01-color-raster-bars.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_BORDER_COL
#define IRQH_BG_COL_0
#define IRQH_BORDER_BG_0_COL
#define IRQH_BORDER_BG_0_DIFF
#define IRQH_JSR

#import "common/invoke.asm"
#import "common/mem.asm"
#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "../copper64.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04

.label SCREEN_PTR = 1024

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$3000 "Program"

start:

  jsr drawMarks
  
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  configureMemory(c64lib.RAM_IO_RAM)
  
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI

  // initialize copper64 routine
  jsr startCopper
block:
  nop
  lda $ff00
  lda $ff00,y
  jmp block
  
drawMarks: {

  pushParamW(helloWorld); pushParamW(SCREEN_PTR + getTextOffset(10, 14)); jsr outText
  
  lda #$00
  sta counterPtr
  
nextRow:
  pushParamW(counterPtr); pushParamWInd(screenPtr); jsr outHex
  add16(38, screenPtr)
  pushParamW(counterPtr); pushParamWInd(screenPtr); jsr outHex
  add16(2, screenPtr)
  inc counterPtr
  lda counterPtr
  cmp #25
  bne nextRow
  rts
}
  
outHex:      .namespace c64lib { _outHex() }
outText:	 .namespace c64lib { _outText() }
startCopper: .namespace c64lib { _startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR) }

.align $100
copperList: {

  copperEntry(46, c64lib.IRQH_BORDER_COL, WHITE, 0)
  copperEntry(81, c64lib.IRQH_BG_COL_0, YELLOW, 0)
  copperEntry(101, c64lib.IRQH_BG_COL_0, LIGHT_GREEN, 0)
  copperEntry(124, c64lib.IRQH_BG_COL_0, GREY, 0)
  copperEntry(131, c64lib.IRQH_BG_COL_0, BLUE, 0)
  copperEntry(150, c64lib.IRQH_BORDER_COL, RED, 0)
  copperEntry(216, c64lib.IRQH_BORDER_BG_0_COL, LIGHT_GREY, $00)
  copperEntry(221, c64lib.IRQH_BORDER_BG_0_COL, GREY, $00)
  copperEntry(227, c64lib.IRQH_BORDER_BG_0_COL, DARK_GREY, $00)
  copperEntry(232, c64lib.IRQH_BORDER_BG_0_DIFF, RED, BLUE)
  copperEntry(252, c64lib.IRQH_BORDER_COL, LIGHT_BLUE, 0)
  copperLoop()
}

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
helloWorld: .text "*** hello world ***" 
			.byte $FF
