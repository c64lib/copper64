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
#import "chipset/lib/vic2-global.asm"
#import "text/lib/text.asm"
#import "common/lib/math-global.asm"
#import "common/lib/invoke-global.asm"
#import "../lib/copper64-global.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATION_IDX = $05
.label BAR_DEFS_IDX = $06
.label SCREEN_PTR = 1024

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$080d "Program"

start:

  .namespace c64lib {
    configureMemory(c64lib.RAM_IO_RAM)
    disableNMI()
    disableCIAInterrupts()
  }
  
  lda #00
  sta ANIMATION_IDX
  sta BAR_DEFS_IDX

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

animateBar: {
  inc c64lib.BORDER_COL
  ldx ANIMATION_IDX
  lda sineData, x
  sta rasterIrqh + 1
  inx
  bne skipDefs
  ldy BAR_DEFS_IDX
  lda barDefs, y
  cmp #$ff
  bne changeDefs
  ldy #$00
  jmp storeY
changeDefs:
  sta rasterIrqh + 2
  iny
  lda barDefs, y
  sta rasterIrqh + 3
  iny
storeY:
  sty BAR_DEFS_IDX
skipDefs:
  stx ANIMATION_IDX
  dec c64lib.BORDER_COL
  rts
}

drawMarks: {
  lda #$00
  sta counterPtr
  
nextRow:
  c64lib_pushParamW(counterPtr); c64lib_pushParamWInd(screenPtr); jsr outHex
  c64lib_add16(38, screenPtr)
  c64lib_pushParamW(counterPtr); c64lib_pushParamWInd(screenPtr); jsr outHex
  c64lib_add16(2, screenPtr)
  inc counterPtr
  lda counterPtr
  cmp #25
  bne nextRow
  rts
}

startCopper: c64lib_startCopper(DISPLAY_LIST_PTR_LO, LIST_PTR, List().add(c64lib.IRQH_BG_RASTER_BAR, c64lib.IRQH_JSR).lock())
outHex:     
        #import "text/lib/sub/out-hex.asm"

.align $100
sineData:   .fill 256, round(100 + 50*sin(toRadians(i*360/256)))
.align $100
copperList:
  c64lib_copperEntry(1, c64lib.IRQH_JSR, <animateBar, >animateBar)
  rasterIrqh: c64lib_copperEntry(102, c64lib.IRQH_BG_RASTER_BAR, <barDef1, >barDef1)
  c64lib_copperLoop()

counterPtr: .byte 0
screenPtr:  .word SCREEN_PTR
barDef1:    .byte 	$1, $f, $f, $c, $c, $c, $c, $c, $c, $c, $c, $b, $b, $0, BLUE, $ff
barDef2:    .byte 	$1, $2, $a, $2, $a, $a, $a, $a, $5, $d, $5, $d, $5, $d, BLUE, $ff
barDef3:    .byte 	$1, $2, $8, $2, $8, $a, $8, $a, $8, $a, $8, $2, $8, $2, BLUE, $ff
barDefs:    .word	barDef1, barDef2, barDef3, $ffff
