#!/bin/bash
set -e
set -x

rm -rf .dub
rm -rf bin
rm -rf *.tar.xz

./scripts/build.sh release
mkdir paddle-game
install -m 00755 bin/serpent-demo-paddle paddle-game/.

install -D -d -m 00755 paddle-game/assets
install -D -d -m 00755 paddle-game/assets/audio
install -m 00644 assets/*.png paddle-game/assets/.
install -m 00644 assets/audio/*.ogg paddle-game/assets/audio/.

# Compliance
install -m 00644 LICENSE paddle-game/.

tar cvf serpent-demo-paddle.tar paddle-game
xz -9 serpent-demo-paddle.tar
rm -rf paddle-game
