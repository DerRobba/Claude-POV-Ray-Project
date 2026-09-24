# Movement: Sunday Drive through POV-Ray Valley

A red hatchback with rally stripes drives down a country road past a forest. The camera swings around it on the way.

| File | What it is |
|---|---|
| `movement.pov` | the scene (all the comments are in here) |
| `quickres.ini` | resolution presets for POV-Ray for Windows, including the animation presets |
| `movement.ini` | the same 1080p animation settings for the command line |
| `movement.mp4` | the finished 10 s animation (1920x1080, 24 fps) |

## Rendering on Windows

1. Copy the `[Movement ...]` blocks from `quickres.ini` into
   `Documents\POV-Ray\v3.7\ini\quickres.ini`, or replace that file with this one.
   Then restart POV-Ray.
2. Open `movement.pov` and pick a `Movement ...` preset from the resolution dropdown.
3. Click **Run**. POV-Ray saves one PNG per frame next to the .pov file.

On a 12-thread i5 the 1080p version takes about half an hour. Try the preview preset first.

## Turning the frames into a video

POV-Ray only saves single images. To join them with ffmpeg:

```
ffmpeg -framerate 24 -i movement%03d.png -c:v libx264 -pix_fmt yuv420p -crf 18 movement.mp4
```

## Switches at the top of `movement.pov`

- `Soft_Shadows`: soft sun shadows. Turning it off makes rendering about twice as fast.
- `Use_Radiosity`: real bounce light. It's slow and can flicker in animations.
- `Focal_Blur`: depth of field. Very slow.
- `Tree_Count`: how many trees get planted.
- `Cam_Select`: 1 = roadside camera, 2 = drone view, 3 = chase cam.

You can also set any of these from the ini or the command line, e.g. `Declare=Cam_Select=1`.
