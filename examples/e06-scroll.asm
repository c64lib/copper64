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

#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2-global.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text-global.asm"
#import "text/lib/scroll1x1-global.asm"
#import "common/lib/mem-global.asm"
#import "common/lib/invoke-global.asm"
#import "../lib/copper64-global.asm"

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
  c64lib_debugBorderStart()
  jsr music.play
  c64lib_debugBorderEnd()
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
  c64lib_debugBorderStart()
  lda SCROLL_OFFSET
  cmp #$00
  bne decOffset
  lda #7
  sta SCROLL_OFFSET
  c64lib_pushParamW(SCREEN_PTR + SCROLL_POSITION_OFFSET)
  c64lib_pushParamW(scrollText)
  c64lib_pushParamWInd(scrollPtr)
  jsr scroll
  c64lib_pullParamW(scrollPtr)
  jmp fineScroll
decOffset:
  sbc #1
  sta SCROLL_OFFSET
fineScroll:
  lda SCROLL_OFFSET
  sta hscroll + 2
  c64lib_debugBorderEnd()
  rts
}

doColorCycle: {
  c64lib_debugBorderStart()
  
  // tech tech
  c64lib_pushParamW(hscrollMapDef)
  ldx #(TECH_TECH_WIDTH-1)
  jsr rotateMemRight
  
  // font effects via raster bars
  inc CYCLE_CNTR
  lda CYCLE_CNTR
  cmp #4
  beq doCycle
  c64lib_debugBorderEnd()
  rts
doCycle:
  lda #0
  sta CYCLE_CNTR
  c64lib_pushParamW(colorCycleDef + 1)
  ldx #6
  jsr rotateMemRight
  c64lib_debugBorderEnd()
  rts
}
unpack: {
  c64lib_pushParamW(musicData)
  c64lib_pushParamW(music.location)
  c64lib_pushParamW(music.size)
  jsr copyLargeMemForward
  rts
}
endOfCode:

.align $100
copperList:
  c64lib_copperEntry(0, c64lib.IRQH_JSR, <doScroll, >doScroll)
  c64lib_copperEntry(25, c64lib.IRQH_JSR, <doColorCycle, >doColorCycle)
  c64lib_copperEntry(LOGO_LINE, c64lib.IRQH_HSCROLL_MAP, <hscrollMapDef, >hscrollMapDef)
  c64lib_copperEntry(CREDITS_COLOR_BARS_LINE, c64lib.IRQH_BG_RASTER_BAR, <colorCycleDef, >colorCycleDef)
  c64lib_copperEntry(CREDITS_COLOR_BARS_LINE + 16, c64lib.IRQH_BG_RASTER_BAR, <colorCycleDef, >colorCycleDef)
  hscroll: c64lib_copperEntry(SCROLL_HSCROLL_LINE_START, c64lib.IRQH_HSCROLL, 5, 0)
  c64lib_copperEntry(SCROLL_COLOR_BARS_LINE, c64lib.IRQH_BG_RASTER_BAR, <scrollBarDef, >scrollBarDef)
  c64lib_copperEntry(SCROLL_HSCROLL_LINE_END, c64lib.IRQH_HSCROLL, 0, 0)

  c64lib_copperEntry(257, c64lib.IRQH_JSR, <playMusic, >playMusic)
  c64lib_copperLoop()

// library hosted functions
startCopper:    c64lib_startCopper(
                                        DISPLAY_LIST_PTR_LO, 
                                        LIST_PTR, 
                                        List().add(c64lib.IRQH_BG_RASTER_BAR, c64lib.IRQH_HSCROLL, c64lib.IRQH_JSR, c64lib.IRQH_HSCROLL_MAP).lock())
scroll:         c64lib_scroll1x1(SCROLL_TEMP)
outHex:         
                #import "text/lib/sub/out-hex.asm"
outText:        
                #import "text/lib/sub/out-text.asm"
fillMem:
                #import "common/lib/sub/fill-mem.asm"
rotateMemRight: 
                #import "common/lib/sub/rotate-mem-right.asm"
fillScreen:
                #import "common/lib/sub/fill-screen.asm"
copyLargeMemForward: 
                #import "common/lib/sub/copy-large-mem-forward.asm"
endOfLibs:

// variables
screenPtr:      .word SCREEN_PTR
scrollText:     c64lib_incText(
                    "  3...      2...      1...      go!      "
                    +"hi folks! this simple intro has been written to demonstrate capabilities of copper64 library "
                    +"which is a part of c64lib project. there's little tech tech animation of ascii logo, some old shool "
                    +"font effect and lame 1x1 scroll that you're reading right now. c64lib is freely available on "
                    +"https://github.com/c64lib     that's all for now, i don't have any more ideas for this text.                 ", 
                    128) 
                .byte $ff
creditsText1:   c64lib_incText("          code by  maciek malecki", 128); .byte $ff
creditsText2:   c64lib_incText("         music by  jeroen tel", 128); .byte $ff                
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
