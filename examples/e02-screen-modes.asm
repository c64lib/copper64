/*
 * c64lib/copper64/examples/e02-screen-modes.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_MODE_MEM

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
    configureMemory(RAM_IO_RAM)
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

startCopper: .namespace c64lib { _startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR) }
outHex:      .namespace c64lib { _outHex() }

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR

.align $100
copperList: {
  copperEntry(85, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_1_BMM, getBitmapMemory(0, 0))
  copperEntry(133, c64lib.IRQH_MODE_MEM, 0, getTextMemory(1, 2))
  copperEntry(166, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM, getTextMemory(0, 2))
  copperEntry(177, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM | c64lib.CONTROL_1_BMM, getBitmapMemory(0, 1))
  copperEntry(213, c64lib.IRQH_MODE_MEM, 0, getTextMemory(1, 2))
  copperLoop()
}
