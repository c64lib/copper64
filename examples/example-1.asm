/*
 * c64lib/copper64/examples/example-1.asm
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

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "../copper64.asm"

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
  lda #$00
  sta COUNTER_PTR
  .for (var i = 0; i < 25; i++) {
    outByteHex(COUNTER_PTR, 1024, 0, i, BLACK, hexChars)
    outByteHex(COUNTER_PTR, 1024, 38, i, BLACK, hexChars)
    inc COUNTER_PTR
  }

  // initialize sound  
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
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
  
copper: {
  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
copperList: {
  copperEntry(48,  c64lib.IRQH_BORDER_COL, WHITE, 0)
  copperEntry(101, c64lib.IRQH_BG_COL_0, YELLOW, 0)
  copperEntry(121, c64lib.IRQH_BG_COL_0, RED, 0)
  copperEntry(144, c64lib.IRQH_BG_COL_0, GREY, 0)
  copperEntry(157, c64lib.IRQH_BG_COL_0, BLUE, 0)
  copperEntry(163, c64lib.IRQH_BORDER_COL, LIGHT_BLUE, 0)
  copperEntry(220, c64lib.IRQH_BORDER_BG_0_COL, LIGHT_GREY, $00)
  copperEntry(230, c64lib.IRQH_BORDER_BG_0_DIFF, LIGHT_BLUE, BLUE)
  copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
  copperLoop()
}

hexChars:
	.text "0123456789abcdef"

*=music.location "Music"
.fill music.size, music.getData(i)

