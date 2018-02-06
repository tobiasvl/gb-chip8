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

SECTION "Memory", ROM0 ; TODO Align
MEMORY DS $200
GAME: INCBIN "game.rom"

SECTION "Registers", WRAM0
REGISTERS:
I DW
rPC DW
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

SECTION "Screen", WRAM0
SCREEN DS 64*32

SECTION "Game logic", ROM0

begin:
    ; Initialize stack
    ld sp, $e000
    ; Enable interrupts
    ld a, IEF_VBLANK
    ld [rIE], a
    ei

    ; Initialize registers
    xor a

    ; V0-VF start at 0
    ld hl, REGISTERS
    REPT 16
    ld [hl+], a
    ENDR

    ; I starts at 0
    ld [I], a

    ; PC starts at $200
    ld hl, rPC
    ld [hl+], a
    ld a, $02
    ld [hl], a

game_loop:
    ; Opcodes are 2 bytes
    ld hl, rPC
    ld a, [hl+]
    ld b, a
    ld c, [hl]

    ; Decode opcode
    ld a, b
    and a, $F0

    cp a, $10
    jp z, Opcode1NNN

    ld a, b
    and a, $0F

    ld a, c
    and a, $FF

    jp game_loop
