# ISX - an ISIS-II emulator for CP/M

This repository contains the disassembly of an ISIS-II emulator for CP/M. The emulator was apparently written by Digital Research as it is based on CP/M 2.2 BDOS, although it doesn't contain any copyright notice. The emulator was found on the [Unofficial CP/M](http://www.cpm.z80.de/) web site, ["Digital Research Binary Files"](http://www.cpm.z80.de/binary.html) page, "Languages" section, among the "PLM compilers". Especifically, inside the [plm80x80.zip](http://www.cpm.z80.de/download/plm80x80.zip) file: IS14.COM and ISX.COM (the two files are the same).

The original ISX.COM file _will not run_ under a standard CP/M system, as it requires a tailored BIOS and a slightly modified BDOS. You can find more information [here](https://p112.sourceforge.net/index.php?isx). This repository contains the BIOS souces and binaries necessary to run the emulator on the [P112 CPU](https://en.wikipedia.org/wiki/P112) platform.

