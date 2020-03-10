# Basic Paddle Demo

[![License](https://img.shields.io/badge/License-ZLib-blue.svg)](https://opensource.org/licenses/ZLib)

This project is a simple demonstration of [Serpent](https://github.com/lispysnake/serpent) to build a
paddle-type-game-from-an-older-generation-of-consoles. >_>

The primary mission here is to build the initial Chipmunk2D integration needed for Serpent before pushing
it backupstream into Serpent as and when ready. Initially any problems encountered with super-basic-game
development should be rectified.

### Building

To get the dependencies on Solus, issue the following command:

    sudo eopkg it -c system.devel sdl2-image-devel sdl2-devel mesalib-devel ldc dub dmd

As with Serpent, you will **currently** need to have `serpent-support` checked out and built locally.
We're going to address this to allow linking to dynamic bgfx, etc, to make this step much easier.

Make sure you have all modules cloned recursively:

    git submodule update --init --recursive

## Running

    ./bin/serpent-demo-paddle
