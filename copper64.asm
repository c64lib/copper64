/*
 * c64lib/copper64/copper64.asm
 *
 * A library that realizes a copper-like functionality of firing certain predefined handlers 
 * at programmable raster lines. This library utilizes raster interrupt functionality of VIC-II.
 *
 * Author:    Maciej Małecki
 * GIT repo:  https://github.com/c64lib/copper64
 */
#importonce
#import "common/common.asm"
#import "chipset/vic2.asm"
#import "chipset/cia.asm"

.filenamespace c64lib

/*
 * Codes of predefined copper64 handlers.
 *
 * Note, that by default each handler is disabled thus not available in assembled code.
 * In order to enable given handler, define IRQH_<handlerName> symbol using #define directive.
 * Assembling will fail, if too many handlers are enabled - summarized code for all handlers must
 * fit into single 256b memory page.
 */
.label IRQH_BORDER_COL          = 1
.label IRQH_BG_COL_0            = 2
.label IRQH_BH_COL_1            = 3
.label IRQH_BH_COL_2            = 4
.label IRQH_BH_COL_3            = 5
.label IRQH_BORDER_BG_0_COL     = 6
.label IRQH_BORDER_BG_0_DIFF    = 7
.label IRQH_MEM_BANK            = 8
.label IRQH_MEM                 = 9
.label IRQH_MODE_MEM_BANK       = 10
.label IRQH_MODE_MEM            = 11
.label IRQH_MODE                = 12
.label IRQH_JSR                 = 13

/*
 * Requires 2 bytes on zero page: 2 subsequent for listStart
 *
 * listStart - begin address of display list stored on zero page
 */
.macro @initCopper(listStart) {
start:
  ldy #$00
  lda (listStart),y             // 5: < 1st byte - control
  cmp #$ff                      // 2
  beq loop                      // 2: if #$ff then loop copper list
  rol                           // 2
  bcs raster8                   // 2: 7 bit set means we use 8th bit of raster irq 
  lda CONTROL_1                 // 4:
  and #neg(CONTROL_1_RASTER8)   // 2: 7..0 bits are enough for raster irq
  jmp nextRaster8               // 3
raster8:
  ora #CONTROL_1_RASTER8        // 2
nextRaster8:
  lda (listStart),y             // 5: it is more efficient to load it once more (5) instead of tax,txa,ror (6)
  and #%00011111                // 2: clear not significant bits to get command id, max 30 values, value 0 is not used
  tax                           // 2
  iny                           // 2
  lda (listStart),y             // 5: < 2nd byte - raster irq counter bits 7..0
  iny                           // 2
  sta RASTER                    // 4: program raster irq
  lda jumpTable,x               // 4: load low byte from jump table
  // TODO store A as low byte of jmp operation in irq handler
loop:
  ldy #$00
  jmp start

  .align $100
irqHandlers:
  .print "IRQ Handlers start at: " + toHexString(irqHandlers)
  irqh1:                        // (22) border color
    #if IRQH_BORDER_COL
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    jmp irqhReminder            // 3
    #endif
  irqh2:                        // (22) background color 0
    #if IRQH_BG_COL_0
    lda (listStart),y           // 5
    sta BG_COL_0                // 4
    jmp irqhReminder            // 3
    #endif
  irqh3:                        // (22 background color 1
    #if IRQH_BG_COL_1
    lda (listStart),y           // 5
    sta BG_COL_1                // 4
    jmp irqhReminder            // 3
    #endif
  irqh4:                        // (22) background color 2
    #if IRQH_BG_COL_2
    lda (listStart),y           // 5
    sta BG_COL_2                // 4
    jmp irqhReminder            // 3
    #endif
  irqh5:                        // (22) background color 3
    #if IRQH_BG_COL_3
    lda (listStart),y           // 5
    sta BG_COL_3                // 4
    jmp irqhReminder            // 3
    #endif
  irqh6:                        // (26) border and background color 0 same
    #if IRQH_BORDER_BG_0_COL
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    sta BG_COL_0                // 4
    jmp irqhReminder            // 3
    #endif
  irqh7:                        // (31) border and background color 0 different
    #if IRQH_BORDER_BG_0_DIFF
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    iny                         // 2
    lda (listStart),y           // 5
    sta BG_COL_0                // 4
    jmp irqhReminder2Args       // 3
    #endif
  irqh8:                        // (28) set vic-ii memory and bank
    #if IRQH_MEM_BANK
    lda (listStart),y           // 5
    sta MEMORY_CONTROL          // 4
    iny                         // 2
    lda (listStart),y           // 4
    ora CIA2_DATA_PORT_A        // 4
    sta CIA2_DATA_PORT_A        // 4
    jmp irqhReminder2Args       // 3
    #endif
  irqh9:                        // (16) set vic-ii memory
    #if IRQH_MEM
    lda (listStart),y           // 5
    sta MEMORY_CONTROL          // 4
    jmp irqhReminder            // 3
    #endif
  irqhReminder:
    iny
  irqhReminder2Args:
    iny
  .print "Size of aggregated code of IRQ handlers: " + [irqhReminder - irqh1] + " bytes."
  .assert "Size of aggregated code of IRQ handlers must fit into one memory page (256b)", irqhReminder - irqh1 <= 256, true
  
  /* 
   * For sake of efficiency, jump table only stores lo address of handler. 
   * It is assumed that hi address is always the same.
   */
  .align $100
jumpTable:
  .print "Jump table starts at: " + toHexString(jumpTable)
  .byte $00, <irqh1, <irqh2, <irqh3, <irqh4, <irqh5, <irqh6, <irqh7 // position 0 is never used
  .byte <irqh8, <irqh9
jumpTableEnd:
  .print "Jump table size: " + [jumpTableEnd - jumpTable] + " bytes."
  .assert "Size of Jump table must fit into one memory page (256b)", jumpTableEnd - jumpTable <= 256, true
  // TODO maybe jumpTable and IRQh table can be merged into one common memory block
  
  /*
   * These nops are used to fine cycle irq routine to get stable irq.
   */
nops:
  nop;  nop;  nop;  nop;  nop
  nop;  nop;  nop;  nop;  nop
  nop;  nop
  jmp nops
}
