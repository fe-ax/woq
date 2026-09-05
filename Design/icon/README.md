# WOQ app icon

Three candidate app icons for Workout Queue, drawn as flat SVG on a 1024x1024
viewBox in the palette from `PLAN.md` section 7 (paper `#F7F3E8`, card `#FFFDF8`,
ink `#111111`, pastel red `#F4A6A6`, yellow `#F6E3A1`, blue `#A8C8F0`).

| file | idea |
|---|---|
| `icon-a.svg` | **Node on lane.** Yellow develop lane, big black-outlined white commit node, blue branch curving off to a smaller blue node. The queue / in-progress metaphor. |
| `icon-b.svg` | **Punched plus node.** The app's add button: solid ink circle with the plus punched out so the paper shows through, sitting on a thin yellow lane. |
| `icon-c.svg` | **Figure.** The front muscle figure from `Design/figure/front.svg`, reduced to the body silhouette plus the two chest regions in primary-muscle red, over a thin yellow lane. |

Constraints the sources honour: full-bleed opaque paper background (iOS applies
its own corner mask), flat shapes only, no text, no gradients, no transparency,
all content inside the inner 80% of the canvas.

## Regenerate

```sh
./Design/icon/render.sh
```

Uses only tools that ship with macOS: `qlmanage -t -s 1024 -o <dir> file.svg`
for SVG -> PNG, `sips` for the downscales, `python3` for the sheet and the
alpha strip. For every `icon-*.svg` it writes into `Design/icon/renders/`:

* `<name>-1024.png` — the master
* `<name>-180.png` — iPhone home screen @3x
* `<name>-120.png` — Spotlight @3x
* `<name>-60.png` — the size the icon is actually judged at, in points
* `preview-sheet.svg` / `preview-sheet.png` — A, B and C side by side at all
  three sizes with the corners rounded to approximate the iOS mask

Every PNG is rewritten as 8-bit RGB with no alpha channel, because `qlmanage`
always emits RGBA and Xcode rejects an App Store icon that carries alpha.

Note: `qlmanage` always writes a *square* thumbnail, which is why the preview
sheet is authored square rather than as a wide strip.

## Install the chosen icon

1. Copy the master next to the asset catalog entry:

   ```sh
   cp Design/icon/renders/icon-b-1024.png \
      WOQ/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
   ```

   (swap `icon-b` for whichever variant wins)

2. Add the image entry to
   `WOQ/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` — the
   `images` array is currently empty, so it becomes:

   ```json
   {
     "images" : [
       {
         "filename" : "AppIcon-1024.png",
         "idiom" : "universal",
         "platform" : "ios",
         "size" : "1024x1024"
       }
     ],
     "info" : {
       "author" : "xcode",
       "version" : 1
     }
   }
   ```

   A single 1024 universal entry is all iOS 26 needs; the system derives every
   other size. Nothing in `project.yml` changes — `ASSETCATALOG_COMPILER_APPICON_NAME`
   already points at `AppIcon`.

3. Rebuild and reinstall. The simulator caches icons hard, so if the old
   placeholder sticks, delete the app from the simulator first.

## Editing

The SVGs are hand-written and readable; edit them directly and re-run
`render.sh`. Keep line weights in the ranges already used — node and silhouette
strokes 18–28 px at 1024 (1.8–2.7%), lane edges 3–5 px — anything thinner
disappears at 60 px, anything much thicker turns the figure into a blob.
