#!/bin/bash
# usage: tools/ui_shot.sh <step> <out.png> [resolution] [frames]
cd "$(dirname "$0")/.."
UI_DEMO_STEP=$1 timeout 90 tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --path . --resolution ${3:-1920x1080} --script res://tools/screenshot.gd -- res://scenes/ui/ui_demo.tscn "$2" ${4:-90} 2>&1 | grep -E "ERROR|error|screenshot|at:" | head -20
