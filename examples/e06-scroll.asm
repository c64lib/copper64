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
 
// #define VISUAL_DEBUG
#define IRQH_BG_RASTER_BAR
#define IRQH_HSCROLL
#define IRQH_JSR
#define IRQH_HSCROLL_MAP

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "chipset/cia.asm"
#import "text/text.asm"
#import "text/scroll1x1.asm"
#import "common/mem-global.asm"
#import "common/invoke-global.asm"
#import "../copper64.asm"

// zero page addresses
.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATION_IDX = $05
.label BAR_DEFS_IDX = $06
.label SCROLL_TEMP = $07 // and $08
.label SCROLL_OFFSET = $09
.label CYCLE_CNTR = $0A

// constants
.label SCREEN_PTR = 1024

.label LOGO_POSITION = 4
.label LOGO_LINE = LOGO_POSITION * 8 + $33 - 4
.label TECH_TECH_WIDTH = 5*8

.label CREDITS_POSITION = 16
.label CREDITS_COLOR_BARS_LINE = CREDITS_POSITION * 8 + $33 - 3

.label SCROLL_POSITION = 23
.label SCROLL_POSITION_OFFSET = SCROLL_POSITION * 40
.label SCROLL_COLOR_BARS_LINE = SCROLL_POSITION * 8 + $33 - 2
.label SCROLL_HSCROLL_LINE_START = SCROLL_COLOR_BARS_LINE - 5 
.label SCROLL_HSCROLL_LINE_END = SCROLL_HSCROLL_LINE_START + 10 + 8 


.var music = LoadSid("Noisy_Pillars_tune_1.sid")

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$080d "Program"

start:
  sei
  .namespace c64lib {
    // reconfigure C64 memory
    configureMemory(RAM_IO_RAM)
    // disable NMI interrupt in a lame way
    disableNMI()
    // disable CIA as interrupt sources
    disableCIAInterrupts()
  }
  cli
  
  jsr unpack
  jsr initSound
  jsr initScreen
  jsr initCopper
  jsr initScroll

  // initialize internal data structures  
  lda #00
  sta ANIMATION_IDX
  sta BAR_DEFS_IDX
  sta CYCLE_CNTR

  // initialize copper64 routine
  jsr startCopper
block:
  // go to infinite loop, rest will be done in interrupts
  jmp block
  
initScreen: 
  .namespace c64lib {
  
    // set up colors
    lda #BLACK
    sta BORDER_COL
    sta BG_COL_0
    
    // clear screen
    pushParamW(SCREEN_PTR)
    lda #($20 + 128)
    jsr fillScreen
    pushParamW(COLOR_RAM)
    lda #BLACK
    jsr fillScreen
    
    // tech tech logo
    pushParamW(logoLine1)
    pushParamW(SCREEN_PTR + getTextOffset(0, LOGO_POSITION))
    jsr outText
    
    pushParamW(COLOR_RAM + getTextOffset(0, LOGO_POSITION))
    ldx #(5*40)
    lda #WHITE
    jsr fillMem
    
    // -- credits --
    pushParamW(creditsText1)
    pushParamW(SCREEN_PTR + getTextOffset(0, CREDITS_POSITION))
    jsr outText
    pushParamW(creditsText2)
    pushParamW(SCREEN_PTR + getTextOffset(0, CREDITS_POSITION + 2))
    jsr outText
    
    // -- scroll --
       
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
  
playMusic: {
  debugBorderStart()
  jsr music.play
  debugBorderEnd()
  rts
}

initSound: {
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  rts
}

doScroll: {
  debugBorderStart()
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
  debugBorderEnd()
  rts
}

doColorCycle: {
  debugBorderStart()
  
  // tech tech
  pushParamW(hscrollMapDef)
  ldx #(TECH_TECH_WIDTH-1)
  jsr rotateMemRight
  
  // font effects via raster bars
  inc CYCLE_CNTR
  lda CYCLE_CNTR
  cmp #4
  beq doCycle
  debugBorderEnd()
  rts
doCycle:
  lda #0
  sta CYCLE_CNTR
  pushParamW(colorCycleDef + 1)
  ldx #6
  jsr rotateMemRight
  debugBorderEnd()
  rts
}
unpack: {
  pushParamW(musicData)
  pushParamW(music.location)
  pushParamW(music.size)
  jsr copyLargeMemForward
  rts
}
endOfCode:

.align $100
copperList:
  copperEntry(0, c64lib.IRQH_JSR, <doScroll, >doScroll)
  copperEntry(25, c64lib.IRQH_JSR, <doColorCycle, >doColorCycle)
  copperEntry(LOGO_LINE, c64lib.IRQH_HSCROLL_MAP, <hscrollMapDef, >hscrollMapDef)
  copperEntry(CREDITS_COLOR_BARS_LINE, c64lib.IRQH_BG_RASTER_BAR, <colorCycleDef, >colorCycleDef)
  copperEntry(CREDITS_COLOR_BARS_LINE + 16, c64lib.IRQH_BG_RASTER_BAR, <colorCycleDef, >colorCycleDef)
  hscroll: copperEntry(SCROLL_HSCROLL_LINE_START, c64lib.IRQH_HSCROLL, 5, 0)
  copperEntry(SCROLL_COLOR_BARS_LINE, c64lib.IRQH_BG_RASTER_BAR, <scrollBarDef, >scrollBarDef)
  copperEntry(SCROLL_HSCROLL_LINE_END, c64lib.IRQH_HSCROLL, 0, 0)

  copperEntry(257, c64lib.IRQH_JSR, <playMusic, >playMusic)
  copperLoop()

// library hosted functions
startCopper:    .namespace c64lib { _startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR) }
outHex:         .namespace c64lib { _outHex() }
outText:        .namespace c64lib { _outText() }
scroll:         .namespace c64lib { _scroll1x1(SCROLL_TEMP) }
fillMem:        .namespace c64lib { _fillMem() }
rotateMemRight: 
                #import "common/sub/rotate-mem-right.asm"
fillScreen:     .namespace c64lib { _fillScreen() }
copyLargeMemForward: 
                #import "common/sub/copy-large-mem-forward.asm"
endOfLibs:

// variables
screenPtr:      .word SCREEN_PTR
scrollText:     incText(
                    "  3...      2...      1...      go!      "
                    +"hi folks! this simple intro has been written to demonstrate capabilities of copper64 library "
                    +"which is a part of c64lib project. there's little tech tech animation of ascii logo, some old shool "
                    +"font effect and lame 1x1 scroll that you're reading right now. c64lib is freely available on "
                    +"https://github.com/c64lib     that's all for now, i don't have any more ideas for this text.                 ", 
                    128) 
                .byte $ff
creditsText1:   incText("          code by  maciek malecki", 128); .byte $ff
creditsText2:   incText("         music by  jeroen tel", 128); .byte $ff                
logoLine1:      .text " ---===--- ---===--- ---===--- ---===-  "
                .text " ccc 666 4 4 l   i bbb ddd eee mmm ooo  "
                .text " c   6 6 444 l   i b b d d e   m m o o  "
                .text " ccc 666   4 lll i bbb ddd eee m m ooo  "
                .text " -===--- ---===--- ---===--- ---===---  "; .byte $ff            
scrollPtr:      .word scrollText
scrollBarDef:   .byte GREY, LIGHT_GREY, WHITE, WHITE, LIGHT_GREY, GREY, GREY, BLACK, $ff
colorCycleDef:  .byte BLACK, RED, RED, BROWN, RED, LIGHT_RED, YELLOW, WHITE, BLACK, $ff
hscrollMapDef:  .fill TECH_TECH_WIDTH, round(3.5 + 3.5*sin(toRadians(i*360/TECH_TECH_WIDTH))) ; .byte 0; .byte $ff
endOfVars:

//*=music.location "Music"
musicData:
.fill music.size, music.getData(i)

endOfProg:

.print "End of code = " + toHexString(endOfCode)
.print "Copper list = " + toHexString(copperList)
.print "Size of vars = " + (endOfVars - screenPtr)
.print "Size of libs = " + (endOfLibs - startCopper)
.print "Size of all = " + (endOfProg - start)
