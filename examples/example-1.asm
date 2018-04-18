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
#define IRQH_MEM
#define IRQH_MODE
#define IRQH_JSR
//#define VISUAL_DEBUG

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "../copper64.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04

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

.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // Basic start routine

// Main program
.pc = $0810 "Program"

start:
  // initialize sound  
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  :configureMemory(c64lib.RAM_IO_RAM)
  
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
  copperEntry(81,  c64lib.IRQH_BORDER_COL, WHITE, 0)
  copperEntry(100, c64lib.IRQH_BG_COL_0, YELLOW, 0)
  copperEntry(120, c64lib.IRQH_BG_COL_0, RED, 0)
  copperEntry(144, c64lib.IRQH_BG_COL_0, GREY, 0)
  copperEntry(157, c64lib.IRQH_BG_COL_0, BLUE, 0)
  copperEntry(161, c64lib.IRQH_BORDER_COL, LIGHT_BLUE, 0)
  copperEntry(169, c64lib.IRQH_MODE, $00, c64lib.CONTROL_2_MCM)
  copperEntry(195, c64lib.IRQH_MEM, getTextMemory(0, 2), 0)
  copperEntry(211, c64lib.IRQH_MEM, getTextMemory(1, 2), 0)
  copperEntry(215, c64lib.IRQH_MODE, $00, $00)
  copperEntry(220, c64lib.IRQH_BORDER_BG_0_COL, GREEN, $00)
  copperEntry(241, c64lib.IRQH_BORDER_BG_0_DIFF, LIGHT_BLUE, BLUE)
  copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
  copperLoop()
}

*=music.location "Music"
.fill music.size, music.getData(i)

