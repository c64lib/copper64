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
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2-global.asm"
#import "text/lib/text.asm"
#import "common/lib/invoke-global.asm"
#import "../lib/copper64-global.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATE_BUFFER = $05
.label ANIMATION_DELAY_COUNTER = $06
.label CHARSET = $6808

.label DELAY = 2

.label BITMAP_BANK = 0
.label BITMAP_SCREEN_BANK = 8
.label TEXT_SCREEN_BANK = 9
.label TEXT_CHARSET_BANK = 5

.var gfxTemplate = "Header=0,Bitmap=2,Screen=8002"
.var gfx  = LoadBinary("frog.art", gfxTemplate)

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$080d "Program"

start:

  sei
  .namespace c64lib {
    setVICBank(%10)
    configureMemory(c64lib.RAM_IO_RAM)
    setVideoMode(c64lib.STANDARD_BITMAP_MODE)
    configureBitmapMemory(BITMAP_SCREEN_BANK, BITMAP_BANK)
    disableNMI()
    disableCIAInterrupts()
  }
  cli

  jsr unpack

  lda #DELAY
  sta ANIMATION_DELAY_COUNTER

  c64lib_pushParamW(c64lib.COLOR_RAM)
  lda #LIGHT_GREY
  jsr fillScreen

  lda #BLUE
  sta c64lib.BG_COL_0
  lda #BLACK
  sta c64lib.BORDER_COL
  
  c64lib_pushParamW($6400)
  lda #$01
  jsr fillScreen
     
  jsr initCopper
  jsr startCopper
block:
  jmp block
  
unpack: {

  // unpack charset
  c64lib_pushParamW(charsetPacked)
  c64lib_pushParamW($6800)
  c64lib_pushParamW(16)
  jsr copyLargeMemForward
  
  // unpack screen mem
  c64lib_pushParamW(screenPacked)
  c64lib_pushParamW($6000)
  c64lib_pushParamW(gfx.getScreenSize())
  jsr copyLargeMemForward
  
  // unpack bitmap
  c64lib_pushParamW(bitmapPacked)
  c64lib_pushParamW($4000)
  c64lib_pushParamW(gfx.getBitmapSize())
  jsr copyLargeMemForward
  
  rts
}
  
initCopper: {
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  rts
}

animateCharset: {
  c64lib_debugBorderStart()
  dec ANIMATION_DELAY_COUNTER
  beq next
  c64lib_debugBorderEnd()
  rts
next:
  lda #DELAY
  sta ANIMATION_DELAY_COUNTER
  lda CHARSET 
  sta ANIMATE_BUFFER
  lda CHARSET+1
  sta CHARSET
  lda CHARSET+2
  sta CHARSET+1
  lda CHARSET+3
  sta CHARSET+2
  lda CHARSET+4
  sta CHARSET+3
  lda CHARSET+5
  sta CHARSET+4
  lda CHARSET+6
  sta CHARSET+5
  lda CHARSET+7
  sta CHARSET+6
  lda ANIMATE_BUFFER
  sta CHARSET+7
  c64lib_debugBorderEnd()
  rts
}

startCopper: c64lib_startCopper(
                                    DISPLAY_LIST_PTR_LO, 
                                    LIST_PTR, 
                                    List().add(c64lib.IRQH_MODE_MEM, c64lib.IRQH_BG_COL_0, c64lib.IRQH_JSR).lock())
fillScreen:
                #import "common/lib/sub/fill-screen.asm"
copyLargeMemForward: 
                #import "common/lib/sub/copy-large-mem-forward.asm"

.print copperList
here:
.print here

.align $100
copperList: {
  c64lib_copperEntry(11, c64lib.IRQH_JSR, <animateCharset, >animateCharset)
  c64lib_copperEntry(52, c64lib.IRQH_BG_COL_0, DARK_GREY, 0)
  c64lib_copperEntry(56, c64lib.IRQH_BG_COL_0, BLUE, 0)
  c64lib_copperEntry(113, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_1_BMM, c64lib_getBitmapMemory(BITMAP_SCREEN_BANK, BITMAP_BANK))
  c64lib_copperEntry(193, c64lib.IRQH_MODE_MEM, 0, c64lib_getTextMemory(TEXT_SCREEN_BANK, TEXT_CHARSET_BANK))
  c64lib_copperEntry(241, c64lib.IRQH_BG_COL_0, DARK_GREY, 0)
  c64lib_copperEntry(246, c64lib.IRQH_BG_COL_0, GREY, 0)
  c64lib_copperLoop()
}

.print bitmapPacked
bitmapPacked: .fill gfx.getBitmapSize(), gfx.getBitmap(i)
  
.print screenPacked
screenPacked: .fill gfx.getScreenSize(), gfx.getScreen(i)

charsetPacked:
  .byte 0, 0, 0, 0, 0, 0, 0, 0
  .byte 0
  .byte %00001110
  .byte %00011100
  .byte %00111110
  .byte %00001100
  .byte %00011000
  .byte %00010000
  .byte 0
