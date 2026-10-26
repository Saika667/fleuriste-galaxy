#!/bin/bash
# usage: tools/shot.sh <shot name> <frames> ; scene res://scenes/shop/shot_<name>.tscn -> out/world3/<name>.png
cd "$(dirname "$0")/.."
name=$1; frames=${2:-300}; out=${3:-out/world3/$name.png}
mkdir -p out/world3
rm -f "$out"
./tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1920x1080 --script res://tools/screenshot.gd -- res://scenes/shop/shot_$name.tscn "$(pwd -W)/$out" $frames 2>&1 | grep -v "^Godot Engine\|^Vulkan\|^OpenGL\|^$" | head -40
ls -la "$out" 2>&1 | tail -1
