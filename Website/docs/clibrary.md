---
title: C library
sidebar_position: 1
---

# C library

The C library for interfacing with the Probabilistic-Memory Hardware-Simulator
provides both high-level as low-level access to the simulator implementation on
the FPGA. The current library is written to target the Xilinx Zynq
system-on-chip that consists of 32bit ARM cores and an FPGA region.

The API documentation is generated by doxygen and can be found [here](pathname:///doxygen/).

## File structure

The library consist of a set of C files and header files:

| File | Description |
| -----|-------------|
| [ained.h](pathname:///doxygen/ained_8h_source.html) | Header file for AiNed library |
| [ained.c](pathname:///doxygen/ained_8c_source.html) | Implementation of the AiNed library |
| [arm_shared_memory.h](pathname:///doxygen/arm__shared__memory__system_8h_source.html) | Header file for low-level memory access helper |
| [arm_shared_memory.c](pathname:///doxygen/arm__shared__memory__system_8c_source.html) | Implementation of low-level memory access helper |

To use this library, all these 4 files need to be included into build system of
the project. The application source needs to only include the toplevel header
file [ained.h](pathname:///doxygen/ained_8h_source.html) header.

## Application permission

To run this library, your program requires 'raw' access to the system memory.
This can be achieved in different ways:

* Run as root. (not recommended)
* Give user permission to `/dev/mem`. (not sufficient, needs special capability)
* Set special capability to the executable so it has access.

 The last option can be achieved by executing the following command on the
 binary after compilation.

```bash
setcap cap_sys_rawio+ep <executable>
```

If the library fails to open the memory, it will print:

```
FAILED open memory: Operation not permitted, please run with sufficient permissions (sudo).
```

## Demo Application

A small commandline application is provided as an example.
This application can be found [here](pathname:///doxygen/main_8c_source.html).

### Dependencies

* C compiler (c99 compatible)
* libreadline
* doxygen (optional)
* doxygen-awesome-css (optional, included as submodule)

### Building

To build the application:

```bash
cd src
make
```

### Running example application

Before running the application make sure that the right bitfile is loaded into
the FPGA and the green LED 'done' is active on the FPGA board.

![Pynq Done LED](/img/pynq-done-led.png)

On initial bootup, this can take up to a minute.

:::danger
If the application is started without anything programmed in the FPGA region,
the system will hang and requires a hard reset to recover.
:::

```bash
cd src
./main
```

This will give you an interactive console. You can type `help` to get a list of
available commands.

```
./main 
Found: 32 dipoles.
Command: help
Got command: 'help'
Commands:
 * quit
 * print
 * info
 * commit
 * set
 * clear
 * store
 * restore
 * test
 * help

Command:
```

You can complete commands by hitting `<tab>`, you can browse through previous
entered commands by pressing `arrow up` and `arrow down`.

#### Running example application - experiment

Start the application, and print the current state:

```
Found: 32 dipoles.
Command: print
Got command: 'print'
Print memory
     | 63 62 61 60 59 58 57 56  55 54 53 52 51 50 49 48  47 46 45 44 43 42 41 40  39 38 37 36 35 34 33 32  31 30 29 28 27 26 25 24  23 22 21 20 19 18 17 16  15 14 13 12 11 10 09 08  07 06 05 04 03 02 01 00  

    0|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
   64|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  128|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  192|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  256|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  320|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  384|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  448|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  

  512|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  576|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  640|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  704|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  768|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  832|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  896|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  960|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  

 1024|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1088|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1152|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1216|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1280|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1344|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1408|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 1472|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  

....

 7680|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 7744|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 7808|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 7872|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 7936|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 8000|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 8064|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
 8128|  0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  

Command: 

```

If the memory are not all zeros, you can clear it with the `clear` command.

```
Command: clear
Got command: 'clear'
Clear memory to 0
Command: 
```

:::info
The `clear` command just clears the memory region, it does not reset the random generators.
If you want to restore the random generators, use the `restore` command to load a known state.
:::

Now we are going to force bits in the first part of the memory:

```
Command: set 0 0 1
Got command: 'set 0 0 1'
Command: set 5 5 1
Got command: 'set 5 5 1'
Command: set 7 7 0
Got command: 'set 7 7 0'
Command:
```

These changes are not yet written back, to write them back use the `commit` command.

```
Got command: 'commit'
Commit memory
Command: print
Print memory
     | ...  15 14 13 12 11 10 09 08  07 06 05 04 03 02 01 00  

    0| ...   0  0  0  0  0  0  0  0   0  0  0  1  1  0  0  1  
   64| ...   0  0  0  0  0  0  1  0   1  0  0  1  0  0  1  1  
  128| ...   0  0  0  0  0  0  0  0   0  1  0  0  1  0  0  0  
  192| ...   0  0  0  0  0  0  0  0   1  0  1  1  0  1  0  1  
  256| ...   0  0  0  0  0  0  0  0   1  0  0  1  0  1  0  0  
  320| ...   0  0  0  0  0  0  0  1   0  0  1  1  1  0  0  0  
  384| ...   0  0  0  0  0  0  0  1   0  0  1  0  0  0  0  0  
  448| ...   0  0  0  0  0  0  0  0   0  0  1  0  0  0  1  0  

  512| ...   0  0  0  0  0  0  0  0   0  0  0  1  0  0  0  0  
  576| ...   0  0  0  0  0  0  0  0   0  0  0  0  1  1  0  0  
  640| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  704| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  768| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  832| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  896| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  
  960| ...   0  0  0  0  0  0  0  0   0  0  0  0  0  0  0  0  

```

:::warning

If the `set` command tries to force bits in more then one 64bit memory word,
This will generate the following error, and the bit will not be set.

`Cannot set bit in more then one word in a single commit.`

:::

:::info
The new state depends on the random generators, the above results might be different.
:::

### Building documentation

The API documentation can be re-generated using doxygen.

```bash
cd doxy
make
```

The documentation is build in the `documentation/html` directory.

### Running tests

To run the tests:

```bash
cd tests
make
```

### Known shortcomings

* The library currently targets 32bit systems. If ported to a 64bit system some
minor changes need to be made to the MMIO library.