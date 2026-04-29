# GLSL Shader Collection

A collection of **1100+ OpenGL GLSL fragment shaders** for real-time video and image processing. These shaders are designed to be used as post-processing effects applied to live camera feeds, video textures, or generated visuals.

## Overview

All shaders are written in **GLSL (OpenGL Shading Language)** and operate as fragment shaders. They take texture input (typically a webcam or video source) and apply various visual transformations in real time. Many shaders support interactive control via mouse input and react to time-based animation.

## Directory Structure

Shaders are organized alphabetically into folders by the first character of their filename:

| Folder | Contents |
|--------|----------|
| `0-9/` | Shaders starting with a digit |
| `A/`–`Z/` | Shaders starting with the corresponding letter (case-insensitive) |
| `material/` | Material-based texture blending and compositing shaders |

## Effect Categories

### Color Manipulation
- **Color shifting & grading** — `color_shift_fade`, `color_grad_rainbow`, `color_increase`, `chue`, `hue-mouse`, `sepia`, `grayscale`, `negative`
- **RGB channel effects** — `rgb`, `rgb_blur`, `rgb_fade`, `rgb_control`, `rgb_time`, `rgbchecker`
- **Strobe & flash** — `strobe`, `strobe_colors`, `strobe_light`, `flash`, `flash_gradient_strobe`, `blue_strobe`, `red_strobe`, `purple_strobe`
- **Rainbow effects** — `rainbow_blur`, `rainbow_bright`, `rainbow_spiral`, `rainbow_fractal`, `rainbow_ink`, `rainbow_prisim`, `bright_rainbow`

### Geometric Distortion
- **Mirror effects** — `mirror1`–`mirror3`, `mirror-twist`, `mirror-wrap`, `mirror-spiral`, `mirror-zoom`, `mirror-bowl`, `funny_mirror`
- **Fisheye & lens** — `fisheye`, `fisheye_mouse`, `fisheye_warp`, `bubble`, `bubble-zoom-mouse`, `thick_glass`, `prism_glass`
- **Warp & twist** — `twist`, `twist_full`, `warp_tunnel`, `warpcursor`, `bend`, `bend_twist`, `elastic`
- **Zoom effects** — `zoom_fish`, `zoom_in_out_mouse`, `zoom_pulse`, `cd_zoom`, `brot-zoom-mouse`
- **Spiral & swirl** — `spiral_wave`, `spiral_mirror`, `swirl_by_mouse`, `color_swirl_beautiful`, `gptswirl`, `g_swirl`
- **Page turn & fold** — `page_turn`, `fold`, `fold-mirror`, `fold-spin`, `tex_fold`

### Fractal & Mathematical
- **Fractal patterns** — `fractal`, `frac_shader01`–`frac_shader05`, `frac_zoom1`–`frac_zoom8`, `new_fractal`, `fractal_diamond_rainbow`
- **Mandelbrot / Julia** — `mandella1`, `julia`, `brot-zoom-mouse`, `frac_shader02_dmd_mandella`
- **Geometric patterns** — `geometric`–`geometric5`, `grid_pattern`, `grid_spiral`, `diamond`, `prism_quad`
- **Kaleidoscope** — `kale`, `kale2`–`kale4`, `kscopic`, `gkale`, `gkalei`

### Video Echo & Feedback
- **Echo effects** — `echo_color`, `echo_mirror`, `echo_mix`, `echo_rainbow_spin`, `echo_xor`, `echo_shift`, `echo_sin`
- **Feedback loops** — `echo_loop`, `echo_loop2`, `gpt_echo`
- **Trail effects** — `gtrail`, `gtrail2`, `HyperFocusTrails`

### Glitch & Digital
- **Glitch effects** — `glitch1`, `glitch_boil`, `glitch_effect`, `glitch_wave`, `glitch-react`, `new_glitch`, `atan-glitch`
- **VHS & retro** — `vhs`, `vhs2`, `vhs_damage`, `vhs-palette`, `old-film`, `snes`, `8bit`, `analog`
- **Pixel & block** — `pixels`, `block_pixels`, `smooth_pixel`, `random_pixels_static`
- **XOR operations** — `xor_rgb`, `xor_sine_swirl`, `xorstrobe`, `xorsheet`, `subtle_xor`, `alpha_xor`

### Lighting & Atmosphere
- **Glow & bloom** — `glow`, `bloom`, `bright`, `brighten`, `whitelight`, `light_pulse`
- **Aura effects** — `aura`–`aura9`, `auraXi1`–`auraXi3`, `green_aura`, `gem-aura`
- **Neon** — `neon`, `neon_mouse`, `frac_shader01_smooth_neon`
- **Fire & energy** — `genergy`, `material_energy`, `heat`, `heat-wave`

### Motion & Animation
- **Wave effects** — `wave_diag`, `wave_spiral`, `blue_wave`, `code_wave`, `psyche_wave`, `spiral_wave`
- **Ripple effects** — `ripple`, `ripple_cycle`, `ripple_rainbow`, `ripple_prisim`, `c_ripple`, `psyche_ripple`
- **Shake & tremor** — `shake`, `tremor1`–`tremor4`, `tearing`
- **Rotation & spin** — `rotate_xyz`, `rotate_xyz_zoom`, `fold-spin`, `rainbow_cd_spin`

### Nature & Organic
- **Water effects** — `water`, `water_full`, `water_rgb`, `waterbend`, `underwater`, `ocean`, `fold-water`
- **Smoke & air** — `smoke`, `air`, `air_full`, `air-bowl`
- **Psychedelic** — `psych`, `psyche_ripple`, `psyche_wave`, `acid_color2`, `acidcam`, `acidcolor`, `halluc_gem`, `halluc_liquid`

### Blending & Compositing (material/)
The `material/` folder contains **200+ shaders** focused on texture blending and compositing techniques:
- **Alpha blending** — `material_alphablend`, `material_alphablend_xor`, `material_alphablend_bright`
- **Echo compositing** — `material_echo`, `material_echo_half`, `material_echo_mirror`, `material_echo_xor`
- **Mirror compositing** — `material_mirror1`–`material_mirror3`, `material_mirror_alpha`
- **Fill effects** — `material_fill`, `material_fill_black`, `material_fill_white`, `material_fill_pencil`
- **XOR blending** — `material_xor`, `material_xor_blend`, `material_xor_rgb`
- **Special** — `material_matrix`, `material_psychedelic`, `material_underwater`, `material_ripple`

### Interactive (Mouse-Controlled)
Many shaders respond to mouse position for real-time control:
- `air_full_mouse`, `audio_mouse`, `apart_mouse`, `bubble-zoom-mouse`, `code_flux_mouse`, `fisheye_mouse`, `hue-mouse`, `kale_mouse`, `matrix_mouse`, `neon_mouse`, `spiral-mouse`, `swirlMouse`, `xorMouse`, `zoom_in_out_mouse`

### Gem & Crystal
- `gem-color-spiral`, `gem-deep`, `gem-fish`, `gem-ripple`, `gem_frac`, `gem_glass`, `gem_metal`, `gem_rainbow_metal`, `gem_polar`, `halluc_gem`

## Additional Shader Families

The categories above are summaries — the collection contains many large named series that share a common style. The sections below describe those families. Each family has many numbered/themed members; only representative names are shown.

### `ant_gem_*` series (≈146 shaders)
Audio-reactive layered overlays that combine the geometry of the `ant_*` shaders with the saturated palette of the `gem_*` shaders. They drive a multi-pass color/warp on top of the camera frame using `amp_*` audio uniforms. Representative members: `ant_gem_aurora_tunnel`, `ant_gem_chrome_wave`, `ant_gem_cosmic_web`, `ant_gem_crystal_pulse`, `ant_gem_deep_bloom`, `ant_gem_diamond_storm`, `ant_gem_fire_spoke`, `ant_gem_fractal_ocean`, `ant_gem_glass_mandala`, `ant_gem_metal_*` (many subvariants: `_aurora`, `_cascade`, `_chrome`, `_coil`, `_crystal`, `_ember`, `_flux`, `_forge`, `_fracture`, `_glacier`, `_helix`, `_inferno`, `_lattice`, `_nebula`, `_opal`, `_orbital`, `_prism`, `_pulse`, `_ripple`, `_shard`, `_storm`, `_tessera`, `_vortex`, `_weave`).

### `game_*` and `game_ant_*` series (≈126 shaders)
Gameplay-friendly post-process variants — calibrated to be visible without significantly distorting screen-space gameplay (no aggressive UV warping, controlled alpha, no gameplay-occluding overlays). Two sub-families:

- **Tone / film looks** — `game_amber_mono`, `game_anamorphic`, `game_anime_cel`, `game_arcade_crt`, `game_bleach_bypass`, `game_chroma_split`, `game_cinema_wide`, `game_color_grade_*`, `game_film_grain`, `game_lcd_subpixel`, `game_lo_fi`, `game_neon_outline`, `game_night_vision`, `game_paper_sketch`, `game_retro_vhs`, `game_thermal`, `game_tilt_shift`, `game_vignette_*`.
- **`game_ant_*` boosted overlays** — gameplay-tuned versions of the `ant_gem_*` family (same names: `aurora_tunnel`, `chrome_wave`, `cosmic_web`, `metal_*`, `gem_*`, `frac_*`). Higher base alpha so the effect is visible during gameplay but the underlying scene remains readable.

### `pilot_effect_ant_*` series (≈80 shaders)
Stylized variants of the `ant_*` shaders intended for HUD / overlay use in pilot/cockpit-style scenes. They share the `ant_gem_*` naming (`_bloom`, `_flare`, `_lattice`, `_pulse`, `_ripple`, `_storm`, `_tunnel`, `_weave`, etc.) but emphasize transparent overlay output suitable for compositing on top of 3-D scenes.

### `react*` series (≈21 shaders)
Numbered audio-reactive shaders (`react`, `react2` … `react20+`). Each reacts to `amp` / `amp_*` uniforms with a different visual response (color shift, warp, bloom, kaleidoscope, wave). Useful as drop-in audio-visualizer post-effects.

### `random_*` series (≈60 shaders)
Hash- or noise-driven randomized effects. Examples: `random_colors`, `random_pos_fish`, `random_resize`, `random_rgb`, `random_rgb_strobe`, `random_soul`, `random_soul_by_mouse`, `random_spectrum_deep_melt`, `random_pixels_static`. Many use `seed` / `random_seed` to reproducibly drive pixel scrambling, color jitter, or position shuffling.

### `Liquid_*` series (≈11 shaders)
Liquid / molten distortion overlays — `Liquid_Censorship`, `Liquid_Crystal`, `Liquid_Crystal_2`, `Liquid_Crystal_Rainbow1`, `Liquid_Fractal_Tunnel`, `Liquid_Heat`, `Liquid_Heat_blend`, `Liquid_Light_Rainbow_Blend`. These animate flowing UV warps with chromatic separation.

### `drain*` series (≈9 shaders)
Whirlpool / drain swirls pulling toward screen center: `drain`, `drain_bend`, `drain_mandella`, `drain_mirror`, `drain_mirror_amp`, `drain_mirror_top`, `drain_mouse`, `drain_rainbow`. The `_amp` and `_mouse` variants drive the swirl center / strength via audio or pointer.

### `huri*` series (≈8 shaders)
Hurricane-style rotating swirl/zoom effects — `huri`, `huri1`–`huri3`, `huri_af`, `huri_create_mouse`, `hurixyz`, `huriz`. The `_af` variant uses audio-frequency drive (`amp_high`/`amp_low`); the `_mouse` variant tracks the pointer.

### `af_scale*` series (≈5 shaders)
Audio-frequency-driven uniform-scale shaders — `af_scale`, `af_scale2`, `af_scale3`, `af_scale_puple`, `af_scale_spectrum`. Frame is uniformly scaled in/out using bass / spectrum bin energy.

### `crystal*` series
Crystal lattice / refraction overlays — `crystal`, `crystal-2`, `crystal-3`, `crystal-4`, `crystalball`, `crystalbend`, `crystalblend2`, `crystalprism`. Faceted UV reflections, often combined with chromatic dispersion.

### `plasma*` series
Classic plasma-field overlays — `plasma`, `plasma2`, `plasma3`, `plasma_prism`, `plasma_rainbow`, `plasma_xor`. Sine-mixed sample positions yield the canonical demo-scene plasma color field.

### `comb3*` series
Three-tap comb-filter / lattice samplers (`comb3`, `comb3-frac-mouse`, `comb3-frac-mouse2`, `comb3_geo_mouse`, `comb3_mouse`). Sample the input at three offset positions and recombine — pointer-controlled in `_mouse` variants.

### `composite*` series
NTSC / CRT / VHS composite-video emulators: `composite`, `composite-static`, `composite2`, `composite3`, `composite_crt`, `composite_vhs`, `composite_vhs_flat`. Each adds chroma bleed, scanlines, and noise characteristic of analog signal degradation.

### `pong-atan*` series
ATAN-based wave shapers reminiscent of CRT scope output: `pong-ataan-ex`, `pong-atan`, `pong-atan2`, `pong-atan3`, `pong_tex`. Polar-coordinate atan2 warps create rolling wave bands across the frame.

### `fat-*` series
Thick / blocky color variants: `fat`, `fat-blue`, `fat-green`, `fat-red`, `fat-rgb`, `fat-slow`. Quantize and saturate the frame into chunky color regions.

### Smaller named families
Each of these is a small set (3–6 shaders) following the same naming pattern:

| Family | Members | Description |
|--------|---------|-------------|
| `scramble*` | `scramble`, `scramble-2`, `scramble-3` | Block / pixel scrambling that shuffles regions of the frame. |
| `snake*` | `snake`, `snake_dir`, `snake_updown` | Snake-style directional UV displacement. |
| `splash*` | `splash`, `splash-x`, `splash-y` | Radial / axial splash distortions. |
| `optxtime*` | `optxtime`, `optxtime_cos`, `optxtime_tex` | `optx`/time-driven parameter sweeps. |
| `Electric*` | `Electric`, `Electric_*` | Electric arc / lightning overlays. |
| `DispersionX*` | `DispersionX`, `DispersionX_*` | Chromatic dispersion variants along the X axis. |
| `tremor*` | `tremor1`–`tremor4` | Frame-shake / tremor effects of escalating intensity. |
| `cyclone*` | `cyclone*` (3) | Spiraling cyclone warps. |
| `glitchy*` | `glitchy*` (3) | Lighter-weight glitch variants distinct from `glitch_*`. |
| `code*` | `code_flux_mouse`, `code_wave`, … | Matrix/code-rain styled overlays. |
| `gpt*` | `gpt_echo`, `gptswirl`, … | AI-generated / experimental shaders. |
| `dream*`, `ghost*`, `magic*`, `light*`, `lightfade*` | various | Atmospheric soft-glow overlays. |

### Standalone named shaders
Notable individual shaders not part of a family that may not be in the categories above: `wormhole`, `tornado`, `tridim`, `triwavedistort`, `twirl`, `twarp`, `twarp2`, `tv`, `weirdlines`, `whirlx`, `wlight`, `wrap`, `wspiral`, `xcordstrobe`, `yin`, `zigzag`, `today`, `timeval`, `underwaterenchanced`. Each is a single-file effect — see the source for specific behavior.

### `material/` folder additions
Beyond the blending categories listed earlier, the `material/` folder also contains many less-common compositors. Patterns include `material_*_xor`, `material_*_blend`, `material_*_alpha`, `material_*_strobe`, and effect-specific variants such as `material_psychedelic`, `material_underwater`, `material_ripple`, `material_matrix`, `material_energy`, `material_pencil_*`. Most expect both `samp` (current frame) and `mat_samp` (overlay texture) plus `mat_size` and `image_pos`.

## Uniforms Reference

The shaders in this collection expect the uniforms listed below. Not every shader uses every uniform — most use a small subset (typically `samp`, `time_f`, `iResolution`, and optionally `iMouse` or one of the `amp_*` audio uniforms). Hosts loading these shaders should provide whichever of these uniforms are referenced by the shader being run.

### Core Inputs

| Uniform | Type | Description |
|---------|------|-------------|
| `samp` | `sampler2D` | Primary input texture (camera/video frame, or current scene). The most common sampler in this collection. |
| `iResolution` | `vec2` | Viewport resolution in pixels (width, height). A few shaders also accept `vec3`-style resolution; `vec2` is the canonical form here. |
| `time_f` | `float` | Elapsed time in seconds — main animation clock used by the majority of shaders. |
| `iTime` | `float` | Alternate elapsed-time uniform (Shadertoy-style). Equivalent to `time_f` where both are present. |
| `iTimeDelta` | `float` | Time since the last frame, in seconds. |
| `iFrame` | `int` | Current frame number (monotonically increasing). |
| `iFrameRate` | `float` | Target/measured frame rate in frames per second. |
| `iDate` | `vec4` | Wall-clock date packed as `(year, month, day, seconds-since-midnight)`. |
| `time_speed` | `float` | Multiplier controlling the rate at which `time_f` advances (used by hosts that scrub or accelerate animation). |

### Mouse / Pointer

| Uniform | Type | Description |
|---------|------|-------------|
| `iMouse` | `vec2` / `vec4` | Mouse position. As `vec2`: current pointer in pixels. As `vec4`: `(xy = current position, zw = last click position; z/w sign indicates button state)`. |
| `iMouseClick` | `vec2` | Position of the last mouse click in pixels. |

### Additional Texture Samplers

Some shaders blend, echo, or composite multiple textures. Hosts should bind these as needed.

| Uniform | Type | Description |
|---------|------|-------------|
| `samp1` … `samp8` | `sampler2D` | Auxiliary texture inputs. Used variously as additional layers (`samp1`–`samp4`), older frames in echo/feedback chains, or cached intermediate buffers. |
| `mat_samp` | `sampler2D` | Material/overlay texture (paired with `mat_size` and `image_pos`). Used by shaders in the `material/` folder. |
| `mat_size` | `vec2` | Pixel dimensions of `mat_samp`. |
| `image_pos` | `vec2` | Position offset (in pixels or normalized coords) at which the material texture should be placed. |

### Audio Reactivity

Shaders that respond to live audio expect any subset of these. Values are typically in the range `[0.0, 1.0]` unless noted.

| Uniform | Type | Description |
|---------|------|-------------|
| `amp` | `float` | Generic audio amplitude / bass level (0.0–1.0). Often the simple "loudness" input. |
| `uamp` | `float` | Audio amplitude after sensitivity scaling — the user-tunable version of `amp`. |
| `iamp` | `float` | Estimated dominant frequency in Hz (via zero-crossing rate); not a 0–1 value. |
| `amp_peak` | `float` | Peak absolute sample value in the current audio buffer. |
| `amp_rms` | `float` | RMS energy of the current audio buffer. |
| `amp_smooth` | `float` | Exponentially-smoothed amplitude for gradual transitions. |
| `amp_low` | `float` | Bass-band energy (below ~300 Hz). |
| `amp_mid` | `float` | Mid-band energy (~300–3000 Hz). |
| `amp_high` | `float` | Treble-band energy (above ~3000 Hz). |
| `spectrum` | `sampler1D` | 1-D frequency spectrum texture (FFT bins) for shaders that read individual bands. |
| `iSampleRate` | `float` | Audio sample rate in Hz (e.g. 44100). |
| `iChannelTime[4]` | `float[4]` | Playback time for each texture channel (Shadertoy-compatible). |
| `iChannelResolution[4]` | `vec3[4]` | Resolution of each texture channel. |

### Color / Channel Controls

Used by shaders that expose per-channel mixing, fading, or alpha blending.

| Uniform | Type | Description |
|---------|------|-------------|
| `alpha` | `float` | Generic alpha / blend factor (0.0–1.0). |
| `alpha_value` | `float` | Alternate scalar alpha used by some shaders. |
| `alpha_r`, `alpha_g`, `alpha_b` | `float` | Per-channel alpha multipliers for red/green/blue. |
| `value_alpha_r`, `value_alpha_g`, `value_alpha_b` | `float` | Per-channel alpha values (alternate naming used by some shaders). |
| `blendAmt` | `float` | Generic blend amount between two layers (0.0 = base only, 1.0 = overlay only). |
| `blendMode` | `int` | Discrete blend-mode selector (0 = normal, additional values shader-specific). |
| `inc_value`, `inc_valuex` | `vec4` | Color/parameter offsets accumulated per frame (used by stateful color-shift shaders). |
| `optx` | `vec4` | Generic 4-component option vector (shader-specific). |

### Effect / Animation Parameters

Common tweak knobs exposed by individual effects.

| Uniform | Type | Description |
|---------|------|-------------|
| `frequency` | `float` (default `0.5`) | Main spatial/temporal frequency of warps and waves. |
| `strength` | `float` (default `1.0`) | Intensity multiplier for warps and distortions. |
| `uDistortion` | `float` (default `0.5`) | Distortion magnitude for glitch / warp shaders. |
| `uPhaseRate` | `float` (default `0.1`) | Phase advance rate for cyclic effects. |
| `uRandRate` | `float` (default `0.2`) | Rate at which random/jitter values evolve. |
| `uRotateSpeed` | `float` (default `1.0`) | Rotation speed multiplier. |
| `uWarpSpeed` | `float` (default `0.1`) | Warp animation speed multiplier. |
| `seed`, `random_seed`, `random_var` | `float` / `vec4` | Seed inputs for hashed/randomized shaders. |
| `index_value` | `float` | Discrete index input (selector for palettes, modes, etc.). |
| `restore_black` | `float` | Toggle (0/1) used by the "strip black / restore black" pipeline so cropped letterboxing can be re-applied after a color-altering pass. |

### 3-D / Geometry (rarely used)

A handful of shaders expect a model-view-projection setup for vertex transforms.

| Uniform | Type | Description |
|---------|------|-------------|
| `mv_matrix` | `mat4` | Model-view matrix. |
| `proj_matrix` | `mat4` | Projection matrix. |

## License

See [LICENSE](LICENSE) for details.
