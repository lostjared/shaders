#!/bin/bash

find .  |  cut -c 3- |  grep -Ev 'git|vertex|material' | grep '.glsl' | sort > index.txt

