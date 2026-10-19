# Tool guide

## Godot (CLI first)

The CLI is the source of truth for tests and exports. On this machine set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`; it reports Godot `4.7.2.stable.official.ed1daf0bf`.

| Job | Command |
| --- | --- |
| Import after changing assets | `$GODOT_BIN --headless --path . --import` |
| Parse-check script | `$GODOT_BIN --headless --path . --check-only --script <file>` |
| Logic test | `$GODOT_BIN --headless --path . --script res://tests/<test>.gd` |
| Render/playtest | Run a project/harness in a signed-in desktop session; macOS has a native Metal renderer. |
| Windows/macOS exports | Use matching export templates and configured presets once the project exists. |
| Lint/format | `gdlint` and `gdformat` from `gdtoolkit`, if installed. |

Fail on Godot output containing `SCRIPT ERROR` or `^ERROR`; leaked-resource messages at quit are not sufficient evidence of failure by themselves. One playtest harness per feature should write screenshots and measured state JSON; inspect both the images and state. Check the active graphics device before heavy rendering or baking. This Mac is Apple M4 Max with 40-core GPU and Metal 4. Linux `Xvfb`, Vulkan, and WSL instructions do not apply to this test machine. Do not bake unless the reference evidence calls for it.

If converted glTF models use vertex colors, load-check the first surface as well as later surfaces; the stock importer can lose the first surface's vertex-color flag. Keep web-export files under 90 MB when using GitHub Pages. Show the first room before making the whole scene. The Godot MCP is connected (`mcp__godot__*`), but CLI checks remain authoritative; available MCP functions include scene creation/editing, project info, run/stop, debug output, sprite load, and mesh-library export.

## REA

REA is connected (`mcp__rea__*`). It wraps Ghidra and provides binary inspection, decompilation, xrefs/call graphs, annotations, unknown tracking, reconstruction coverage, and browser/web capture and comparison tools. Read a tool definition before first use. For native binaries: open, overview, search strings/procedures, decompile narrowly, trace callers/callees/xrefs, annotate, record unknowns, then verify resolutions. Never call `binary_session` without a narrow question; it can return hundreds of thousands of characters. Console binary support remains untested. The reference game binary is not available, so REA is not currently needed.

## Reference footage and browser

The portal page and official trailer were inspected in the signed-in Chrome session. No browser-devtools MCP appeared among connected tools; CUA browser control is available. `yt-dlp` and `ffmpeg` were not found on PATH. Reference captures, if made later, go in ignored local `study/` and include source URL and timestamp. Frames check a result; they do not set numeric targets. Compare same-sized captures; let visual inspection lead and use pixel differences as support.

## Flora MCP (read-only discovery only under $0 budget)

Connected names: `mcp__codex_apps__flora_flora_*` and `mcp__flora__flora_*`. Relevant functions include workspace/project/model/usage listing, generation listing/creation, canvas, and model viewing. No paid generation is permitted under the current owner cap. The Flora workspace observed was `RISD EDU Workspace` (`ws_qd79c614xtmypkpczymr6rp92n8fjazp`); project `Ghost in the Machine` (`prj_ns70p1pmta4cevyzan3bbe3sa98gjzdx`) was public in that workspace. Usage reported caller availability $1.084 and a $20 member lifetime limit; spend data was unavailable due to missing permission. This is not project budget and does not change the owner's $0 cap.

The 3D model query returned 22 options (estimated USD per run): Hunyuan3D v3.1 Rapid (text $0.27; image $0.27); Meshy 6 (text $0.96; image $0.96; multi-view $1.44); Rodin v2.5 (text $0.48; image $0.48; multi-view $0.48); Tripo H3.1 (text $0.24; image $0.36; multi-view $0.36); Hi3D v3.0 (image and multi-view $2.52); Meshy 7 (image and multi-view $1.44); SAM 3D image $0.024; Trellis image $0.024; Trellis 2 image $0.36; Trellis Multi image $0.021; Meshy 5 Remesh $0.24; Meshy 5 Retexture $0.36; Trellis 2 Retexture $0.252. These are catalog estimates only, not authorized prices or usable spend. No paid model should be called. Historical notes mention `i3d-tripo-h3-1-i3d` and `i3d-tripo-h3-1-multiview-i3d`; the current catalog IDs are shown in the names above.

## Research and GitHub

Prefer primary sources: source code at a pinned commit, official documentation, and original data. Save topic research in `docs/research/<topic>.md` with `Verified`, `Inferred`, and `Not determined` sections. The local machine has GitHub CLI `gh` authenticated as `Avocaadorable` with repo scope; the GitHub MCP is connected as `mcp__codex_apps__github__*`.

## Machine and tool availability

- OS: macOS 26.5.2, Darwin arm64; Apple M4 Max, 16 CPU cores, 48 GB memory, 40-core GPU, Metal 4.
- Godot CLI: `/Applications/Godot.app/Contents/MacOS/Godot`, version 4.7.2 stable.
- Orca CLI: `/Applications/Orca.app/Contents/Resources/bin/orca`, version 1.4.216. No agent account was configured. Owner Q10 forbids background schedules, so Orca automation must stay unused.
- Godot MCP, REA MCP, Flora MCP, GitHub MCP, and CUA browser are connected. No Chrome DevTools MCP was found.
- `gdlint`, `gdformat`, `Xvfb`, `vulkaninfo`, `yt-dlp`, `ffmpeg`, and `blender` were not found on PATH during setup.
- No Steam or Dolphin application, or supplied installed reference copy, was found in the observed Applications/Downloads search.
