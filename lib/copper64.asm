/*
 * c64lib/copper64/copper64.asm
 *
 * A library that realizes a copper-like functionality of firing certain predefined handlers
 * at programmable raster lines. This library utilizes raster interrupt functionality of VIC-II.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
#importonce
#import "common/lib/common.asm"
#import "common/lib/mem.asm"
#import "chipset/lib/vic2.asm"
#import "chipset/lib/cia.asm"

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
.label IRQH_BG_COL_1            = 3
.label IRQH_BG_COL_2            = 4
.label IRQH_BG_COL_3            = 5
.label IRQH_BORDER_BG_0_COL     = 6
.label IRQH_BORDER_BG_0_DIFF    = 7

.label IRQH_MEM_BANK            = 8
.label IRQH_MODE_MEM            = 9

.label IRQH_JSR                 = 10

.label IRQH_MODE_HIRES_BITMAP   = 11
.label IRQH_MODE_MULTIC_BITMAP  = 12
.label IRQH_MODE_HIRES_TEXT     = 13
.label IRQH_MODE_MULTIC_TEXT    = 14
.label IRQH_MODE_EXTENDED_TEXT  = 15

.label IRQH_FULL_RASTER_BAR     = 16
.label IRQH_BG_RASTER_BAR       = 17

.label IRQH_HSCROLL             = 18
.label IRQH_HSCROLL_MAP			= 19

.label IRQH_CTRL_RASTER8        = %10000000
.label IRQH_SKIP                = $00
.label IRQH_LOOP                = $FF

// ===== PRIVATE PART =====

/*
 * Stabilizes interrupt.
 *
 * Params:
 * secondIrqHandler - to be called after stabilizing
 * commonEnd - to preserve memory, this is common end of stabilization procedure
 * preserveA - preserve accumulator value or nots
 */
.macro _stabilize(secondIrqHandler, commonEnd, preserveA) {
  .if(preserveA) tax
  lda #<secondIrqHandler
  sta IRQ_LO
  lda #>secondIrqHandler
  sta IRQ_HI
  .if(preserveA) txa
  jmp commonEnd
}

// to preserve memory...
.macro _stabilizeCommonEnd() {
  inc RASTER // 5: TODO what if raster is higher than 255? quick check on overflow needed...
  inc IRR    // 5
  tsx // 2
  cli // 2
  nop // 2
  nop // 2
  nop // 2
  nop
  nop
  nop
  jmp *-1
}

/*
 * Length: 5 bytes
 * Timing:   count * 7 - 1 (cycles)
 * MOD: X
 */
.macro _cycleDelay(count) {
  ldx #count  // 2, 2
  dex         // 2, 1
  bne *-1     // 3(2), 2 - max 3 if on the same page
}

/*
 * Length: 15 bytes
 * Timing: count * 7 + 10 + 2(3)
 */
.macro _cycleRaster(count) {// length 15 bytes
  ldx #count  // 2, 2
  dex         // 2, 1
  bne *-1     // 3(2), 2

  bit $00     // 3, 2
  lda RASTER  // 4, 3
  cmp RASTER  // 4, 3

  beq *+2     // 3(2), 2
              // total: count * 5 + 14 + 2(3)
}

.macro _setMasterIrqHandler(copperIrq) {
  lda #<copperIrq
  sta c64lib.IRQ_LO
  lda #>copperIrq
  sta c64lib.IRQ_HI
}

.macro _setBankMemoryAndMode(mode, listStart, listPtr, accu) {
  lda CONTROL_2                                       // 4
  and #neg(CONTROL_2_MCM)                             // 2
  ora #calculateControl2ForMode(mode) // 2
  sta accu                                            // 4
  lda (listStart),y                                   // 5
  sta listPtr                                         // 3
  iny                                                 // 2
  lda CIA2_DATA_PORT_A                                // 4
  and #%11111100                                      // 2
  ora (listStart),y                                   // 5
  sta CIA2_DATA_PORT_A                                // *4
  lda listPtr                                         // *3
  sta MEMORY_CONTROL                                  // *4
  lda CONTROL_1                                       // *4
  and #neg(CONTROL_1_ECM | CONTROL_1_BMM)             // *2
  ora #calculateControl1ForMode(mode) // *2
  sta CONTROL_1                                       // *4
  lda accu                                            // *4
  sta CONTROL_2                                       // *4
}

.function _handlersToHashmap(handlersList) {
  .var result = Hashtable()
  .for (var i = 0; i < handlersList.size(); i++) {
    .eval result.put(handlersList.get(i), i)
  }
  .return result
}

.function _has(handlersMap, handlerCode) {
  .return handlersMap.containsKey(handlerCode)
}

// ===== PUBLIC PART =====

/*
 * Creates single entry of copper list.
 * raster - at which raster line (supports all raser lines, also > 255)
 * handler - handler code
 * arg1 - argument 1 of raster handler
 * arg2 - argument 2 of raster handler
 */
.macro copperEntry(raster, handler, arg1, arg2) {
  .if (raster >= 256) {
    .byte 128 + handler
  }  else {
    .byte handler
  }
  .byte <raster, arg1, arg2
}

/*
 * Creates end of copper list with looping directive.
 */
.macro copperLoop() {
  copperEntry(0, IRQH_LOOP, 0, 0)
}


// Hosted subroutines

/*
 * Initializes copper64 and installs IRQ handler at first position from copper list. This macro defines
 * hosted subroutine and as such can be then called many times. It is handy, when one need to disable
 * copper functionality and then relaunch it again. Once called again, display list pointer is reset to 0.
 *
 * This is handy when one need to change display list (for next demo part for instance, or from game title
 * screen to in-game screen). To achieve this one needs to stop copper by launching hosted subroutine
 * _stopCopper, change copper list address specified by listStart (zero page) and relaunch by calling
 * _startCopper again.
 *
 * Requires 3 bytes on zero page: 2 subsequent for listStart, 1 byte for list pointer (Y)
 *
 * listStart - begin address of display list stored on zero page
 * listPtr - address for Y reg storage
 * handlersList - KA List with handler codes
 */
.macro startCopper(listStart, listPtr, handlersList) {
  .var handlers = _handlersToHashmap(handlersList)

  // here we do initialize and install first interrupt handler
  lda #$00
  sta listPtr
  sei
  // enable IRQ generated by VIC-II
  lda #IMR_RASTER
  sta IMR
  _setMasterIrqHandler(copperIrq)

  ldy listPtr
  jsr fetchNext
  sty listPtr
  cli
  rts // end of initialization
accu1:
  .byte $00
accu2:
  .byte $00

commonEnd:
  _stabilizeCommonEnd()

copperIrq:                    // major interrupt handler for copper64; interrupt not stabilized at this point
  pha
  tya
  pha
  txa
  pha
  ldy listPtr
irqHandlersJump:
  jmp irqHandlers               // 3: LO byte of jump address will be modified every time new item is fetched from the list
irqHandlersReturn:              // here we jump back from handler routine, due to jmp instead jsr we save 6 cycles
  jsr fetchNext                 // 6
  sty listPtr
  dec IRR                       // ACK the interrupt
  pla
  tax
  pla
  tay
  pla
  rti
fetchNext:                      // fetch new copper list item, y should point at current list position
  lda (listStart),y             // 5: < 1st byte - control
  cmp #IRQH_LOOP                // 2
  beq loop                      // 2: if $FF then loop copper list
  cmp #IRQH_SKIP                // 2
  beq skip                      // 2: if #$FF then skip copper list position
  rol                           // 2
  lda CONTROL_1                 // 4:
  bcs raster8                   // 2: 7 bit set means we use 8th bit of raster irq
  and #neg(CONTROL_1_RASTER8)   // 2: 7..0 bits are enough for raster irq
  jmp nextRaster8               // 3
raster8:
  ora #CONTROL_1_RASTER8        // 2
nextRaster8:
  sta CONTROL_1
  lda (listStart),y             // 5: it is more efficient to load it once more (5) instead of tax,txa,ror (6)
  and #%00011111                // 2: clear not significant bits to get command id, max 30 values, value 0 is not used
  tax                           // 2
  iny                           // 2
  lda (listStart),y             // 5: < 2nd byte - raster irq counter bits 7..0
  iny                           // 2
  sta RASTER                    // 4: program raster irq
  lda jumpTable,x               // 4: load low byte from jump table
  sta irqHandlersJump + 1       // 4: store low byte of address
  rts                           // 6
loop:                           // we do loop the copper list
  ldy #$00
  jmp fetchNext
skip:                           // we do skip the copper list, useful for disabling list item temporarily
  iny
  iny
  iny
  iny
  jmp fetchNext

  /*
   * Switchable IRQ handlers.
   */
  .align $100
irqHandlers:
  .print "IRQ Handlers start at: " + toHexString(irqHandlers)
  irqh1:                              // (?) border color; stable + jitter; +1 raster
    .if (_has(handlers, IRQH_BORDER_COL)) {
      _stabilize(irqh1Stabilized, commonEnd, false)
    irqh1Stabilized:                  // 7 + 0(1)
      txs                             // 2
      _cycleDelay(8)                   // cycle delay
      nop                             // potentially 1 extra cycle to save
      lda (listStart),y               // 5
      sta BORDER_COL                  // 4 right horiz blanking
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder                // 3
    }
  irqh2:                              // (?) background color 0, stable + jitter; +1 raster
    .if (_has(handlers, IRQH_BG_COL_0)) {
      _stabilize(irqh2Stabilized, commonEnd, false)
    irqh2Stabilized:                  // 7
      txs                             // 2
      _cycleDelay(8)                   // a little bit too much, but we want to save bytes as well
      lda (listStart),y               // 5
      sta BG_COL_0                    // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder                // 3
    }
  irqh3:                              // (22) background color 1
    .if (_has(handlers, IRQH_BG_COL_1)) {
      _stabilize(irqh3Stabilized, commonEnd, false)
    irqh3Stabilized:                  // 7
      txs                             // 2
      _cycleDelay(8)                   // a little bit too much, but we want to save bytes as well
      lda (listStart),y               // 5
      sta BG_COL_1                    // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder                // 3
    }
  irqh4:                              // (22) background color 2
    .if (_has(handlers, IRQH_BG_COL_2)) {
      _stabilize(irqh4Stabilized, commonEnd, false)
    irqh4Stabilized:                  // 7
      txs                             // 2
      _cycleDelay(8)                   // a little bit too much, but we want to save bytes as well
      lda (listStart),y               // 5
      sta BG_COL_2                    // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder                // 3
    }
  irqh5:                              // (22) background color 3
    .if (_has(handlers, IRQH_BG_COL_3)) {
      _stabilize(irqh5Stabilized, commonEnd, false)
    irqh5Stabilized:                  // 7
      txs                             // 2
      _cycleDelay(8)                   // a little bit too much, but we want to save bytes as well
      lda (listStart),y               // 5
      sta BG_COL_3                    // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder                // 3
    }
  irqh6:                              // (?) border and background color 0 same; stable + jitter; +1 raster
    .if (_has(handlers, IRQH_BORDER_BG_0_COL)) {
      _stabilize(irqh6Stabilized, commonEnd, false)
    irqh6Stabilized:
      txs
      _cycleDelay(7)
      nop
      lda (listStart),y           // 5
      sta BG_COL_0                // 4
      sta BORDER_COL              // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder            // 3
    }
  irqh7:                        // (31) border and background color 0 different; stable + jitter; +1 raster
    .if (_has(handlers, IRQH_BORDER_BG_0_DIFF)) {
      _stabilize(irqh7Stabilized, commonEnd, false)
    irqh7Stabilized:
      txs
      _cycleDelay(5)
      lda (listStart),y           // 5
      sta listPtr
      iny                         // 2
      lda (listStart),y           // 5
      nop
      sta BG_COL_0                // 4
      lda listPtr
      sta BORDER_COL              // 4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args       // 3
    }
  irqh8:                          // (28) set vic-ii memory and bank TODO stabilize
    .if (_has(handlers, IRQH_MEM_BANK)) {
      lda (listStart),y           // 5
      sta MEMORY_CONTROL          // 4
      iny                         // 2
      lda CIA2_DATA_PORT_A
      and #%11111100
      ora (listStart),y
      sta CIA2_DATA_PORT_A
      jmp irqhReminder2Args       // 3
    }
  irqh9:                          // change vic-ii mode and memory settings
                                  // arg 1: CR2: 00010000 Multicolor
                                  // arg 1: CR1: 01100000 ExtendedColor, Bitmap mode
                                  // arg 2: Memory Control
    .if (_has(handlers, IRQH_MODE_MEM)) {
      _stabilize(irqh9Stabilized, commonEnd, false)
    irqh9Stabilized:
      txs                         // 2
      lda (listStart),y           // 5
      iny                         // 2
      sta listPtr                 // 3
      and #CONTROL_2_MCM          // 2
      beq irqh9_1
      lda CONTROL_2               // 4
      ora #CONTROL_2_MCM          // 2
      jmp irqh9_2                 // 3
    irqh9_1:
      lda CONTROL_2               // 4
      and #neg(CONTROL_2_MCM)     // 2
    irqh9_2:
      sta CONTROL_2               // *4
      lda listPtr                 // *3
      and #(CONTROL_1_ECM | CONTROL_1_BMM) // *2
      sta listPtr                 // *3
      lda CONTROL_1               // *4
      and #(neg(CONTROL_1_ECM | CONTROL_1_BMM)) // *2
      ora listPtr                 // *3
      sta CONTROL_1               // *4
      lda (listStart),y           // *5
      sta MEMORY_CONTROL          // *4
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh10:                         // jsr (jsr address lo | lsr address hi)
    .if (_has(handlers, IRQH_JSR)) {
      lda (listStart),y           // 4
      sta irqh10jsr+1             // 4
      iny                         // 2
      lda (listStart),y           // 4
      sta irqh10jsr+2             // 4
      sty listPtr
    irqh10jsr:
      jsr $0000
      ldy listPtr
      jmp irqhReminder2Args
    }
  irqh11:                       // HIRES Bitmap mode (memory control | bank)
    .if (_has(handlers, IRQH_MODE_HIRES_BITMAP)) {
      _stabilize(irqh11Stabilized, commonEnd, false)
    irqh11Stabilized:
      txs
      _setBankMemoryAndMode(STANDARD_BITMAP_MODE, listStart, listPtr, accu1)
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh12:                       // MULTIC Bitmap mode (memory control | bank)
    .if (_has(handlers, IRQH_MODE_MULTIC_BITMAP)) {
      _stabilize(irqh12Stabilized, commonEnd, false)
    irqh12Stabilized:
      txs
      _setBankMemoryAndMode(MULTICOLOR_BITMAP_MODE, listStart, listPtr, accu1)
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh13:                       // HIRES Text (memory control | bank) TODO stabilize
    .if (_has(handlers, IRQH_MODE_HIRES_TEXT)) {
      _stabilize(irqh13Stabilized, commonEnd, false)
    irqh13Stabilized:
      txs
      _setBankMemoryAndMode(STANDARD_TEXT_MODE, listStart, listPtr, accu1)
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh14:                       // MULTIC Text (memory control | bank) TODO stabilize
    .if (_has(handlers, IRQH_MODE_MULTIC_TEXT)) {
      _stabilize(irqh14Stabilized, commonEnd, false)
    irqh14Stabilized:
      txs
      _setBankMemoryAndMode(MULTICOLOR_TEXT_MODE, listStart, listPtr, accu1)
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh15:                       // EXTENDED Background Text (memory control | bank) TODO stabilize
    .if (_has(handlers, IRQH_MODE_EXTENDED_TEXT)) {
      _stabilize(irqh15Stabilized, commonEnd, false)
    irqh15Stabilized:
      txs
      _setBankMemoryAndMode(EXTENDED_TEXT_MODE, listStart, listPtr, accu1)
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder2Args
    }
  irqh16: {                     // FULL Color raster bar (bar definition ptr lo | bar definition ptr hi)
    .if (_has(handlers, IRQH_FULL_RASTER_BAR)) {
      lda (listStart), y
      sta rasterList + 1
      iny
      lda (listStart), y
      sta rasterList + 2
      ldx #0
      sty listPtr

      rasterList: lda $ffff, x  // 4(5)
      cmp #$ff                  // 2
      beq end                   // 2
      ldy RASTER                // 4
      compareAgain: cpy RASTER  // 4
      beq compareAgain          // 2
      sta BORDER_COL            // 4 (fully stable if commented out)
      sta BG_COL_0              // 4
      inx                       // 2
      jmp rasterList            // 3
    end:
      ldy listPtr
      jmp irqhReminder2Args
    }
    }
  irqh17: {                     // BG only color raster bar (bar definition ptr lo | bar definition ptr hi)
    .if (_has(handlers, IRQH_BG_RASTER_BAR)) {
      lda (listStart), y
      sta rasterList + 1
      iny
      lda (listStart), y
      sta rasterList + 2
      ldx #0
      sty listPtr
      ldy RASTER                // 4
      preStabilize: cpy RASTER  // 4
      beq preStabilize          // 2

      rasterList: lda $ffff, x  // 4(5)
      cmp #$ff                  // 2
      beq end                   // 2
      ldy RASTER                // 4
      compareAgain: cpy RASTER  // 4
      beq compareAgain          // 2
      sta BG_COL_0              // 4
      inx                       // 2
      jmp rasterList            // 3
    end:
      ldy listPtr
      jmp irqhReminder2Args
    }
    }
  irqh18: {						// HSCROLL by given pixels
    .if (_has(handlers, IRQH_HSCROLL)) {
      _stabilize(irqh18Stabilized, commonEnd, false)
    irqh18Stabilized:
      txs
      lda CONTROL_2
      and #%11111000
      ora (listStart), y
      sta CONTROL_2
      _setMasterIrqHandler(copperIrq)
      jmp irqhReminder
    }
  }
  irqh19: {						// tech tech effect using HSCROLL and pixel map
  	.if (_has(handlers, IRQH_HSCROLL_MAP)) {
      lda (listStart), y
      sta hscrollMap + 1
      iny
      lda (listStart), y
      sta hscrollMap + 2
      ldx #0
      sty listPtr
      ldy RASTER                // 4
      preStabilize: cpy RASTER  // 4
      beq preStabilize          // 2

      lda CONTROL_2
    nextLine:
      and #$11111000
      hscrollMap: ora $ffff, x
      cmp #$ff                  // 2
      beq end                   // 2
      ldy RASTER                // 4
      compareAgain: cpy RASTER  // 4
      beq compareAgain          // 2
      sta CONTROL_2             // 4
      inx                       // 2
      jmp nextLine              // 3
    end:
      ldy listPtr
      jmp irqhReminder2Args
  	}
  }
  irqhReminder:
    iny
  irqhReminder2Args:
    iny
    jmp irqHandlersReturn
  irqhEnd:
  .print "Size of aggregated code of IRQ handlers: " + (irqhReminder - irqHandlers) + " bytes."
  .assert "Size of aggregated code of IRQ handlers must fit into one memory page (256b)", irqhReminder - irqHandlers <= 256, true

  /*
   * Jump table for IRQ handlers.
   *
   * For sake of efficiency, jump table only stores lo address of handler.
   * It is assumed that hi address is always the same.
   */
  .if (256 - (irqhEnd - irqHandlers) < 32) {
    // jumpTable(s) are merged into irqHandlers space if only they fit together into 256b
    .align $100
  }
jumpTable:
  .print "Jump table starts at: " + toHexString(jumpTable)
  .byte $00, <irqh1, <irqh2, <irqh3, <irqh4, <irqh5, <irqh6, <irqh7 // position 0 is never used
  .byte <irqh8, <irqh9, <irqh10, <irqh11, <irqh12, <irqh13, <irqh14, <irqh15
  .byte <irqh16, <irqh17, <irqh18, <irqh19
jumpTableEnd:
  .print "Jump table size: " + [jumpTableEnd - jumpTable] + " bytes."
  .assert "Size of Jump table must fit into one memory page (256b)", jumpTableEnd - jumpTable <= 256, true
}

/*
 * Stops copper. It actually disables VIC-II interrupt, display list start pointer and list pointer value
 * are left unchanged.
 */
.macro stopCopper() {
	lda #0
	sta IMR
	rts
}
