---
slug: /
title: Probabilistic-Memory Hardware-Simulator
sidebar_label: 'Hardware User Guide'
sidebar_position: 0
---

# Probabilistic-Memory Hardware-Simulator

Simulates a memory that has the property that when a bit is written to there is a probability that it triggers neighbouring bits to "flip" to the same value.

The simulator operates in much the same way as a regular memory. The memory is 8-Kb in capacity, with 64-bit wide words. A 64-bit write mask is used to specify which individual bits of the word should be written. The simulator simulates a memory layout in which the 64-bit words are arranged in 2-dimensional 8x8 squares, as illustrated below:

![Memory Map Layout](@site/static/img/mm_layout.svg "Memory Map Layout")

Only the 64-bits within a word can be written to simultaneously. However, bits in neighbouring words may change as a result of the bits that are written.

## Simple Write Example

In this example a 2-dimensional 11x11 memory location is illustrated. This memory area is mainly zeroes with some ones. The centre value of this area is zero and the illustration below shows a possible outcome from driving the centre bit (and only the centre bit) to one. The simulator allows for multiple simultaneous writes taking into account cumulative probability, but in this example only one write takes place.

![Simple Write Example](@site/static/img/single_write.svg "Simple Write Example")

The simulator simulates side-effects around a driven bit using a 9x9 grid, therefore the bits on the periphery of the illustrated memory area are out of range to possibly change, and are coloured red. The values within range that are already one, and will not change, are also coloured red. The rest of the 9x9 grid might change (coloured yellow) depending on the [probability coefficients](#probability-coefficients) (not illustrated). Ones that are coloured blue are bits within range that flipped from zero to one based on the derived probability and using a [Pseudo Random Number Generator (PRNG)](#pseudo-random-number-generators) to decide the outcome.

## Verilog Module

![AiNed Memory](@site/static/img/AiNed_memory.svg "AiNed Memory")

The memory simulator is implemented as a verilog module that has two AXI4lite ports. The memory (or "mem") port is used for read and write memory operations and the control (or "ctrl") port is used to read and write the control registers.

| Port | Base Address |
|------|--------------|
| ctrl | 0x43C00000   |
| mem  | 0x43C10000   |

### Control Registers

The control registers consist of the following:

| Address        | No. 32-bit Registers | Description                                   |
|---------------:|:--------------------:|-----------------------------------------------|
| 0x43C00000     | 2                    | 64-bit write mask                             |
| 0x43C00008     | 6                    | 24 8-bit probability coefficients high        |
| 0x43C00020     | 6                    | 24 8-bit probability coefficients low         |
| 0x43C00038     | 1                    | Write bypass (0 or 1)                         |
| 0x43C01000     | 128                  | Pseudo Random Number Generators (PRNGs) state |

### Write mask

The write mask indicates which of the 64 bits to write when a word is written to memory. The mask consists of 64-bits with a 1 indicating that a bit in that location in a word should be written and a 0 indicating that it should not be written. The write mask is retained until it is updated meaning that multiple writes can be performed with the same mask without needing to write to the control register each time.

### Probability coefficients

Whenever a bit is written there is a probability that bits in its vicinity 'flip'. This simulator simulates this process for a 9x9 square around the bit being set, as illustrated below:

![Coefficient Ordering](@site/static/img/coeffs.svg "Coefficient Ordering")

The probability for each location is a value from 0-256 representing a probability from 0-1. A probability of 0.5 would therefore be represented as a value of 128. Each probability is stored as an 8-bit value meaning that only probability values from 0-255 can be used as coefficients.

This implementation of the simulator assumes horizontal and vertical symmetry enabling the probabilities to be captured in 24 values, as illustrated by the numbering of the bits from 0-23 in the diagram above. Separate 24 value coefficient tables are used for when bits are driven high (1) or low (0). The addresses for the high and low coefficients, along with the coefficient ordering within the register word, is described in the table below:

| Address high | Address low | +3 | +2 | +1 | +0 |
|-------------:|------------:|:--:|:--:|:--:|:--:|
| 0x43C00008   | 0x43C00020  | 3  | 2  | 1  | 0  |
| 0x43C0000C   | 0x43C00024  | 7  | 6  | 5  | 4  |
| 0x43C00010   | 0x43C00028  | 11 | 10 | 9  | 8  |
| 0x43C00014   | 0x43C0002C  | 15 | 14 | 13 | 12 |
| 0x43C00018   | 0x43C00030  | 19 | 18 | 17 | 16 |
| 0x43C0001C   | 0x43C00034  | 23 | 22 | 21 | 20 |

### Pseudo Random Number Generators

This simulator implementation uses 32 Pseudo Random Number Generators (PRNGs) to simulate probabilistic behaviour. The internal state of the PRNGs are exposed as registers that can be read and written. The 32 PRNGs have the following base addresses:

| Address        | PRNG ID |
|---------------:|---------|
| 0x43C01000     | 0       |
| 0x43C01010     | 1       |
| 0x43C01020     | 2       |
| 0x43C01030     | 3       |
| 0x43C01040     | 4       |
| 0x43C01050     | 5       |
| 0x43C01060     | 6       |
| 0x43C01070     | 7       |
| 0x43C01080     | 8       |
| 0x43C01090     | 9       |
| 0x43C010A0     | 10      |
| 0x43C010B0     | 11      |
| 0x43C010C0     | 12      |
| 0x43C010D0     | 13      |
| 0x43C010E0     | 14      |
| 0x43C010F0     | 15      |
| 0x43C01100     | 16      |
| 0x43C01110     | 17      |
| 0x43C01120     | 18      |
| 0x43C01130     | 19      |
| 0x43C01140     | 20      |
| 0x43C01150     | 21      |
| 0x43C01160     | 22      |
| 0x43C01170     | 23      |
| 0x43C01180     | 24      |
| 0x43C01190     | 25      |
| 0x43C011A0     | 26      |
| 0x43C011B0     | 27      |
| 0x43C011C0     | 28      |
| 0x43C011D0     | 29      |
| 0x43C011E0     | 30      |
| 0x43C011F0     | 31      |

Each PRNG exposes 4 32-bit registers with the following offsets from their base address:

| Address Offset | Usage | Description           |
|---------------:|:-----:|-----------------------|
| 0x0            | R     | PRNG generated number |
| 0x4            | RW    | State 1               |
| 0x8            | RW    | State 2               |
| 0xC            | RW    | State 3               |

The PRNG generated number is the output from the PRNG based on its state. This register is read only as it is derived from the other values. Writing to this address is permitted but will be ignored.

The 3 32-bit internal state registers contain the values that are used to derive the pseudo random number. These registers can be written to seed the PRNG, to enable reproducible outcomes. The values will automatically update as the PRNG is used.