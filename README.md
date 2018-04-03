# copper64

## Data model
Copper64 operates on IRQ table consisting of IRQ entries. Each IRQ entry is
a following structure of 4 bytes:

<table>
	<th>
		<td>Offset</td><td>Code</td><td>Description</td>
	</th>
	<tr>
		<td>0</td><td>CTRL</td><td>Control byte</td>
	</tr>
	<tr>
		<td>1</td><td>RAS</td><td>Raster counter</td>
	</tr>
	<tr>
		<td>2</td><td>DAT1</td><td>Data field 1</td>
	</tr>
	<tr>
		<td>3</td><td>DAT2</td><td>Data field 2</td>
	</tr>
</table>

Control byte (CTRL) has following meaning:

<table>
	<tr><td>$00</td><td>stop</td></tr>
	<tr><td>b7</td><td>raster 8</td></tr>
	<tr><td>b6</td><td>reserved</td></tr>
	<tr><td>b5</td><td>reserved</td></tr>
	<tr><td>b4..0/td><td>function - 1..31</td></tr>
	<tr><td>$FF</td><td>loop</td></tr>
</table>
	
