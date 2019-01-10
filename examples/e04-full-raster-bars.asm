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
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2.asm"
#import "text/lib/text.asm"
#import "common/lib/math-global.asm"
#import "common/lib/invoke-global.asm"
#import "../lib/copper64.asm"

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
    configureMemory(c64lib.RAM_IO_RAM)
    disableNMI()
    disableCIAInterrupts()
  }
  cli
  
  jsr drawMarks
  jsr initCopper
  jsr startCopper
block:
  jmp block
  
initCopper: {
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  rts
}

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

startCopper: .namespace c64lib { _startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR, List().add(IRQH_FULL_RASTER_BAR, IRQH_JSR).lock()) }
outHex:      
        #import "text/lib/sub/out-hex.asm"

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
barDef:     .byte 	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, BLUE, $ff

.align $100
copperList: {
  copperEntry(102, c64lib.IRQH_FULL_RASTER_BAR, <barDef, >barDef)
  copperLoop()
}
