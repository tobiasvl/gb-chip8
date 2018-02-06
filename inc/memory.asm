; vi:syntax=rgbds
; https://github.com/assemblydigest/gameboy/blob/master/part-3-libraries/memory.z80

; Fills a range in memory with a specified byte value.
; hl = destination address
; bc = byte count
; a = byte value
memset:
    inc c
    inc b
    jr .start
.repeat:
    ld [hl+], a
.start:
    dec c
    jr nz, .repeat
    dec b
    jr nz, .repeat
ret

; Copies count bytes from source to destination.
; de = destination address
; hl = source address
; bc = byte count
memcpy:
    inc c
    inc b
    jr .start
.repeat:
    ld a, [hl+]
    ld [de], a
    inc de
.start:
    dec c
    jr nz, .repeat
    dec b
    jr nz, .repeat
ret
