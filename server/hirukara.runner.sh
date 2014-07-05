#!/usr/bin/env bash
exec carton exec -- \
    plackup \
        -Ilib \
        -s Starlet \
        -E production \
        --host 127.0.0.1 \
        --port 2525
