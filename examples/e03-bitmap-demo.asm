/*
 * c64lib/copper64/examples/e03-bitmap-demo.asm
 *
 * Demo program for copper64 routine.
 *
 * Author:    Maciej Malecki
 * License:   MIT
 * (c):       2018
 * GIT repo:  https://github.com/c64lib/copper64
 */
 
#define IRQH_MODE_MEM
#define IRQH_BG_COL_0
#define IRQH_JSR
#define VISUAL_DEBUG

#import "chipset/mos6510.asm"
#import "chipset/vic2.asm"
#import "text/text.asm"
#import "../copper64.asm"

.label DISPLAY_LIST_PTR_LO = $02
.label DISPLAY_LIST_PTR_HI = $03
.label LIST_PTR = $04
.label ANIMATE_BUFFER = $05
.label ANIMATION_DELAY_COUNTER = $06

.label DELAY = 2

.label BITMAP_BANK = 0
.label BITMAP_SCREEN_BANK = 8
.label TEXT_SCREEN_BANK = 9
.label TEXT_CHARSET_BANK = 5

.var music = LoadSid("Noisy_Pillars_tune_1.sid")
.print "SID Music details"
.print "-----------------"
.print "name: " + music.name
.print "author: " + music.author
.print "location: $" + toHexString(music.location)
.print "size: $" + toHexString(music.size)
.print "init: $" + toHexString(music.init)
.print "play: $" + toHexString(music.play)
.print "start song: " + music.startSong

.var gfxTemplate = "Header=0,Bitmap=2,Screen=8002"
.var gfx  = LoadBinary("frog.art", gfxTemplate)

*=$0801 "Basic Upstart"
BasicUpstart(start) // Basic start routine

// Main program
*=$3000 "Program"

start:

  lda #DELAY
  sta ANIMATION_DELAY_COUNTER

  // initialize sound  
  ldx #0
  ldy #0
  lda #music.startSong-1
  jsr music.init
  jsr fillColorMem
  sei                                   // I don't care of calling cli later, copper initialization does it anyway
  
  lda #BLUE
  sta c64lib.BG_COL_0
  lda #BLACK
  sta c64lib.BORDER_COL
  
  lda #$01
  ldy #$00
fillText:
  sta $6400,y
  sta $6500,y
  sta $6600,y
  sta $6700,y
  iny
  bne fillText
  
  setVICBank(%10)
  configureMemory(c64lib.RAM_IO_RAM)
  setVideoMode(c64lib.STANDARD_BITMAP_MODE)
  configureBitmapMemory(BITMAP_SCREEN_BANK, BITMAP_BANK)
   
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
  sta $ff00
  nop
  nop
  lda $ff00
  lda $ff
  lda $ffff
  jmp block
playMusic: {
  inc c64lib.BORDER_COL
  jsr music.play
  dec c64lib.BORDER_COL
  rts
}
fillColorMem: {
  lda #LIGHT_GRAY
  ldx #0
loop:
  sta c64lib.COLOR_RAM, x
  sta c64lib.COLOR_RAM + $100, x
  sta c64lib.COLOR_RAM + $200, x
  sta c64lib.COLOR_RAM + $300, x
  inx
  bne loop
  rts
}
animateCharset: {
  debugBorderStart()
  dec ANIMATION_DELAY_COUNTER
  beq next
  debugBorderEnd()
  rts
next:
  lda #DELAY
  sta ANIMATION_DELAY_COUNTER
  lda CHARSET 
  sta ANIMATE_BUFFER
  lda CHARSET+1
  sta CHARSET
  lda CHARSET+2
  sta CHARSET+1
  lda CHARSET+3
  sta CHARSET+2
  lda CHARSET+4
  sta CHARSET+3
  lda CHARSET+5
  sta CHARSET+4
  lda CHARSET+6
  sta CHARSET+5
  lda CHARSET+7
  sta CHARSET+6
  lda ANIMATE_BUFFER
  sta CHARSET+7
  debugBorderEnd()
  rts
}

copper: {
  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
}

.align $100
copperList: {
  copperEntry(11, c64lib.IRQH_JSR, <animateCharset, >animateCharset)
  copperEntry(52, c64lib.IRQH_BG_COL_0, DARK_GREY, 0)
  copperEntry(56, c64lib.IRQH_BG_COL_0, BLUE, 0)
  copperEntry(113, c64lib.IRQH_MODE_MEM, c64lib.CONTROL_1_BMM, getBitmapMemory(BITMAP_SCREEN_BANK, BITMAP_BANK))
  copperEntry(193, c64lib.IRQH_MODE_MEM, 0, getTextMemory(TEXT_SCREEN_BANK, TEXT_CHARSET_BANK))
  copperEntry(241, c64lib.IRQH_BG_COL_0, DARK_GREY, 0)
  copperEntry(246, c64lib.IRQH_BG_COL_0, GREY, 0)
  copperEntry(257, c64lib.IRQH_JSR, <playMusic, >playMusic)
  copperLoop()
}

hexChars:
	.text "0123456789abcdef"
  
*=music.location "Music"
.fill music.size, music.getData(i)

*=$4000 "Bitmap"
  .fill gfx.getBitmapSize(), gfx.getBitmap(i)
  
*=$6000 "Screen Memory"
  .fill gfx.getScreenSize(), gfx.getScreen(i)

*=$6800 "Charset"
  .byte 0, 0, 0, 0, 0, 0, 0, 0
CHARSET:
  .byte 0
  .byte %00001110
  .byte %00011100
  .byte %00111110
  .byte %00001100
  .byte %00011000
  .byte %00010000
  .byte 0
