/*
 * c64lib/copper64/examples/e04-full-raster-bars.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_HSCROLL
#define IRQH_JSR

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "text/scroll1x1.asm"
#import "../copper64.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATION_IDX = $05
.label BAR_DEFS_IDX = $06
.label SCROLL_TEMP = $07 // and $08
.label SCREEN_PTR = 1024


//.var music = LoadSid("Noisy_Pillars_tune_1.sid")

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$3000 "Program"

start:

  jsr drawMarks
//  jsr initSound

  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  configureMemory(c64lib.RAM_IO_RAM)
  
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  
  lda #00
  sta ANIMATION_IDX
  sta BAR_DEFS_IDX

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
  /*
playMusic: {
  inc c64lib.BORDER_COL
  jsr music.play
  dec c64lib.BORDER_COL
  rts
}*/
/*
initSound: {
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  rts
}*/

drawMarks: {
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

doScroll: {
  pushParamW(SCREEN_PTR)
  pushParamW(scrollText)
  pushParamWInd(scrollPtr)
  jsr scroll
  pullParamW(scrollPtr)
  
  pushParamW(scrollPtr)
  pushParamW(SCREEN_PTR + 44)
  jsr outHex
  
  pushParamW(scrollPtr + 1)
  pushParamW(SCREEN_PTR + 42)
  jsr outHex
  
  pushParamWInd(SCROLL_TEMP)
  pushParamW(SCREEN_PTR + 84)
  jsr outHex
  
  pushParamWInd(SCROLL_TEMP + 1)
  pushParamW(SCREEN_PTR + 82)
  jsr outHex
  rts
}

copper: {
  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
sineData:   .fill 256, round(100 + 50*sin(toRadians(i*360/256)))
.align $100
copperList:
  hscroll: copperEntry(96, c64lib.IRQH_HSCROLL, 5, 0)
  copperEntry(105, c64lib.IRQH_HSCROLL, 0, 0)
  copperEntry(120, c64lib.IRQH_JSR, <doScroll, >doScroll)
  //copperEntry(257, c64lib.IRQH_JSR, <playMusic, >playMusic)
  copperLoop()

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
outHex:     outHex()
scroll:     scroll1x1(SCROLL_TEMP)
scrollText: .text "hello world i'm jan b. this is my first scroll on c64 so please be polite. i just want to check that it is working                              "
            .byte $ff
            .print "scrollText: " + toHexString(scrollText)
scrollPtr:  .word scrollText
            .print "scrollPtr: "  + toHexString(scrollPtr)

//*=music.location "Music"
//.fill music.size, music.getData(i)
