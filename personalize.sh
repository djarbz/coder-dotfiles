#!/usr/bin/env bash

# If running bash
if [ -n "$BASH_VERSION" ]; then
    # If there is a local rc folder, run them.
    if [ -d ~/.bashrc.local ]; then
        for rc in ~/.bashrc.local/*; do
            if [ -f "$rc" ]; then
            . "$rc"
            fi
        done
    fi

    unset rc
fi
