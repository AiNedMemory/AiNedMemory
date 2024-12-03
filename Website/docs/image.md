---
title: Pynq-Z2 SD-Card Image
sidebar_position: 2
---

# Pynq-Z2 SD-Card Image

The AiNed Probabilistic-Memory Hardware-Simulator targets a [TUL
Pynq-Z2](https://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html) board. This
board is build around the Xilinx XC7Z020 Zynq FPGA SoC.

![pynq](/img/pynq-z2.png)

The SD-card image provided containing a Linux install based on the image
provided by AMD for this board via the [pynq.io](http://www.pynq.io/boards.html)
website. This is based on [Ubuntu 22.04](https://ubuntu.com/download/desktop).

## Zynq system

The Xilinx Zynq system is  split into two parts, the Processing System (PS)
side is build around 2 ARM A9 core CPU cores running Linux and an FPGA region
that can be freely programmed. The two regions are connected via an
interconnect. This interconnect allows modules in the FPGA region to be made
available in the memory map of the ARM cores. See [here](/#verilog-module) for
the memory map.

![Layout](/img/pynq-system-design.png)

The green area is the PS part, the red area is the FPGA implementation.
Where the purple block is the AiNed Probabilistic-Memory Hardware-Simulator.

The image (bit file) that gets loaded into the FPGA region at startup is
located in the `🗀 /boot/` directory and is loaded on startup from the `📄 /boot/boot.py`
file.

## Username and Password

To login to the board either via the [serial port](#serial) or [SSH](#ssh), the credentials for the board are:

| Key      | Value    |
|----------|----------|
| Username | student  |
| Password | password |

## Login

### Serial

When connecting the Pynq-Z2 to a pc via the usb connector it creates two serial ports.
The 2nd serial port, normally `/dev/ttyUSB1` under linux, is a serial-terminal.
The default baudrate is 115200.
Using a program like [tio](https://github.com/tio/tio) you can login and work with the board.

Under Linux:

```bash
tio /dev/ttyUSB1 -b 115200
```

User macOS:

```bash
tio /dev/tty.usbserial-1234_tul1 -b 115200
```

### SSH

By default the board runs a ssh server on port 22.
When directly plugged into a ps or laptop, the IP address of the board is `10.43.0.1`.

```bash
ssh student@10.43.0.1
```

## Networking

By default the image makes the board act as a
[dhcp](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol)
server. Connecting a wire directly between a PC and this board should give you
access to the board on the ip: `10.43.0.1`.

On startup the board also queries for a dhcp server to get an IP, this way you
can get internet on the board by enabling `share internet` on the PC its
connected too.

:::danger
Do not plug the board directly into an existing network, given that the board runs a dhcp server
this can cause problem.
To disable the builtin dhcp server run: `systemctl disable isc-dhcp-server` and reboot.
:::

## Upgrading the FPGA image

Copy the new `bit` file (the FPGA image) and `hwh` (Hardware description) file
into the `🗀 /boot` folder on the board. (This is the first partition on the SD
card).
Then edit the `/boot/boot.py` file and change the loading to point to the new file:

```python
#! /usr/bin/env python3

from time import sleep
import subprocess
import pynq

base = pynq.Overlay("/boot/ained-v0.2.bit")

```

:::warning
Both the `bit` file and the `hwh` file need to have the same basename.
If the bitfile is `ained-v0.2.bit`, the hwh file should be called `ained-v0.2.hwh`.
:::

## More Instructions

More instructions on how to connect from different operating systems and working with this base image can be found on the
Eindhoven University of Technology [pynq](https://pynq.tue.nl/) website.
