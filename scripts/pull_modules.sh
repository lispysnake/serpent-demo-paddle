#!/bin/bash

echo "Pulling latest submodules..."

git submodule update --recursive --remote --merge
