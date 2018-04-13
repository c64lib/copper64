/*
 * c64lib/copper64/examples/example-1.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_BORDER_COL
#define IRQH_BG_COL_0
#define IRQH_BORDER_BG_0_COL
#define IRQH_BORDER_BG_0_DIFF
#define IRQH_MEM
#define IRQH_MODE
//#define VISUAL_DEBUG

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "../copper64.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04

.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // Basic start routine

// Main program
.pc = $0810 "Program"

start:
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  :configureMemory(c64lib.RAM_IO_RAM)
  
  // set up address of display list
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  
  // initialize copper64 routine
  jsr copper
block:
  nop
  lda $ff00
  jmp block
  
copper: {
  :initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
copperList: {
  .byte c64lib.IRQH_BORDER_COL,       81,   WHITE,      $00
  .byte c64lib.IRQH_BG_COL_0,         100,  YELLOW,     $00
  .byte c64lib.IRQH_BG_COL_0,         120,  RED,        $00
  .byte c64lib.IRQH_BG_COL_0,         144,  GREY,       $00
  .byte c64lib.IRQH_BG_COL_0,         147,  BLUE,       $00
  .byte c64lib.IRQH_BORDER_COL,       161,  LIGHT_BLUE, $00
  .byte c64lib.IRQH_MODE,             169,  $00, c64lib.CONTROL_2_MCM
  .byte c64lib.IRQH_MEM,              195,  getTextMemory(0, 2), $00
  .byte c64lib.IRQH_MEM,              211,  getTextMemory(1, 2), $00
  .byte c64lib.IRQH_MODE,             215,  $00,        $00
  .byte c64lib.IRQH_BORDER_BG_0_COL,  220,  GREEN,      $00
  .byte c64lib.IRQH_BORDER_BG_0_DIFF, 241,  LIGHT_BLUE, BLUE
  .byte c64lib.IRQH_LOOP,             $00,  $00,        $00
}

