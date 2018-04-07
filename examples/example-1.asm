/*
 * Copper demo 1.
 */

#define IRQH_BORDER_COL
#define IRQH_BG_COL_0
#define IRQH_BORDER_BG_0_COL
#define IRQH_BORDER_BG_0_DIFF
//#define VISUAL_DEBUG

#import "common/mem.asm"
#import "chipset/cia.asm"
#import "chipset/vic2.asm"
#import "chipset/mos6510.asm"
#import "../copper64.asm"

.label IRQ_1 = 100
.label IRQ_2 = 120

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04

.pc = $0801 "Basic Upstart"
:BasicUpstart(start) // Basic start routine

// Main program
.pc = $0810 "Program"

start:
  sei
	:setRaster(IRQ_1)
	lda #<irqFreeze
	sta c64lib.IRQ_LO
	lda #>irqFreeze
	sta c64lib.IRQ_HI
	lda #<irqFreeze
	sta c64lib.NMI_LO
	lda #>irqFreeze
	sta c64lib.NMI_HI
  
  :configureMemory(c64lib.RAM_IO_RAM)
  
  cli
  lda #<copperList
  sta DISPLAY_LIST_PTR_LO
  lda #>copperList
  sta DISPLAY_LIST_PTR_HI
  jsr copper
block:
  jmp block
  
irqFreeze: {
	rti
}

copper: {
  :initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
copperList: {
  .byte c64lib.IRQH_BORDER_COL,       80,   WHITE,      $00
  .byte c64lib.IRQH_BG_COL_0,         100,  YELLOW,     $00
  .byte c64lib.IRQH_BG_COL_0,         120,  RED,        $00
  .byte c64lib.IRQH_BG_COL_0,         144,  GREY,       $00
  .byte c64lib.IRQH_BG_COL_0,         146,  BLUE,       $00
  .byte c64lib.IRQH_BORDER_COL,       160,  LIGHT_BLUE, $00
  .byte c64lib.IRQH_BORDER_BG_0_COL,  220,  GREEN,      $00
  .byte c64lib.IRQH_BORDER_BG_0_DIFF, 240,  LIGHT_BLUE, BLUE
  .byte c64lib.IRQH_LOOP,             $00,  $00,        $00
}

