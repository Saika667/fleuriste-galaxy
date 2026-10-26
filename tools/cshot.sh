#!/bin/bash
# usage: tools/cshot.sh <scenario> <at_seconds> <frames> [out]  -> out/cellar3/<scenario>.png
cd "$(dirname "$0")/.."
sc=$1; at=${2:-}; fr=${3:-60}; out=${4:-out/cellar3/$sc.png}
export CELLAR_SCENARIO=$sc
if [ -n "$at" ]; then export CELLAR_AT=$at; fi
tools/shotscene.sh res://scenes/cellar/cellar_demo.tscn "$out" $fr
