# baremetalgames
baremetalgames is a Digital Design project to combine a MIPS-like microprocessor with a VGA core to run simple GUI applications, 
namely video games.

The microprocessor is a 32-bit MIPS-like architecture that can run a subset of the MIPS instruction set.
The VGA core is a simple VGA controller with a double frame buffer that is able to display 12-bit RGB (a total of 4096 colors) at a resolution of 640x480 @ 60Hz.
[12-bit color and other RGB palettes](https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_palettes#12-bit_RGB)
