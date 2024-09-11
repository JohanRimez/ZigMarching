ZigMarching - Marching Square implementation with 3D Perlin noise
Johan Rimez - 2024

This is an open source project featuring:
* ZIG programming language (www.ziglang.org)
* SDL2 - Simple DirectMedia Layer (www.libsdl.org)

This program is intended to demonstrate graphics programming for a simple but fully working coding example using ZIG & SDL.
Moreover, this project is intended to be as flexible as possible towards:
* Coding and compiling in and for WindowsOS & VS Code
* Coding and compiling in and for Linux & VS Codium
* Coding and compiling in Windows for Linux as target

3D NOISE:

taken from: https://rosettacode.org/wiki/Perlin_noise#Zig
Adapted for Zig versio 0.13.0

USAGE:

<any key> quits the application

CODING:

In order for VS Code/Codium to run smoothly with the Zig Language Server (ZLS) in both Windows and Linux, the C-library and the SDL-library header files
are first exported to a common import file "SDLimport.zig" (important: UTF-8) as a preparatory step (you may want to locate the header files first and 
adapt the below commands first). I consider this file to be put in the source directory.

target specific:
(Windows) zig translate-c cImportWin.h -lc > SDLimport.zig
(Linux)   zig translate-c cImportLinux.h -lc -target x86_64-linux-gnu -I/usr/include -I/usr/include/x86_64-linux-gnu > SDLimport.zig

COMPILING:

The build.zig build file is configured for these scenarios:
* Building in windows for windows
* Building in windows for linux (.a & .so libraries need to be provided in the root project directory)
* Building in linux for linux

VS CODE:

the json-build and launch tasks are configured for windows.

RUNNING:

Windows users need to put the path to the SDL2.dll SDL2_image.dll libraries into their PATH or have them in the same folder as the executable.

REMARK:

I used the "Software Renderer" to interact with the Surfaces to easily implement the XOR - blending. I know it's a strech on CPU usage,
but I simply can't find any decent equivalent with the hardware accelerated renderer (acting on Textures). If anybody has a found a better alternative,
please notify!

Kind regards
Johan*

