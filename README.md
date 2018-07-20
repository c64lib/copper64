# copper64

A library that realizes a copper-like functionality of firing certain predefined handlers 
at programmable raster lines. This library utilizes raster interrupt functionality of VIC-II.

## Build status

* master: [![Build Status](https://travis-ci.org/c64lib/copper64.svg?branch=master)](https://travis-ci.org/c64lib/copper64)

# Usage
## Using as KickAssembler library
The concept of writing libraries for KickAssembler has been already roughly sketched in my blog [post](https://maciejmalecki.github.io/blog/assembler-libraries). Copper64 is intended to be a library too. Copper64 requires other c64lib libraries such as common, chipset and text.

## Running examples
As for now there are three example programs available that demonstrate capabilities of Copper64 library (all are placed in `examples` directory):
* [`e01-color-raster-bars.asm`](https://github.com/c64lib/copper64/blob/master/examples/e01-color-raster-bars.asm) - shows colorful raster bars using different combination of border, background and both while playing Noisy Pillars of Jeroen Tel in the background.
* [`e02-screen-modes.asm`](https://github.com/c64lib/copper64/blob/master/examples/e02-screen-modes.asm) - shows several different screen modes mixed together.
* [`e03-bitmap-demo.asm`](https://github.com/c64lib/copper64/blob/master/examples/e03-bitmap-demo.asm) - mixes regular text and hires bitmap modes while playing music and animating background.

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

	#import "chipset/mos6510.asm"
	#import "chipset/vic2.asm"
	#import "text/text.asm"
	#import "../copper64.asm"
 
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
Changes border color, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BORDER_COL</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>1</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for border</td>
	</tr>
</table>

## Set background color 0
Changes background color 0, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BG_COL_0</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>2</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for background 0</td>
	</tr>
</table>

## Set background color 1
Changes background color 1, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BG_COL_1</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>3</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for background 1</td>
	</tr>
</table>

## Set background color 2
Changes background color 2, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BG_COL_2</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>4</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for background 2</td>
	</tr>
</table>

## Set background color 3
Changes background color 3, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BG_COL_3</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>5</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for background 3</td>
	</tr>
</table>

## Set border and background 0 color uniformly
Changes background color 0 and border color to the same color, the color can be specified as argument 1.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BORDER_BG_0_COL</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>6</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Common color code for background 0 and border</td>
	</tr>
</table>

## Set border and background 0 color separately
Changes background color 0 and border color to another values in single step, the colors are specified as arguments.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_BORDER_BG_0_DIFF</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>7</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for border</td>
	</tr>
	<tr>
		<th>Argument 2</th><td>Color code for background 0</td>
	</tr>
</table>

## Set VIC memory register and VIC memory bank
Changes VIC memory control and VIC memory bank in one step.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_MEM_BANK</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>8</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Value for MEMORY_CONTROL register</td>
	</tr>
	<tr>
		<th>Argument 2</th><td>Value for VIC bank</td>
	</tr>
</table>

## Set VIC mode and memory settings
Changes VIC display mode and memory settings in one step. VIC bank cannot be changed.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_MODE_MEM</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>9</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Values for two control registers are packed in one byte: `%00010000` for Multicolor, `%01100000` for ECM or Bitmap</td>
	</tr>
	<tr>
		<th>Argument 2</th><td>Value for MEMORY_CONTROL register</td>
	</tr>
</table>

## Jump to custom subroutine
Jumps to custom subroutine that can do whatever you want, i.e. play music. Subroutine must end with `rts`.
<table>
	<tr>
		<th>Handler label</th><td><code>IRQH_JSR</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>10</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Low byte of subroutine address</td>
	</tr>
	<tr>
		<th>Argument 2</th><td>High byte of subroutine address</td>
	</tr>
</table>

## Set hires bitmap mode

## Set multicolor mode

## Set hires text mode

## Set multicolor text mode

## Set extended background mode

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
	
