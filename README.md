# 7-Segment Counter with Interrupts (ATmega328P)

## Overview

This project implements an interrupt-driven decimal counter using the ATmega328P microcontroller.

Two push buttons allow:
- Incrementing the counter (INT0)
- Decrementing the counter (PCINT0)

The current value (0–9) is displayed on a single 7-segment display.

The system is fully interrupt-driven. The main loop remains idle.

---

## Hardware

Microcontroller: ATmega328P  
Display: Common cathode 7-segment  
Buttons:
- INT0 (PD2) → Increment
- PB0 (PCINT0) → Decrement

Segment Mapping:

(dp, g, f, e, d, c, b, a)  
(PD7, PD6, PD5, PD4, PD3, PB2, PD1, PD0)

---

## Features

- External interrupt (INT0) – Falling edge triggered
- Pin change interrupt (PCINT0)
- Flash-based lookup table using LPM
- Manual stack initialization
- Software debounce
- Modular interrupt initialization routines

---

## How It Works

1. On reset:
   - Stack pointer is initialized
   - Interrupts are configured
   - I/O ports are set
   - Global interrupts are enabled

2. When INT0 triggers:
   - Counter increments
   - Rolls over at 9 → 0

3. When PCINT0 triggers:
   - Counter decrements
   - Rolls under at 0 → 9

4. Display is updated using a lookup table stored in Flash memory.

---
