#importonce
#import "common/common.asm"
#import "chipset/vic2.asm"
#import "chipset/cia.asm"

.filenamespace c64lib

/*
 * Requires 3 bytes on zero page: 2 subsequent for listStart and 1 for listPtr
 *
 * listStart - begin address of display list stored on zero page
 * listPtr - pointer (Y reg) od display list stored on zero page
 */
.macro @initCopper(listStart, listPtr) {
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
  irqh1:                        // (18) border color
    #if IRQH1
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    jmp irqhReminder            // 3
    #endif
  irqh2:                        // (18) background color 0
    #if IRQH2
    lda (listStart),y           // 5
    sta BG_COL_0                // 4
    jmp irqhReminder            // 3
    #endif
  irqh3:                        // (18) background color 1
    // TODO use #define and #if directives to switch on only necessary sections
    lda (listStart),y           // 5
    sta BG_COL_1                // 4
    jmp irqhReminder            // 3
  irqh4:                        // (18) background color 2
    lda (listStart),y           // 5
    sta BG_COL_2                // 4
    jmp irqhReminder            // 3
  irqh5:                        // (18) background color 3
    lda (listStart),y           // 5
    sta BG_COL_3                // 4
    jmp irqhReminder            // 3
  irqh6:                        // (22) border and background color 0 same
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    sta BG_COL_0                // 4
    jmp irqhReminder            // 3
  irqh7:                        // (29) border and background color 0 different
    lda (listStart),y           // 5
    sta BORDER_COL              // 4
    iny                         // 2
    lda (listStart),y           // 5
    sta BG_COL_0                // 4
    jmp irqhReminder2Args       // 3
  irqh8:                        // (26) set vic-ii memory and bank
    lda (listStart),y           // 5
    sta MEMORY_CONTROL          // 4
    iny                         // 2
    lda (listStart),y           // 4
    ora CIA2_DATA_PORT_A        // 4
    sta CIA2_DATA_PORT_A        // 4
    jmp irqhReminder2Args       // 3
  irqh9:                        // (12) set vic-ii memory
    lda (listStart),y           // 5
    sta MEMORY_CONTROL          // 4
    jmp irqhReminder            // 3
  irqhReminder:
    iny                         // 2
  irqhReminder2Args:
    iny                         // 2
  
  .align $100
jumpTable:
  .byte $00, <irqh1, <irqh2, <irqh3, <irqh4, <irqh5, <irqh6, <irqh7 // position 0 is never used
  .byte <irqh8, <irqh9
}

:initCopper($f0, $00)           // just for testing
