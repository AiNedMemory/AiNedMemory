---
title: Synthesis 
sidebar_position: 3
---

# Building the AiNed Hardware

## Requirements

* The project is tested on Xilinx Vivado version 2018.2 and 2020.2.
* Install the pynq-z2 board support package (BSP).
 [Here](https://github.com/xupsh/pynq-supported-board-file) is a (fixed) version.

## Generating the project

To generate the project, launch Vivado while sourcing the tcl script.

```bash
vivado -source AiNed_project.tcl
```

![Vivado Project](/img/vivado-project.png)

This will setup the project with the following block design.

![design](/img/pynq-system-design.png)

Click the `Generate Bitstream` button to generate the bitstream.
A full synthesis takes around 7 minutes.

After synthesis the bit file can be found in here:
`./pmemory/pmemory.runs/impl_1/design_1_wrapper.bit` and the hwh file:
`./pmemory/pmemory.gen/sources_1/bd/design_1/hw_handoff/design_1.hwh`.

## Loading the hardware on the Pynq-z2 board

For using it with the image provided with the [pynq.io](https://pynq.io) image
see instructions on the [Pynq-z2 Image](/image#upgrading-the-fpga-image) page.

If used with a custom design, make sure the clock (FCLK_CLK0) provided by the Processing
System runs at `100 MHz`.
