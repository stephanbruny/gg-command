#!/usr/bin/env sh
valac --pkg posix --pkg gtk+-3.0 --pkg cairo src/main.vala --pkg librsvg-2.0 -o bin/gg-command
