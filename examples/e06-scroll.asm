/*
 * c64lib/copper64/examples/e06-scroll.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_BG_RASTER_BAR
#define IRQH_HSCROLL
#define IRQH_JSR

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "text/scroll1x1.asm"
#import "../copper64.asm"

// zero page addresses
.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATION_IDX = $05
.label BAR_DEFS_IDX = $06
.label SCROLL_TEMP = $07 // and $08
.label SCROLL_OFFSET = $09

// constants
.label SCREEN_PTR = 1024
.label SCROLL_POSITION = 20
.label SCROLL_POSITION_OFFSET = 20*40
.label SCROLL_COLOR_BARS_LINE = SCROLL_POSITION * 8 + $33 - 2
.label SCROLL_HSCROLL_LINE_START = SCROLL_COLOR_BARS_LINE - 5 
.label SCROLL_HSCROLL_LINE_END = SCROLL_HSCROLL_LINE_START + 10 * 8 


//.var music = LoadSid("Noisy_Pillars_tune_1.sid")

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$3000 "Program"

start:

//  jsr initSound

  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  configureMemory(c64lib.RAM_IO_RAM)
  
  jsr initScreen
  jsr initCopper
  jsr initScroll
  
  lda #00
  sta ANIMATION_IDX
  sta BAR_DEFS_IDX

  // initialize copper64 routine
  jsr copper
block:
  jmp block
  
initScreen: 
  .namespace c64lib {
  
    // set up colors
    lda #BLACK
    sta BORDER_COL
    sta BG_COL_0
    
    // narrow screen to enable scrolling
    lda CONTROL_2
    and #neg(CONTROL_2_CSEL)
    sta CONTROL_2
    
    rts
  }

  
initCopper: {
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  rts
}

initScroll: {
  lda #$00
  sta SCROLL_OFFSET
  rts  
}

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

doScroll: {
  lda SCROLL_OFFSET
  cmp #$00
  bne decOffset
  lda #7
  sta SCROLL_OFFSET
  pushParamW(SCREEN_PTR + SCROLL_POSITION_OFFSET)
  pushParamW(scrollText)
  pushParamWInd(scrollPtr)
  jsr scroll
  pullParamW(scrollPtr)
  jmp fineScroll
decOffset:
  sbc #1
  sta SCROLL_OFFSET
fineScroll:
  lda SCROLL_OFFSET
  sta hscroll + 2
  rts
}


.align $100
sineData:   .fill 256, round(100 + 50*sin(toRadians(i*360/256)))

.align $100
copperList:
  copperEntry(0, c64lib.IRQH_JSR, <doScroll, >doScroll)
  hscroll: copperEntry(SCROLL_HSCROLL_LINE_START, c64lib.IRQH_HSCROLL, 5, 0)
  copperEntry(SCROLL_COLOR_BARS_LINE, c64lib.IRQH_BG_RASTER_BAR, <scrollBarDef, >scrollBarDef)
  copperEntry(SCROLL_HSCROLL_LINE_END, c64lib.IRQH_HSCROLL, 0, 0)

  //copperEntry(257, c64lib.IRQH_JSR, <playMusic, >playMusic)
  copperLoop()

// library hosted functions
copper:     initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
outHex:     outHex()
scroll:     scroll1x1(SCROLL_TEMP)

// variables
counterPtr:   .byte 0
screenPtr:    .word SCREEN_PTR
scrollText:   .text "hello world i'm jan b. this is my first scroll on c64 so please be polite. i just want to check that it is working                              "
              .byte $ff
scrollPtr:    .word scrollText
scrollBarDef: .byte GREY, LIGHT_GREY, WHITE, WHITE, WHITE, LIGHT_GREY, GREY, BLACK, $ff

//*=music.location "Music"
//.fill music.size, music.getData(i)
