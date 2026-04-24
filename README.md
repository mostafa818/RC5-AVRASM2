# RC5-16/8/12 — AVR ATmega328P Assembly Implementation
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A bare-metal implementation of the **RC5 symmetric block cipher** written entirely in **AVR assembly** for the ATmega328P microcontroller. Built as part of a university curriculum to explore low-level cryptographic primitives on constrained embedded hardware.

---

## Algorithm Parameters

| Parameter | Value |
|---|---|
| Word size | 16 bits |
| Rounds | 8 |
| Key length | 12 bytes |
| Subkey table | 18 words (S[0..17]) |
| Magic constant P | 0xB7E1 |
| Magic constant Q | 0x9E37 |

---

## Features

- Full RC5 key schedule (54-iteration mixing loop)
- Encryption and decryption of 32-bit blocks (two 16-bit words)
- Data-dependent rotations implemented using AVR shift/rotate instructions
- No external libraries — pure AVR assembly
- Fits entirely within the ATmega328P's 32KB flash and 2KB SRAM

---

## Project Structure

```
rc5_avr.asm       # Main source — key schedule, encryption, decryption
README.md         # This file
```

---

## Memory Layout

| Region | Address | Size | Contents |
|---|---|---|---|
| Flash | 0x0000 | 2 bytes | Reset vector (rjmp init) |
| Flash | after code | 12 bytes | Key string (encryption_key) |
| SRAM | key | 12 bytes | L[] — key words |
| SRAM | s | 36 bytes | S[] — 18 subkey words |

---

## Register Conventions

| Register | Alias | Role |
|---|---|---|
| r2:r3 | al:ah | Plaintext/ciphertext word A |
| r4:r5 | bl:bh | Plaintext/ciphertext word B |
| r6 | zro_reg | Constant zero for carry wrap in ROL |
| r20 | lp_cntr_i | Mix loop counter i |
| r21 | lp_cntr_j | Mix loop counter j |
| r22 | n | Round / step counter |
| r30:r31 | Z | Flash pointer (LPM) / S[] pointer |
| r26:r27 | X | L[] (key) pointer |
| r28:r29 | Y | S[] pointer |

---

## How It Works

### 1. Key Loading
The 12-byte ASCII key is stored in flash and copied into SRAM via `lpm` on startup.

### 2. Key Schedule
The subkey table S[] is initialised with arithmetic progressions starting from the Rivest constants P16 and Q16, then mixed with the key over 54 iterations using data-dependent rotations.

### 3. Encryption
Pre-whitening adds S[0] and S[1] to the plaintext words. Eight rounds then apply:
```
A = ROL(A ^ B, B mod 16) + S[2i]
B = ROL(B ^ A, A mod 16) + S[2i+1]
```

### 4. Decryption
Eight rounds in reverse:
```
B = ROR(B - S[2i+1], A mod 16) ^ A
A = ROR(A - S[2i],   B mod 16) ^ B
```
Followed by undoing the pre-whitening.

---

## Test Vector

Key: `cyberPhantom` (ASCII, 12 bytes)

| | Word A | Word B |
|---|---|---|
| Plaintext | 0x0000 | 0x0000 |
| Ciphertext | 0x96AE | 0x7B97 |

---

## Environment

- **MCU:** ATmega328P (Arduino Uno / bare chip)
- **Assembler:** AVRASM2 (Microchip Studio / Atmel Studio)
- **Simulator:** Microchip Studio AVR Simulator

---

## References

- Rivest, R.L. — *The RC5 Encryption Algorithm* (1994)
- AVR Instruction Set Manual — Microchip Technology
