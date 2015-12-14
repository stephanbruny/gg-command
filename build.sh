#!/usr/bin/env sh
valac --pkg posix --pkg gtk+-3.0 --pkg cairo src/main.vala --pkg librsvg-2.0 --pkg json-glib-1.0 -o bin/gg-command
cp -r ApplicationData ./bin
