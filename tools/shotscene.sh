#!/bin/bash
# usage: tools/shotscene.sh res://scene.tscn out.png frames
cd "$(dirname "$0")/.."
mkdir -p "$(dirname "$2")"; rm -f "$2"
./tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1920x1080 --script res://tools/screenshot.gd -- "$1" "$(pwd -W)/$2" ${3:-60} 2>&1 | grep -v "^Godot Engine\|^Vulkan\|^OpenGL\|^$" | head -30
