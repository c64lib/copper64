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
#import "common/lib/invoke.asm"
#import "common/lib/mem.asm"
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2-global.asm"
#import "chipset/lib/cia.asm"
#import "text/lib/text.asm"
#import "common/lib/math-global.asm"
#import "common/lib/invoke-global.asm"
#import "../lib/copper64-global.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04

.label SCREEN_PTR = 1024

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$080d "Program"

start:
 
  sei
  .namespace c64lib {
    configureMemory(RAM_IO_RAM)
    disableNMI()
    disableCIAInterrupts()
  }
  cli
  
  jsr drawMarks
  jsr initCopper

  // initialize copper64 routine
  jsr startCopper
block:
  // go into endless loop
  jmp block
  
initCopper: {
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  rts
}
  
drawMarks: {

  c64lib_pushParamW(helloWorld); 
  c64lib_pushParamW(SCREEN_PTR + c64lib_getTextOffset(10, 14)); 
  jsr outText
  
  lda #$00
  sta counterPtr
  
nextRow:
  c64lib_pushParamW(counterPtr); 
  c64lib_pushParamWInd(screenPtr)
  jsr outHex
  
  c64lib_add16(38, screenPtr)
  c64lib_pushParamW(counterPtr); 
  c64lib_pushParamWInd(screenPtr)
  jsr outHex
  
  c64lib_add16(2, screenPtr)
  inc counterPtr
  lda counterPtr
  cmp #25
  bne nextRow
  rts
}
  
outHex:      
            #import "text/lib/sub/out-hex.asm"
outText:	  
            #import "text/lib/sub/out-text.asm"
startCopper: c64lib_startCopper(
                                    DISPLAY_LIST_PTR_LO, 
                                    LIST_PTR, 
                                    List().add(
                                      c64lib.IRQH_BORDER_COL, 
                                      c64lib.IRQH_BG_COL_0, 
                                      c64lib.IRQH_BORDER_BG_0_COL, 
                                      c64lib.IRQH_BORDER_BG_0_DIFF).lock())

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
helloWorld: .text "*** hello world ***"; .byte $FF

.align $100
copperList: {

  c64lib_copperEntry(46, c64lib.IRQH_BORDER_COL, WHITE, 0)
  c64lib_copperEntry(81, c64lib.IRQH_BG_COL_0, YELLOW, 0)
  c64lib_copperEntry(101, c64lib.IRQH_BG_COL_0, LIGHT_GREEN, 0)
  c64lib_copperEntry(124, c64lib.IRQH_BG_COL_0, GREY, 0)
  c64lib_copperEntry(131, c64lib.IRQH_BG_COL_0, BLUE, 0)
  c64lib_copperEntry(150, c64lib.IRQH_BORDER_COL, RED, 0)
  c64lib_copperEntry(216, c64lib.IRQH_BORDER_BG_0_COL, LIGHT_GREY, $00)
  c64lib_copperEntry(221, c64lib.IRQH_BORDER_BG_0_COL, GREY, $00)
  c64lib_copperEntry(227, c64lib.IRQH_BORDER_BG_0_COL, DARK_GREY, $00)
  c64lib_copperEntry(232, c64lib.IRQH_BORDER_BG_0_DIFF, RED, BLUE)
  c64lib_copperEntry(252, c64lib.IRQH_BORDER_COL, LIGHT_BLUE, 0)
  c64lib_copperLoop()
}
programEnd:

.print "Program size = " + (programEnd - start)
