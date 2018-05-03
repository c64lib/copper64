/*
 * c64lib/copper64/examples/e03-bitmap-demo.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_MODE_MEM
#define IRQH_JSR

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "../copper64.asm"
#import "e03-gfx.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label COUNTER_PTR = $05

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

  // initialize sound  
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  lda #BLACK
  sta c64lib.BG_COL_0
  lda #GREEN
  sta c64lib.BORDER_COL
  setVICBank(%10)
  configureMemory(c64lib.RAM_IO_RAM)
  setVideoMode(c64lib.MULTICOLOR_BITMAP_MODE)
  configureBitmapMemory(8, 0)
  
  // copy color ram
  ldy #$00
copyLoop:
  lda colorMemory, y
  sta c64lib.COLOR_RAM, y
  lda colorMemory + $100, y
  sta c64lib.COLOR_RAM + $100, y
  lda colorMemory + $200, y
  sta c64lib.COLOR_RAM + $200, y
  lda colorMemory + $300, y
  sta c64lib.COLOR_RAM + $300, y
  iny
  bne copyLoop
  
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
  sta $ff00
  nop
  nop
  lda $ff00
  lda $ff
  lda $ffff
  jmp block
custom1:  
  inc c64lib.BORDER_COL
  jsr music.play
  dec c64lib.BORDER_COL
  rts
  
copper: {
  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
copperList: {
  //copperEntry(85, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_1_BMM, getBitmapMemory(0, 0))
  //copperEntry(133, c64lib.IRQH_MODE_MEM, 0, getTextMemory(1, 2))
  //copperEntry(166, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM, getTextMemory(0, 2))
  //copperEntry(177, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM | c64lib.CONTROL_1_BMM, getBitmapMemory(0, 1))
  //copperEntry(213, c64lib.IRQH_MODE_MEM, 0, getTextMemory(1, 2))
  copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
  copperLoop()
}

hexChars:
	.text "0123456789abcdef"

*=music.location "Music"
.fill music.size, music.getData(i)

