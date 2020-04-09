# c64lib/copper64

## Build status
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CircleCI](https://circleci.com/gh/c64lib/copper64/tree/master.svg?style=svg)](https://circleci.com/gh/c64lib/copper64/tree/master)
[![CircleCI](https://circleci.com/gh/c64lib/copper64/tree/develop.svg?style=svg)](https://circleci.com/gh/c64lib/copper64/tree/develop)
[![Gitter](https://badges.gitter.im/c64lib/community.svg)](https://gitter.im/c64lib/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

A library that realizes a copper-like functionality of firing certain predefined handlers 
at programmable raster lines. This library utilizes raster interrupt functionality of VIC-II.

# Usage
## Using as KickAssembler library
The concept of writing libraries for KickAssembler has been already roughly sketched in my blog [post](https://maciejmalecki.github.io/blog/assembler-libraries). Copper64 is intended to be a library too. Copper64 requires other c64lib libraries such as common, chipset and text.

## Running examples
As for now there are three example programs available that demonstrate capabilities of Copper64 library (all are placed in `examples` directory):
* [`e01-color-raster-bars.asm`](https://github.com/c64lib/copper64/blob/master/examples/e01-color-raster-bars.asm) - shows colorful raster bars using different combination of border, background and both while playing Noisy Pillars of Jeroen Tel in the background.
* [`e02-screen-modes.asm`](https://github.com/c64lib/copper64/blob/master/examples/e02-screen-modes.asm) - shows several different screen modes mixed together.
* [`e03-bitmap-demo.asm`](https://github.com/c64lib/copper64/blob/master/examples/e03-bitmap-demo.asm) - mixes regular text and hires bitmap modes while playing music and animating background.

For more sophisticated example please refer my [bluevessel](https://github.com/maciejmalecki/bluevessel) intro.

As library management system is not yet complete, you have to do several steps manually in order to be able to assembly and run examples. One possible approach is following:
1. Create new directory and name it i.e.: `c64lib`
2. Inside of this directory clone `common`, `chipset`, `text` and `copper64` libraries:

   git clone https://github.com/c64lib/common.git
   
   git clone https://github.com/c64lib/chipset.git
   
   git clone https://github.com/c64lib/text.git
   
   git clone https://github.com/c64lib/copper64.git
   
3. Assuming that your KickAssembler JAR file is located under `c:\cbm\KickAss.jar` and your `c64lib` directory is located under `c:\cbm\c64lib` run assembler inside of `examples` directory:

	> java -jar c:\cbm\KickAss.jar -libdir c:\cbm\c64lib e01-color-raster-bars.asm 
	>
	> java -jar c:\cbm\KickAss.jar -libdir c:\cbm\c64lib e02-screen-modes.asm
	>
	> java -jar c:\cbm\KickAss.jar -libdir c:\cbm\c64lib e03-bitmap-demo.asm
	
4. In result you should get three PRG files that can be launched using VICE or transferred to real hardware and launched there.

## Define your own copper list
Easiest way to learn how to create own "copper list" is to study one of examples that are provided in copper64 repository. Copper list is a data structure that should fit entirely into single page of memory (256b) - to ensure this always use `.align $100` directive prior list declaration. Definition of copper list is simplified due to two KickAssembler macros: `copperEntry` and `copperLoop`.

`copperEntry` can be used multiple times to "install" one of few available IRQ handlers at given raster position. `copperLoop` must always be a last position in display list and it informs copper64 that the list is over and it should loop to the beginning.

Let's look at following example:

	.align $100
	copperList: {
	  copperEntry(46, c64lib.IRQH_BORDER_COL, WHITE, 0)
	  copperEntry(81, c64lib.IRQH_BG_COL_0, YELLOW, 0)
	  copperEntry(101, c64lib.IRQH_BG_COL_0, LIGHT_GREEN, 0)
	  copperEntry(124, c64lib.IRQH_BG_COL_0, GREY, 0)
	  copperEntry(131, c64lib.IRQH_BG_COL_0, BLUE, 0)
	  copperEntry(150, c64lib.IRQH_BORDER_COL, RED, 0)
	  copperEntry(216, c64lib.IRQH_BORDER_BG_0_COL, LIGHT_GREY, $00)
	  copperEntry(221, c64lib.IRQH_BORDER_BG_0_COL, GREY, $00)
	  copperEntry(227, c64lib.IRQH_BORDER_BG_0_COL, DARK_GREY, $00)
	  copperEntry(232, c64lib.IRQH_BORDER_BG_0_DIFF, RED, BLUE)
	  copperEntry(252, c64lib.IRQH_BORDER_COL, LIGHT_BLUE, 0)
	  copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
	  copperLoop()
	}

We mark beginning of the list with label (`copperList`), because we need this address later on when initializing copper64. 

Then we have sequence of copper entries, each taking couple of parameters. First parameter is always a raster line (we can use here numbers greater than 255, macro takes care of handling this extra bit). It is up to coder to ensure that these numbers are ordered and growing. If you mess up ordering, you'll get junk on the screen - you have been warned.

Copper64 uses double interrupt technique to stabilize raster. Therefore you cannot install handlers too often - there will be not enough time to launch next handler just because of this stabilization that can take up to 3 raster lines. You also need to remember, that stabilization does not support active sprites (yet) nor bad lines. So, you should place your entries wisely.

Second attribute to the entry is always a handler code. All supported handlers are defined as KickAssembler labels in copper64 library (all of them start with `IRQH_` prefix). There is one limitation: overall size of handlers code cannot extend single memory page (256 bytes). In consequence, all existing handlers cannot be used in the same time (they weight too much), therefore there is enabling mechanism available. In your program you must enable each handler that you're going to use manually:

	#define IRQH_BORDER_COL
	#define IRQH_BG_COL_0
	#define IRQH_BORDER_BG_0_COL
	#define IRQH_BORDER_BG_0_DIFF
	#define IRQH_JSR

	#import "chipset/lib/mos6510.asm"
	#import "chipset/lib/vic2.asm"
	#import "text/lib/text.asm"
	#import "copper64/lib/copper64.asm"
 
As you see you can do it with `#define` directive. Just make sure that you define all of them before importing `copper64.asm`, otherwise it will not work.

Next two parameters have different meaning depending on the handler.

Examples:

	copperEntry(46, c64lib.IRQH_BORDER_COL, WHITE, 0)

Changes border color to WHITE in line 46. In this case last parameter is not used, we set it to 0.

	copperEntry(232, c64lib.IRQH_BORDER_BG_0_DIFF, RED, BLUE)

Changes border color to RED and background color to BLUE in line 232.

	copperEntry(257, c64lib.IRQH_JSR, <custom1, >custom1)
	
Launches custom subroutine at line 257, address of this subroutine is specified in last two parameters.

## Initialize IRQ system
The `initCopper` macro installs copper64 initialization routine that can be then called with jsr. Macro takes two parameters - an arbitrary chosen addresses on zero page. That's it - copper64 requires only two zero page registers for functioning. It's up to you which two to choose.

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
	  lda $ff00,y
	  jmp block			// infinite loop
	copper: {
	  initCopper(DISPLAY_LIST_PTR_LO, LIST_PTR)
	}


# IRQ handlers reference
## Set border color
Changes border color.

* __Handler label:__ `IRQH_BORDER_COL`
* __Handler code:__ `1`
* __Argument 1:__ desired border color; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BORDER_COL, <color>, 0)
```

## Set background color 0
Changes background color 0.

* __Handler label:__ `IRQH_BG_COL_0`
* __Handler code:__ `2`
* __Argument 1:__ desired background 0 color; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BG_COL_0, <color>, 0)
```

## Set background color 1
Changes background color 1.

* __Handler label:__ `IRQH_BG_COL_1`
* __Handler code:__ `3`
* __Argument 1:__ desired background 1 color; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BG_COL_1, <color>, 0)
```

## Set background color 2
Changes background color 2.

* __Handler label:__ `IRQH_BG_COL_2`
* __Handler code:__ `4`
* __Argument 1:__ desired background 2 color; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BG_COL_2, <color>, 0)
```

## Set background color 3
Changes background color 3.

* __Handler label:__ `IRQH_BG_COL_3`
* __Handler code:__ `5`
* __Argument 1:__ desired background 3 color; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BG_COL_3, <color>, 0)
```

## Set border and background 0 color uniformly
Changes background color 0 and border color to the same color.

* __Handler label:__ `IRQH_BORDER_BG_0_COL`
* __Handler code:__ `6`
* __Argument 1:__ desired color for border and background 0; `0..15`
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BORDER_BG_0_COL, <color>, 0)
```

## Set border and background 0 color separately
Changes background color 0 and border color to another values in single step, the colors are specified as arguments.

* __Handler label:__ `IRQH_BORDER_BG_0_DIFF`
* __Handler code:__ `7`
* __Argument 1:__ desired color for border; `0..15`
* __Argument 2:__ desired color for background 0; `0..15`
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BORDER_BG_0_DIFF, <border color>, <background color>)
```

## Set VIC memory register and VIC memory bank
Changes VIC memory control and VIC memory bank in one step.

* __Handler label:__ `IRQH_MEM_BANK`
* __Handler code:__ `8`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MEM_BANK, <memory control>, <vic bank number>)
```

## Set VIC mode and memory settings
Changes VIC display mode and memory settings in one step. VIC bank cannot be changed.

* __Handler label:__ `IRQH_MODE_MEM`
* __Handler code:__ `9`
* __Argument 1:__ mode of vic2; for performance reasons the values for two control registers are packed in one byte: `%00010000` for Multicolor, `%01100000` for ECM or Bitmap
* __Argument 2:__ value for `MEMORY_CONTROL` register
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_MEM, <vic mode>, <memory control>)
```

## Jump to custom subroutine
Jumps to custom subroutine that can do whatever you want, i.e. play music. Subroutine must end with `rts`.

* __Handler label:__ `IRQH_JSR`
* __Handler code:__ `10`
* __Argument 1:__ Low byte of subroutine address
* __Argument 2:__ High byte of subroutine address
* __Cycled:__ no

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_JSR, <address, >address)
```

## Set hires bitmap mode
Sets up hires bitmap mode using given memory layout and VIC bank. Useful for screen splits using totally different memory locations for VIC chip.

* __Handler label:__ `IRQH_MODE_HIRES_BITMAP`
* __Handler code:__ `11`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_HIRES_BITMAP, <memory control>, <vic bank number>)
```

## Set multicolor mode
Sets up multicolor bitmap mode using given memory layout and VIC bank. Useful for screen splits using totally different memory locations for VIC chip.

* __Handler label:__ `IRQH_MODE_MULTIC_BITMAP`
* __Handler code:__ `12`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_MULTIC_BITMAP, <memory control>, <vic bank number>)
```

## Set hires text mode
Sets up hires text mode using given memory layout and VIC bank. Useful for screen splits using totally different memory locations for VIC chip.

* __Handler label:__ `IRQH_MODE_HIRES_TEXT`
* __Handler code:__ `13`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_HIRES_TEXT, <memory control>, <vic bank number>)
```

## Set multicolor text mode
Sets up multicolor text mode using given memory layout and VIC bank. Useful for screen splits using totally different memory locations for VIC chip.

* __Handler label:__ `IRQH_MODE_MULTIC_TEXT`
* __Handler code:__ `14`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_MULTIC_TEXT, <memory control>, <vic bank number>)
```

## Set extended background mode
Sets up extended text mode using given memory layout and VIC bank. Useful for screen splits using totally different memory locations for VIC chip.

* __Handler label:__ `IRQH_MODE_EXTENDED_TEXT`
* __Handler code:__ `15`
* __Argument 1:__ value for `MEMORY_CONTROL` register
* __Argument 2:__ value for VIC bank (goes to `CIA2_DATA_PORT_A`); only two least significant bits are taken, other bits of the data port are preserved
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_MODE_EXTENDED_TEXT, <memory control>, <vic bank number>)
```

## Full raster bar
Generates colorful raster bar across whole screen including border. Color for each subsequent bar line is fetched from `$FF` terminated array of colors (values `0..15`). Because procedure is cycled using busy waiting on raster, a raster time for whole bar will be consumed. Color array can be cycled or modified in any way to get interesting animation effects.

* __Handler label:__ `IRQH_FULL_RASTER_BAR`
* __Handler code:__ `16`
* __Argument 1:__ Low byte of bar color definition address
* __Argument 2:__ High byte of bar color definition address
* __Cycled:__ yes (PAL, 63 cycles) - it sucks on badlines however

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_FULL_RASTER_BAR, <address, >address)
```

## Background-only raster bar
Generates colorful raster bar across whole background. Color for each subsequent bar line is fetched from `$FF` terminated array of colors (values `0..15`). Because procedure is cycled using busy waiting on raster, a raster time for whole bar will be consumed. Color array can be cycled or modified in any way to get interesting animation effects.

* __Handler label:__ `IRQH_BG_RASTER_BAR`
* __Handler code:__ `17`
* __Argument 1:__ Low byte of bar color definition address
* __Argument 2:__ High byte of bar color definition address
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_BG_RASTER_BAR, <colorCycleDef, >colorCycleDef)
...
colorCycleDef:  .byte COLOR_3, LIGHT_RED, RED, LIGHT_RED, YELLOW, WHITE, YELLOW, YELLOW, COLOR_3, $ff
```

## Horizontal scroll
Scrolls screen horizontally using specified amount of pixels.

* __Handler label:__ `IRQH_HSCROLL`
* __Handler code:__ `17`
* __Argument 1:__ value for horizontal scroll register (`0..7`)
* __Argument 2:__ unused
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_HSCROLL, <scroll value>, 0)
```

## Mapped horizontal scroll
Applies shallow tech-tech effect (using values `0..7`) starting from given raster position. Horizontal scroll value for each corresponding raster line is taken from `$FF` terminated array of values, each should contain value from `0..7` range. The scroll map can be further modified (i.e. rotated) to achieve interesting animation effects.

* __Handler label:__ `IRQH_HSCROLL_MAP`
* __Handler code:__ `17`
* __Argument 1:__ low byte of scroll map definition address
* __Argument 2:__ high value of scroll map definition address
* __Cycled:__ yes (PAL, 63 cycles)

Usage:
```(assembler)
copperEntry(<raster>, c64lib.IRQH_HSCROLL_MAP, <hscrollMapDef, >hscrollMapDef)
...
hscrollMapDef:  .fill TECH_TECH_WIDTH, round(3.5 + 3.5*sin(toRadians(i*360/TECH_TECH_WIDTH))) ; .byte 0; .byte $ff
```

# Data model
Copper64 operates on IRQ table consisting of IRQ entries. Each IRQ entry is
a following structure of 4 bytes:

<table>
	<tr>
		<th>Offset</th><th>Code</th><th>Description</th>
	</tr>
	<tr>
		<td>0</td><td>CTRL</td><td>Control byte; specifies handler id and some additional data.</td>
	</tr>
	<tr>
		<td>1</td><td>RAS</td><td>Raster counter; low 8 bits of raster counter. 9-th bit is stored in CTRL.</td>
	</tr>
	<tr>
		<td>2</td><td>DAT1</td><td>Data byte 1</td>
	</tr>
	<tr>
		<td>3</td><td>DAT2</td><td>Data byte 2</td>
	</tr>
</table>

Control byte (CTRL) has following meaning:

<table>
	<tr><td>$00</td><td>stop</td></tr>
	<tr><td>$FF</td><td>loop</td></tr>
	<tr><td>b7</td><td>raster 8</td></tr>
	<tr><td>b6</td><td>reserved</td></tr>
	<tr><td>b5</td><td>reserved</td></tr>
	<tr><td>b4..0</td><td>function - 1..31</td></tr>
</table>

# Change log	
## Changes in 0.2.0

* Public symbols defined as global in "-global.asm" file