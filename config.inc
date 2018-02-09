;; Configuration of the Chip-8 interpreter
; Please follow the instructions in the comments
; (lines starting with semicolons) and do not change anything
; else in this file.

KEYPAD_MAPPING:

; Change the values after the dollar ($) signs to map a
; Chip-8 hex key to the corresponding Game Boy button:

.Left: db    $4
.Right: db   $6
.Up: db      $8
.Down: db    $2
.A: db       $0
.B: db       $0
.Select: db  $0
.Start: db   $0

;;;;;;;;;;;;;;;;;;;;;;;;

GAME_ROM:

; Change the file name between the quotation marks to load a different
; Chip-8 game ROM. The file must be located in this directory or the
; inc/ subdirectory. (Alternatively, you can just leave this value
; unchanged and rename the ROM file to "game.rom".)

INCBIN "game.rom"

