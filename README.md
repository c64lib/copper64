# copper64

A library that realizes a copper-like functionality of firing certain predefined handlers 
at programmable raster lines. This library utilizes raster interrupt functionality of VIC-II.

## Build status

* master: [![Build Status](https://travis-ci.org/c64lib/copper64.svg?branch=master)](https://travis-ci.org/c64lib/copper64)
* develop: [![Build Status](https://travis-ci.org/c64lib/copper64.svg?branch=develop)](https://travis-ci.org/c64lib/copper64)

# IRQ handlers
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
		<th>Handler label</th><td><code>IRQH_BORDER_BG_0_COL</code></td>
	</tr>
	<tr>
		<th>Handler code</th><td><code>6</code></td>
	</tr>
	<tr>
		<th>Argument 1</th><td>Color code for border</td>
	</tr>
	<tr>
		<th>Argument 2</th><td>Color code for background 0</td>
	</tr>
</table>

## Set VIC memory register and VIC memory bank

## Set VIC memory register

## Set VIC mode, memory register and memory bank

## Set VIC mode and memory register

## Set VIC mode

## Jump to subroutine

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
	
