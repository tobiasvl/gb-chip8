; vi:syntax=rgbds

INCLUDE "hardware.inc" ; standard hardware definitions from devrs.com

; IRQs
SECTION    "Vblank",ROM0[$0040]
    reti
SECTION    "LCDC",ROM0[$0048]
    reti
SECTION    "Timer_Overflow",ROM0[$0050]
    reti
SECTION    "Serial",ROM0[$0058]
    reti
SECTION    "p1thru4",ROM0[$0060]
    reti

SECTION "FreeSpace",ROM0[$0068]
INCLUDE "memory.inc"

wait_vblank:
    halt
    ret

StartLCD:
    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld [rLCDC], a
    ret

StopLCD:
    ld a, [rLCDC]
    rlca                ; Put the high bit of LCDC into the Carry flag
    ret nc              ; Screen is off already. Exit.
    call wait_vblank
; Turn off the LCD
    ld a, [rLCDC]
    res 7, a            ; Reset bit 7 of LCDC
    ld [rLCDC], a
    ret

SECTION    "start",ROM0[$0100]
nop
jp    begin

Nintendo_logo:
INCLUDE "header.inc"
 ROM_HEADER    CART_ROM, CART_ROM_256K, CART_RAM_NONE

SECTION "HiRAM", HRAM

hPadPressed::   ds 1
hPadHeld::      ds 1
hPadReleased::  ds 1
hPadOld::       ds 1

SECTION "Joypad", ROM0

BUTTON_A        EQU %00000001
BUTTON_B        EQU %00000010
BUTTON_SELECT   EQU %00000100
BUTTON_START    EQU %00001000
BUTTON_RIGHT    EQU %00010000
BUTTON_LEFT     EQU %00100000
BUTTON_UP       EQU %01000000
BUTTON_DOWN     EQU %10000000

ReadJoyPad::
    ldh     a,[hPadHeld]
    ldh     [hPadOld],a
    ld      c,a
    ld      a,$20
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $0F
    swap    a
    ld      b,a
    ld      a,$10
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $0F
    or      b
    ldh     [hPadHeld],a
    ld      b,a
    ld      a,c
    cpl
    and     b
    ldh     [hPadPressed],a
    xor     a
    ldh     [rP1],a
    ldh     a,[hPadOld]
    ld      b,a
    ldh     a,[hPadHeld]
    cpl
    and     b
    ldh     [hPadReleased],a
    ret

SECTION "Game", ROM0[$200]
GAME: INCBIN "game.rom"

SECTION "Registers", WRAM0
REGISTERS:
V0 DB
V1 DB
V2 DB
V3 DB
V4 DB
V5 DB
V6 DB
V7 DB
V8 DB
V9 DB
VA DB
VB DB
VC DB
VD DB
VE DB
VF DB
I DW
rPC DW

SECTION "Timers", WRAM0
DELAY DB
SOUND DB

SECTION "Screen", WRAM0
SCREEN DS (64 * 32) / 8

SECTION "Game logic", ROM0

begin:
    ; Initialize stack
    ld sp, $e000

    ; Enable interrupts
    ld a, IEF_VBLANK
    ld [rIE], a
    ei

    ; Initialize memory
    call StopLCD
    ; Blank VRAM
    xor a
    ld hl, _VRAM
    ld bc, $9000-_VRAM
    call mem_SetVRAM
    call StartLCD

    ; Registers start at 0
    xor a
    ld hl, REGISTERS
    REPT 16
    ld [hl+], a
    ENDR
    ld [I], a
    ld [SOUND], a
    ld [DELAY], a

    ; PC starts at $200
    ld hl, rPC
    ld [hl+], a
    ld [hl], $02

game_loop:
    ; hl = PC
    ; de = current opcode
    ; Opcodes are 2 bytes
    halt

    call DecrementTimers

    call ReadPC

    ; Decode opcode
    ld a, d
    and a, $F0

    cp a, $00
    jr z, Opcode00
    cp a, $10
    jp z, Opcode1NNN
    cp a, $20
    jp z, Opcode2NNN
    cp a, $30
    jp z, Opcode3XNN
    cp a, $40
    jp z, Opcode4XNN
    cp a, $50
    jp z, Opcode5XY0
    cp a, $60
    jp z, Opcode6XNN
    cp a, $70
    jp z, Opcode7XNN
    cp a, $80
    jr z, Opcode8X
    cp a, $90
    jp z, Opcode9XY0
    cp a, $A0
    jp z, OpcodeANNN
    cp a, $B0
    jp z, OpcodeBNNN
    cp a, $C0
    jp z, OpcodeCXNN
    cp a, $D0
    jp z, OpcodeDXYN
    cp a, $E0
    jr z, OpcodeEX
    cp a, $F0
    jr z, OpcodeFX
    jp game_loop

Opcode00:
    ld a, e
    cp a, $E0
    jp z, Opcode00E0
    cp a, $EE
    jp z, Opcode00EE
    jp game_loop

Opcode8X:
    ld a, e
    and a, $0F
    cp a, $1
    jp z, Opcode8XY1
    cp a, $2
    jp z, Opcode8XY2
    cp a, $3
    jp z, Opcode8XY3
    cp a, $4
    jp z, Opcode8XY4
    cp a, $5
    jp z, Opcode8XY5
    cp a, $6
    jp z, Opcode8XY6
    cp a, $7
    jp z, Opcode8XY7
    cp a, $E
    jp z, Opcode8XYE
    jp game_loop

OpcodeEX:
    ld a, e
    cp a, $9E
    jp z, OpcodeEX9E
    cp a, $A1
    jp z, OpcodeEXA1
    jp game_loop

OpcodeFX:
    ld a, e
    cp a, $07
    jp z, OpcodeFX07
    cp a, $0A
    jp z, OpcodeFX0A
    cp a, $15
    jp z, OpcodeFX15
    cp a, $18
    jp z, OpcodeFX18
    cp a, $1E
    jp z, OpcodeFX1E
    cp a, $29
    jp z, OpcodeFX29
    cp a, $33
    jp z, OpcodeFX33
    cp a, $55
    jp z, OpcodeFX55
    cp a, $65
    jp z, OpcodeFX65
    jp game_loop

Opcode00E0:
    ; Blank VRAM
    call StopLCD
    xor a
    ld hl, _VRAM
    ld bc, $9000-_VRAM
    call mem_SetVRAM
    call StartLCD
    call AdvancePC
    jp game_loop

Opcode00EE:
    ; return
    pop hl
    ld a, l
    ld [rPC], a
    ld a, h
    ld [rPC+1], a

    call AdvancePC
    jp game_loop

Opcode1NNN:
    ; jump to address $NNN
    ld a, d
    and a, $0F
    ld [rPC], a
    ld a, e
    ld [rPC+1], a
    jp game_loop

Opcode2NNN:
    ; call address $NNN
    ld a, d
    and a, $0F
    ld [rPC+1], a
    ld a, e
    ld [rPC], a
    push hl
    jp game_loop

Opcode3XNN:
    ; if VX == NN: skip next instruction
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h   ; hl = VX
    ld h, a
    ld a, [hl]
    ld b, a    ; b = [VX]

    ld a, e    ; a = NN

    cp a, b
    jp nz, .no_skip
    ; Skip next instruction:
    call AdvancePC
.no_skip:
    call AdvancePC
    jp game_loop

Opcode4XNN:
    ; if VX != NN: skip next instruction
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h   ; hl = VX
    ld h, a
    ld a, [hl]
    ld b, a    ; b = [VX]

    ld a, e    ; a = NN

    cp a, b
    jp z, .no_skip
    ; Skip next instruction:
    call AdvancePC
.no_skip:
    call AdvancePC
    jp game_loop

Opcode5XY0:
    ; if VX == VY: skip next instruction
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a
    ld a, [hl]
    ld b, a

    ld hl, REGISTERS
    ld a, e
    and a, $F0
    swap a ; a = Y
    add a, h
    ld a, [hl]

    cp a, b
    jp nz, .no_skip
    ; Skip next instruction:
    call AdvancePC
.no_skip:
    call AdvancePC
    jp game_loop

Opcode6XNN:
    ; VX = NN
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, l
    ld l, a

    ld [hl], e
    call AdvancePC
    jp game_loop

Opcode7XNN:
    ; VX += NN
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a

    ld a, e ; a = NN

    add a, [hl]
    ld [hl], a
    call AdvancePC
    jp game_loop

Opcode8XY0:
    ; VX = VY
    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld [hl], b ; VX = VY
    call AdvancePC
    jp game_loop

Opcode8XY1:
    ; VX = VX | VY
    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    or a, [hl]
    ld [hl], a ; VX = VY
    call AdvancePC
    jp game_loop

Opcode8XY2:
    ; VX = VX & VY
    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    and a, [hl]
    ld [hl], a ; VX = VY
    call AdvancePC
    jp game_loop

Opcode8XY3:
    ; VX = VX ^ VY
    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    xor a, [hl]
    ld [hl], a ; VX = VY
    call AdvancePC
    jp game_loop

Opcode8XY4:
    ; VX = VX + VY (VF = carry)
    xor a
    ld [VF], a

    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld b, [hl] ; a = VY

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    sub a, [hl]
    ld [hl], a ; VX = VY
    jr nc, .no_carry

    ld hl, VF
    ld [hl], 1
.no_carry:
    call AdvancePC
    jp game_loop

Opcode8XY5:
    ; VX = VX - VY (VF = carry)
    ld hl, VF
    ld [hl], 1

    ld hl, REGISTERS
    and a, $0F
    add a, h
    ld h, a
    ld a, [hl]
    ld b, a
    push hl

    ld hl, REGISTERS
    ld a, e
    and a, $F0
    swap a
    add a, h
    ld a, [hl]

    sub a, b ; b, a
    pop hl
    ld [hl], a ; ld [VX], a

    jr nc, .no_borrow
    xor a
    ld [VF], a ; carry
.no_borrow:
    call AdvancePC
    jp game_loop

Opcode8XY6:
    ; VX = VY >>= 1 (VF = carry)
    xor a
    ld [VF], a

    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    srl a ; sra?
    ld [hl], a ; VX = VY
    jr nc, .no_carry

    ld hl, VF
    ld [hl], 1
.no_carry:
    call AdvancePC
    jp game_loop

Opcode8XY7:
    ; VX = VY - VX (VF = carry)
    ld hl, VF
    ld [hl], 1

    ld hl, REGISTERS
    ld a, e
    and a, $F0
    swap a
    add a, h
    ld a, [hl]

    ld hl, REGISTERS
    and a, $0F
    add a, h
    ld h, a
    ld a, [hl]
    ld b, a

    sub a, b ; b, a
    ld [hl], a ; ld [VX], a

    jr nc, .borrow
    xor a
    ld [VF], a ; carry
.borrow:
    call AdvancePC
    jp game_loop

Opcode8XYE:
    ; VX = VY <<= 1 (VF = carry)
    xor a
    ld [VF], a

    ld hl, REGISTERS
    ld a, e
    and a, $F0 ; a = Y
    swap a
    add a, h
    ld a, [hl] ; a = VY
    ld b, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, b
    sla a
    ld [hl], a ; VX = VY
    jr nc, .no_carry

    ld hl, VF
    ld [hl], 1
.no_carry:
    call AdvancePC
    jp game_loop

Opcode9XY0:
    ; if VX != VY: skip next instruction
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a
    ld a, [hl]
    ld b, a

    ld hl, REGISTERS
    ld a, e
    and a, $F0
    swap a ; a = Y
    add a, h
    ld a, [hl]

    cp a, b
    jp z, .no_skip
    ; Skip next instruction:
    call AdvancePC
.no_skip:
    call AdvancePC
    jp game_loop

OpcodeANNN:
    ; I = NNN
    ld a, d
    and a, $0F

    ld hl, I
    ld [hl], d
    inc hl
    ld [hl], e

    call AdvancePC
    jp game_loop

OpcodeBNNN:
    ; jump to address $NNN + V0
    ld a, d
    and a, $0F
    ld d, a
    
    ; TODO

    ld [hl], d
    inc hl
    ld [hl], e
    jp game_loop

OpcodeCXNN:
    ; VX = rand() & NN
    ld a, e
    ld hl, rDIV
    and a, [hl]
    ld e, a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a

    ld [hl], e

    call AdvancePC
    jp game_loop

OpcodeDXYN:
    ; TODO draw pixels
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a
    ld a, [hl]
    ld b, a ; b = VX

    ld hl, REGISTERS
    ld a, e
    and a, $F0
    swap a ; a = Y
    add a, h
    ld a, [hl] ; a = VY
    ld c, a ; c = VY

    ld a, e
    and a, $0F ; a = N

    ld d, c
    ld e, b
    call get_map_position

    ld hl, I

    call AdvancePC
    jp game_loop

get_map_position:
; from a sprite's pixel position, get the BG map address.
; d: Y pixel position
; e: X pixel position
; hl: returned map address
    push af

    ld h, HIGH(_SCRN0) >> 2

    ; Y
    ;ld a, [rSCY] ; account for scroll
    add a, d
    and $F8      ; snap to grid
    add a, a
    rl h
    add a, a
    rl h
    ld l, a

    ; X
    ;ld a, [rSCX] ; account for scroll
    add a, e
    and $F8      ; snap to grid
    rrca
    rrca
    rrca
    add a, l
    ld l, a

    pop af
    ret

OpcodeEX9E:
    ; TODO joypad
    jp game_loop

OpcodeEXA1:
    ; TODO joypad
    jp game_loop

OpcodeFX07:
    ; VX = DELAY
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, [DELAY]
    ld [hl], a
    call AdvancePC
    jp game_loop

OpcodeFX0A:
    ; TODO joypad
    jp game_loop

OpcodeFX15:
    ; DELAY = VX
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, [hl]
    ld [DELAY], a

    call AdvancePC
    jp game_loop

OpcodeFX18:
    ; SOUND = VX
    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, [hl]
    ld [SOUND], a

    call AdvancePC
    jp game_loop

OpcodeFX1E:
    ; I = VX + I (VF = carry)
    xor a
    ld [VF], a

    ld hl, REGISTERS
    ld a, d
    and a, $0F ; a = X
    add a, h
    ld h, a ; hl = VX

    ld a, [hl]

    ld hl, I
    add a, [hl]
    ld [I], a

    jr nc, .no_carry

    ld hl, VF
    ld [hl], 1
.no_carry:
    call AdvancePC
    jp game_loop

OpcodeFX29:
    ; TODO I = sprite_addr[VX]
    jp game_loop

OpcodeFX33:
    ; TODO BCD
    jp game_loop

OpcodeFX55:
    ; dump registers V0–VX to I
    ld a, d
    and a, $0F ; a = X
    ld b, a    ; b = X counter
    inc b

    ld hl, V0
.loop:
    push hl
    ld hl, I
    ld a, [hl+]
    ld e, [hl]
    ld d, a
    pop hl
    ld a, [hl]
    ld [de], a
    inc hl
    ld a, h
    ld [I], a
    ld a, l
    ld [I+1], a
    dec b
    jr nz, .loop
    call AdvancePC
    jp game_loop

OpcodeFX65:
    ; dump I to registers V0–VX
    ; TODO
;
;    ld a, d
;    and a, $0F ; a = X
;    ld b, a    ; b = X counter
;    inc b
;
;    ld hl, V0
;.loop:
;    push hl
;    ld hl, I
;    ld a, [hl+]
;    ld e, [hl]
;    ld d, a
;    pop hl
;    ld a, [hl]
;    ld [de], a
;    inc hl
;    ld a, h
;    ld [I], a
;    ld a, l
;    ld [I+1], a
;    dec b
;    jr nz, .loop
;    jp game_loop

ReadPC:
    ; hl = PC
    ; de = opcode
    ld a, [rPC]
    ld l, a
    ld a, [rPC+1]
    ld h, a
    ld d, [hl]
    inc hl
    ld e, [hl]
    dec hl
    ret

AdvancePC:
    call ReadPC
    inc hl
    inc hl
    ld a, l
    ld [rPC], a
    ld a, h
    ld [rPC+1], a
    ret

DecrementTimers:
    ; Decrement timers
    ld hl, SOUND
    ld a, [hl]
    and a
    jr z, .delay
    cp a, 1
    jr z, .decrement_sound
    ; Beep:
    ld a, $83
    ldh [$FF13], a
    ld a, $87
    ldh [$FF14], a
.decrement_sound:
    dec [hl]
.delay:
    ld hl, DELAY
    ld a, [hl]
    and a
    ret z
    dec [hl]
    ret
