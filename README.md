# POV-Ray Animationen

## 1. Abgabe: `movement.pov` („Feierabend“)

A figure built with `merge` jogs along a path between trees for exactly 4 seconds, and at the end walks into a house with a roof. The sun in the sky makes shadows.

| Datei | Inhalt |
|---|---|
| `movement.pov` | the scene, with German comments |
| `movement.ini` | render settings: 1080p, 100 frames, played at 25 fps = exactly 4.0 s |
| `movement.mp4` | the finished video |
| `Programmiertagebuch.md` / `.docx` | the programming diary (to hand in) |
| `tagebuch_bilder/` | screenshots for the diary |
| `movement_original.pov` | the teacher's template |

## 2. Bonus: `car_drive.pov` („Sunday Drive through POV-Ray Valley“)

A red hatchback drives down a country road through the forest while the chase camera swings around it. 240 frames at 24 fps = 10 s.
Files: `car_drive.pov`, `car_drive.ini`, `car_drive.mp4`.

## Rendering on Windows

1. Copy the `[Movement ...]` and `[Car Drive ...]` blocks from `quickres.ini` into `Documents\POV-Ray\v3.7\ini\quickres.ini`, or replace that file with this one. Restart POV-Ray.
2. Open the .pov file and choose the matching preset from the resolution dropdown.
3. Click **Run**. POV-Ray saves one PNG per frame.

## Frames to video (ffmpeg)

```
ffmpeg -framerate 25 -i movement%03d.png -c:v libx264 -pix_fmt yuv420p -crf 18 movement.mp4
ffmpeg -framerate 24 -i car_drive%03d.png -c:v libx264 -pix_fmt yuv420p -crf 18 car_drive.mp4
```

**Important for the task:** use `-framerate 25` for `movement`. 100 frames at 25 fps is exactly 4 seconds.
