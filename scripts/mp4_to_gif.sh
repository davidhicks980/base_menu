#!/bin/bash

for f in assets/videos/*.mp4; do
  ffmpeg -y -i "$f" -vf "fps=30,split[s0][s1];[s0]palettegen=stats_mode=full[p];[s1][p]paletteuse=dither=sierra2_4a" -loop 0 "${f%.mp4}.gif"
done