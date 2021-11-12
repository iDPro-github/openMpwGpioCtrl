# Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

Overview
========

This repo contains a sample user project that utilizes the
`caravel <https://github.com/efabless/caravel.git>` chip user space.
The user project contains a simple GPIO-Control module to read and write
the first 32 bit from the caraval GPIO module in the user space. Furthermore
it implements a FSM to automatically read and write 1024 bits of bit
stream from and to any of the first 32 GPIO ports.

System
======

The user space contains 3 blocks:
  1. wishboneSlave: Connection to caravel's RISC-V CPU
  2. gpioModule: Simple GPIO control block connected to caravel's GPIO ports
  3. ramInterface: Internal Memory for bus access and GPIO streaming

Adress Mapping
==============

  * caraval user block      : 0x30000000 to 0x7FFFFFFF  
    * GPIO user block       : 0x30000000 to 0x3000000F  
      * Control Register    : 0x30000000 to 0x30000003  
      * GPIO-Input          : 0x30000004 to 0x30000007  
      * GPIO-Output         : 0x30000008 to 0x3000000B  
      * GPIO-OutEnable      : 0x3000000C to 0x3000000F  
    * RAM user block        : 0x30000080 to 0x300000FF  

wishboneSlave
=============

The wishbone slave introduces a 32-bit data interface to the user block connected to the caravel's system bus. It is the communication interface to the main RISC-V cpu.

gpioModule
==========

The gpio module offers direct access to the caravel's GPIO lines 0 to 31. The registers "GPIO-Input", "GPIO-Output" and "GPIO-OutEnable" as listes in the chapter "Address Mapping" can be used for simple GPIO bit controlling to the corressponding GPIO port.

The Control Register is composed of the follwoing control signals:

|Bits  |Parameter     |Description
|------|--------------|-----------------------------------------------------------------
|0     |aSHIFT_IN_EN  |Enable the GPIO input stream automatic
|5:1   |aINPUT_SEL    |Select the GPIO input port for automatic streaming (0..31)
|6     |aSHIFT_OUT_EN |Enable the GPIO output stream automatic
|11:7  |aOUTPUT_SEL   |Select the GPIO output port for automatic streaming (0..31)
|12    |aOUTPUT_LOOP  |Enable the GPIO output stream to be repeated until aOUTPUT_LOOP=0
|22:13 |aOUTPUT_LEN   |Configure the GPIO output stream bitlength (0..1023)
|23    |aOUTPUT_LIMIT |Enable the GPIO output stream bitlength limit to aOUTPUT_LEN

For GPIO input stream, the corresponding configuration needs to be written to the Control Register and the data can be read from RAM when it is finished. The parameter "aSHIFT_IN_EN" is reset automatically.

For GPIO output stream, the data needs to be written to the RAM before the corresponding configuration is written to the Control Register.

ramInterface
============

The RAM-IF is connected to the wishbone bus and the gpio control block. The gpio control block uses the RAM-IF to read and write GPIO stream data in dependens of the current configuration. The direct access via the wishbone slave is only allowed, when the gpio control
has finished automatic data processing. 

The RAM-IF is prepared to be used with OpenRAM.