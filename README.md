# Petal by Petal

First playable slice: play as the brown-haired florist behind the counter, talk with Mina (the separate pink-dressed customer) through three short dialogue beats, then build a relaxed, one-flower cosmos arrangement in her vase. Mina’s request, favorite colors, budget, and arrangement controls remain visible throughout.

## Run on macOS

Open this folder as a project in Godot 4.7.2, then press **Run Project**. Or launch it from Terminal:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

The current prototype runs at 1920 × 1080. Choose one of the three dialogue responses, then drag the cosmos from the right-side basket onto the vase opening. Click a bloom to select it; drag to move it, use the sliders and rotation buttons to adjust it, and use **Remove** or **Undo** as needed. Deliver when ready; there is no timer.

## Verify

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./scripts/check.sh
```

The checked-in shop scene, character illustration, and logo are crops from the owner's supplied design bible. No paid generation or external image source is used. The reference game's footage is not included.
