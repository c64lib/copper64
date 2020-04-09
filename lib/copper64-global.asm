#import "copper64.asm"
#importonce
.filenamespace c64lib

.macro @c64lib_copperEntry(raster, handler, arg1, arg2) { copperEntry(raster, handler, arg1, arg2) }
.macro @c64lib_copperLoop() { copperLoop() }
.macro @c64lib_startCopper(listStart, listPtr, handlersList) { startCopper(listStart, listPtr, handlersList) }
.macro @c64lib_stopCopper() { stopCopper() }
