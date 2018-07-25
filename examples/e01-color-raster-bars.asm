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

.var music = LoadSid("Noisy_Pillars_tune_1.sid")
.print "SID Music details"
.print "-----------------"
.print "name: " + music.name
.print "author: " + music.author
.print "location: $" + toHexString(music.location)
.print "size: $" + toHexString(music.size)
.print "init: $" + toHexString(music.init)
.print "play: $" + toHexString(music.play)
.print "start song: " + music.startSong

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$3000 "Program"

start:

  jsr drawMarks
  jsr initSound
  
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  configureMemory(c64lib.RAM_IO_RAM)
  
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI

  // initialize copper64 routine
  jsr copper
block:
  nop
  lda $ff00
  lda $ff00,y
  jmp block
  
custom1:  
  inc c64lib.BORDER_COL
  jsr music.play
  dec c64lib.BORDER_COL
  rts
  
initSound: {
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  rts
}

drawMarks: {

  pushWordParamV(helloWorld)
  pushWordParamV(SCREEN_PTR + getTextOffset(10, 14))
  jsr outText
  
  lda #$00
  sta counterPtr
  
nextRow:
  pushWordParamV(counterPtr); pushWordParamPtr(screenPtr); jsr outHex
  add16(38, screenPtr)
  pushWordParamV(counterPtr); pushWordParamPtr(screenPtr); jsr outHex
  add16(2, screenPtr)
  inc counterPtr
  lda counterPtr
  cmp #25
  bne nextRow
  rts
}
  
copper: {
  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

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
  copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
  copperLoop()
}

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
outHex:     outHex()
outText:	outText()
helloWorld: .text "*** hello world ***" 
			.byte $FF

*=music.location "Music"
.fill music.size, music.getData(i)
