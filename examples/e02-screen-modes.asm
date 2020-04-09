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
#import "chipset/lib/mos6510.asm"
#import "chipset/lib/vic2-global.asm"
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
  c64lib_pushParamW(counterPtr); 
  c64lib_pushParamWInd(screenPtr); 
  jsr outHex
  
  c64lib_add16(38, screenPtr)
  c64lib_pushParamW(counterPtr); 
  c64lib_pushParamWInd(screenPtr); 
  jsr outHex
  
  c64lib_add16(2, screenPtr)
  inc counterPtr
  lda counterPtr
  cmp #25
  bne nextRow
  rts
}

startCopper: c64lib_startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR, List().add(c64lib.IRQH_MODE_MEM).lock())
outHex:      
      #import "text/lib/sub/out-hex.asm"

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR

.align $100
copperList: {
  c64lib_copperEntry(85, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_1_BMM, c64lib_getBitmapMemory(0, 0))
  c64lib_copperEntry(133, c64lib.IRQH_MODE_MEM, 0, c64lib_getTextMemory(1, 2))
  c64lib_copperEntry(166, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM, c64lib_getTextMemory(0, 2))
  c64lib_copperEntry(177, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_2_MCM | c64lib.CONTROL_1_BMM, c64lib_getBitmapMemory(0, 1))
  c64lib_copperEntry(213, c64lib.IRQH_MODE_MEM, 0, c64lib_getTextMemory(1, 2))
  c64lib_copperLoop()
}
