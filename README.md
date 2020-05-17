![screenshot](https://github.com/lispysnake/serpent-demo-paddle/raw/master/.github/screenshot.png)


### Serpent Paddle Demo

[![License](https://img.shields.io/badge/License-ZLib-blue.svg)](https://opensource.org/licenses/ZLib)

Demonstration of the [Serpent Game Framework](https://github.com/lispysnake/serpent) from [Lispy Snake, Ltd](https://lispysnake.com)

Our goal is to accelerate development of certain aspects of Serpent, through various demos.

### Demo Goals

 - Flesh our physics integration (Chipmunk2D)
 - Add basic audio support (sdl_mixer)
 - Make a basic game with Serpent
 - Test deployment across multiple targets (Windows & Linux)
 - Huge Serpent core improvements

### Dependencies

To get the dependencies on Solus, issue the following command:

    sudo eopkg it -c system.devel sdl2-image-devel sdl2-devel mesalib-devel ldc dub dmd

As with Serpent, you will **currently** need to have `serpent-support` checked out and built locally.
We're going to address this to allow linking to dynamic bgfx, etc, to make this step much easier.

Make sure you have all modules cloned recursively:

    git submodule update --init --recursive

### Building

    ./scripts/build.sh release

## Running

    ./bin/serpent-demo-paddle
