# GLSL Shader Collection

A collection of **2700+ OpenGL GLSL fragment shaders** and **182 GLSL compute shaders** for real-time video and image processing. These shaders are designed to be used as post-processing effects applied to live camera feeds, video textures, or generated visuals.

## Overview

All shaders are written in **GLSL (OpenGL Shading Language)**. Most are fragment shaders; the programs in `compute/` are OpenGL 4.3 compute shaders. They take texture input (typically a webcam or video source) and apply various visual transformations in real time. Many shaders support interactive control via mouse input and react to time-based animation.

## Directory Structure

Shaders are organized alphabetically into folders by the first character of their filename:

| Folder | Contents |
|--------|----------|
| `0-9/` | Shaders starting with a digit |
| `A/`–`Z/` | Shaders starting with the corresponding letter (case-insensitive) |
| `compute/` | 182 OpenGL 4.3 compute-shader effects and their separate manifests |
| `material/` | Material-based texture blending and compositing shaders |

## Fragment Shaders (`*.glsl`)

Fragment shaders make up the main library in the alphabetical directories and the separate `material/` collection. The following categories, families, history interfaces, and uniform reference apply to fragment shaders; compute shaders have their own interface later in this document.

### Effect Categories

#### Color Manipulation
- **Color shifting & grading** — `color_shift_fade`, `color_grad_rainbow`, `color_increase`, `chue`, `hue-mouse`, `sepia`, `grayscale`, `negative`
- **RGB channel effects** — `rgb`, `rgb_blur`, `rgb_fade`, `rgb_control`, `rgb_time`, `rgbchecker`
- **Strobe & flash** — `strobe`, `strobe_colors`, `strobe_light`, `flash`, `flash_gradient_strobe`, `blue_strobe`, `red_strobe`, `purple_strobe`
- **Rainbow effects** — `rainbow_blur`, `rainbow_bright`, `rainbow_spiral`, `rainbow_fractal`, `rainbow_ink`, `rainbow_prisim`, `bright_rainbow`

#### Geometric Distortion
- **Mirror effects** — `mirror1`–`mirror3`, `mirror-twist`, `mirror-wrap`, `mirror-spiral`, `mirror-zoom`, `mirror-bowl`, `funny_mirror`
- **Fisheye & lens** — `fisheye`, `fisheye_mouse`, `fisheye_warp`, `bubble`, `bubble-zoom-mouse`, `thick_glass`, `prism_glass`
- **Warp & twist** — `twist`, `twist_full`, `warp_tunnel`, `warpcursor`, `bend`, `bend_twist`, `elastic`
- **Zoom effects** — `zoom_fish`, `zoom_in_out_mouse`, `zoom_pulse`, `cd_zoom`, `brot-zoom-mouse`
- **Spiral & swirl** — `spiral_wave`, `spiral_mirror`, `spiral-code-*`, `swirl_by_mouse`, `color_swirl_beautiful`, `gptswirl`, `g_swirl`
- **Page turn & fold** — `page_turn`, `fold`, `fold-mirror`, `fold-spin`, `tex_fold`

#### Fractal & Mathematical
- **Fractal patterns** — `fractal`, `frac_shader01`–`frac_shader05`, `frac_zoom1`–`frac_zoom8`, `fractal-code-large-*`, `new_fractal`, `fractal_diamond_rainbow`
- **Mandelbrot / Julia** — `mandella1`, `julia`, `brot-zoom-mouse`, `frac_shader02_dmd_mandella`
- **Geometric patterns** — `geometric`–`geometric5`, `grid_pattern`, `grid_spiral`, `diamond`, `prism_quad`
- **Kaleidoscope** — `kale`, `kale2`–`kale4`, `kscopic`, `gkale`, `gkalei`

#### Video Echo & Feedback
- **Echo effects** — `echo_color`, `echo_mirror`, `echo_mix`, `echo_rainbow_spin`, `echo_xor`, `echo_shift`, `echo_sin`
- **Feedback loops** — `echo_loop`, `echo_loop2`, `gpt_echo`
- **Trail effects** — `gtrail`, `gtrail2`, `HyperFocusTrails`

#### Glitch & Digital
- **Glitch effects** — `glitch1`, `glitch_boil`, `glitch_effect`, `glitch_wave`, `glitch-react`, `new_glitch`, `atan-glitch`
- **VHS & retro** — `vhs`, `vhs2`, `vhs_damage`, `vhs-palette`, `old-film`, `snes`, `8bit`, `analog`
- **Pixel & block** — `pixels`, `block_pixels`, `smooth_pixel`, `random_pixels_static`
- **XOR operations** — `xor_rgb`, `xor_sine_swirl`, `xorstrobe`, `xorsheet`, `subtle_xor`, `alpha_xor`

#### Lighting & Atmosphere
- **Glow & bloom** — `glow`, `bloom`, `bright`, `brighten`, `whitelight`, `light_pulse`
- **Aura effects** — `aura`–`aura9`, `auraXi1`–`auraXi3`, `green_aura`, `gem-aura`
- **Neon** — `neon`, `neon_mouse`, `frac_shader01_smooth_neon`
- **Fire & energy** — `genergy`, `material_energy`, `heat`, `heat-wave`

#### Motion & Animation
- **Wave effects** — `wave_diag`, `wave_spiral`, `blue_wave`, `code_wave`, `psyche_wave`, `spiral_wave`
- **Ripple effects** — `ripple`, `ripple_cycle`, `ripple_rainbow`, `ripple_prisim`, `c_ripple`, `psyche_ripple`
- **Shake & tremor** — `shake`, `tremor1`–`tremor4`, `tearing`
- **Rotation & spin** — `rotate_xyz`, `rotate_xyz_zoom`, `fold-spin`, `rainbow_cd_spin`

#### Nature & Organic
- **Water effects** — `water`, `water_full`, `water_rgb`, `water_hq_01`–`water_hq_25`, `waterbend`, `underwater`, `ocean`, `fold-water`
- **Smoke & air** — `smoke`, `air`, `air_full`, `air-bowl`
- **Psychedelic** — `psych`, `psyche_ripple`, `psyche_wave`, `acid_color2`, `acidcam`, `acidcolor`, `halluc_gem`, `halluc_liquid`

#### Blending & Compositing (`material/`)
The `material/` folder contains **200+ shaders** focused on texture blending and compositing techniques:
- **Alpha blending** — `material_alphablend`, `material_alphablend_xor`, `material_alphablend_bright`
- **Echo compositing** — `material_echo`, `material_echo_half`, `material_echo_mirror`, `material_echo_xor`
- **Mirror compositing** — `material_mirror1`–`material_mirror3`, `material_mirror_alpha`
- **Fill effects** — `material_fill`, `material_fill_black`, `material_fill_white`, `material_fill_pencil`
- **XOR blending** — `material_xor`, `material_xor_blend`, `material_xor_rgb`
- **Special** — `material_matrix`, `material_psychedelic`, `material_underwater`, `material_ripple`

#### Interactive (Mouse-Controlled)
Many shaders respond to mouse position for real-time control:
- `air_full_mouse`, `audio_mouse`, `apart_mouse`, `bubble-zoom-mouse`, `code_flux_mouse`, `fisheye_mouse`, `hue-mouse`, `kale_mouse`, `matrix_mouse`, `neon_mouse`, `spiral-mouse`, `swirlMouse`, `xorMouse`, `zoom_in_out_mouse`

#### Gem & Crystal
- `gem-color-spiral`, `gem-deep`, `gem-fish`, `gem-ripple`, `gem_frac`, `gem_glass`, `gem_metal`, `gem_rainbow_metal`, `gem_polar`, `halluc_gem`

### Additional Shader Families

The categories above are summaries — the collection contains many large named series that share a common style. The sections below describe those families. Each family has many numbered/themed members; only representative names are shown.

#### `ant_gem_*` series (48 shaders)
Audio-reactive layered overlays that combine the geometry of the `ant_*` shaders with the saturated palette of the `gem_*` shaders. They drive a multi-pass color/warp on top of the camera frame using `amp_*` audio uniforms. Representative members: `ant_gem_aurora_tunnel`, `ant_gem_chrome_wave`, `ant_gem_cosmic_web`, `ant_gem_crystal_pulse`, `ant_gem_deep_bloom`, `ant_gem_diamond_storm`, `ant_gem_fire_spoke`, `ant_gem_fractal_ocean`, `ant_gem_glass_mandala`, `ant_gem_metal_*` (many subvariants: `_aurora`, `_cascade`, `_chrome`, `_coil`, `_crystal`, `_ember`, `_flux`, `_forge`, `_fracture`, `_glacier`, `_helix`, `_inferno`, `_lattice`, `_nebula`, `_opal`, `_orbital`, `_prism`, `_pulse`, `_ripple`, `_shard`, `_storm`, `_tessera`, `_vortex`, `_weave`).

#### `game_*` and `game_ant_*` series (146 shaders)
Gameplay-friendly post-process variants — calibrated to be visible without significantly distorting screen-space gameplay (no aggressive UV warping, controlled alpha, no gameplay-occluding overlays). Two sub-families:

- **Tone / film looks** — `game_amber_mono`, `game_anamorphic`, `game_anime_cel`, `game_arcade_crt`, `game_bleach_bypass`, `game_chroma_split`, `game_cinema_wide`, `game_color_grade_*`, `game_film_grain`, `game_lcd_subpixel`, `game_lo_fi`, `game_neon_outline`, `game_night_vision`, `game_paper_sketch`, `game_retro_vhs`, `game_thermal`, `game_tilt_shift`, `game_vignette_*`.
- **`game_ant_*` boosted overlays** — gameplay-tuned versions of the `ant_gem_*` family (same names: `aurora_tunnel`, `chrome_wave`, `cosmic_web`, `metal_*`, `gem_*`, `frac_*`). Higher base alpha so the effect is visible during gameplay but the underlying scene remains readable.

#### `react*` series (40 shaders)
This group contains the numbered audio-reactive shaders (`react`, `react2` … `react20`) plus the 20-member `react_x_*` family. Each reacts to `amp` / `amp_*` uniforms with a different visual response (color shift, warp, bloom, kaleidoscope, wave). Useful as drop-in audio-visualizer post-effects.

#### `random_*` series (61 shaders)
Hash- or noise-driven randomized effects. Examples: `random_colors`, `random_pos_fish`, `random_resize`, `random_rgb`, `random_rgb_strobe`, `random_soul`, `random_soul_by_mouse`, `random_spectrum_deep_melt`, `random_pixels_static`. Many use `seed` / `random_seed` to reproducibly drive pixel scrambling, color jitter, or position shuffling.

#### `Liquid_*` series (11 shaders)
Liquid / molten distortion overlays — `Liquid_Censorship`, `Liquid_Crystal`, `Liquid_Crystal_2`, `Liquid_Crystal_Rainbow1`, `Liquid_Fractal_Tunnel`, `Liquid_Heat`, `Liquid_Heat_blend`, `Liquid_Light_Rainbow_Blend`. These animate flowing UV warps with chromatic separation.

#### `drain*` series (9 shaders)
Whirlpool / drain swirls pulling toward screen center: `drain`, `drain_bend`, `drain_mandella`, `drain_mirror`, `drain_mirror_amp`, `drain_mirror_top`, `drain_mouse`, `drain_rainbow`. The `_amp` and `_mouse` variants drive the swirl center / strength via audio or pointer.

#### `huri*` series (8 shaders)
Hurricane-style rotating swirl/zoom effects — `huri`, `huri1`–`huri3`, `huri_af`, `huri_create_mouse`, `hurixyz`, `huriz`. The `_af` variant uses audio-frequency drive (`amp_high`/`amp_low`); the `_mouse` variant tracks the pointer.

#### `af_scale*` series (59 shaders)
Audio-frequency-driven scale shaders. The core set is `af_scale`, `af_scale2`, `af_scale3`, `af_scale_puple`, and `af_scale_spectrum`; newer additions include `af_scale2_dark`, `af_scale2_react`, `af_scale_pulse`, and 51 `af_scale-cache-*` temporal variants. They scale, fold, or layer the frame using amplitude, spectrum energy, and (for cache variants) frame history.

---

### Frame Cache & Spectrum History

ACMX2 now exposes both histories as array textures. The array form keeps the complete ring on one texture unit, supports a runtime-selected depth, and avoids moving every stored frame when the ring advances. The older fixed sampler names are retained only as a compatibility mode.

#### Frame history (`history`)

Current array-cache shaders declare:

```glsl
#ifndef SIZE
#define SIZE 8
#endif

uniform sampler2DArray history;
uniform int history_head;

int cacheLayer(int index) {
    return (history_head + clamp(index, 0, SIZE - 1)) % SIZE;
}

vec4 cacheHist(int index, vec2 uv) {
    return texture(history, vec3(uv, float(cacheLayer(index))));
}
```

`SIZE` is injected by ACMX2 from `--texture-cache-size` when the shader is compiled (1–64, default 8). `history_head` is the physical array layer containing logical index 0. Logical indices are ordered **oldest to newest**, so `cacheHist(0, uv)` reads the oldest retained frame and `cacheHist(SIZE - 1, uv)` reads the newest. The current input is still the separate `sampler2D samp`; it is not an extra `history` layer.

Enable this interface with `--texture-cache --texture-cache-array`. The cache stores recent source/input frames and is populated only for cache-aware shaders. On startup ACMX2 seeds all layers with the first accepted frame, so shaders do not sample uninitialized layers while the ring warms up.

Legacy mode (without `--texture-cache-array`) binds separate `sampler2D` values. `samp1` is the oldest entry and `samp8` is the newest for the default eight-frame cache. `textures[SIZE]` is the scalable legacy array-of-samplers spelling with the same oldest-to-newest ordering. These declarations are not interchangeable with `sampler2DArray history`: use the representation selected by the host. New shaders in this repository use `history` and `history_head`.

#### Spectrum history (`spectrum_history`)

The live FFT remains available through `sampler1D spectrum`; `spectrum0` is an alias of that same current-spectrum texture. Historical FFT frames now use a runtime-sized 1-D array texture:

```glsl
uniform sampler1D spectrum;
uniform sampler1D spectrum0; // current-spectrum alias
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;

float spectrumHist(int age, float frequency) {
    if (spectrum_history_size <= 0) {
        return texture(spectrum, clamp(frequency, 0.0, 1.0)).r;
    }

    int count = max(spectrum_history_size, 1);
    int layer = (spectrum_history_head - (max(age, 0) % count) + count) % count;
    return texture(spectrum_history,
                   vec2(clamp(frequency, 0.0, 1.0), float(layer))).r;
}
```

Here age 0 is the newest/current stored FFT frame, age 1 is the preceding FFT frame, and `spectrum_history_size - 1` is the oldest. Unlike frame history, spectrum history therefore counts **newest to oldest**. Do not assume a fixed depth of eight; use `spectrum_history_size` for loop bounds. ACMX2 allocates the `GL_TEXTURE_1D_ARRAY` with `GL_R32F` layers when audio is compiled in and `--enable-audio --enable-audio-buffers N` is supplied. The requested depth is limited by the GPU's maximum array-texture layers.

Common frequency landmarks (approximate, depends on FFT size and sample rate):

| Frequency coord | Approx. range | Band |
|----------------|---------------|------|
| 0.00 – 0.06 | < ~150 Hz | Sub-bass |
| 0.06 – 0.20 | ~150–500 Hz | Bass |
| 0.20 – 0.35 | ~500–1 kHz | Low-mid |
| 0.35 – 0.55 | ~1–3 kHz | Mid |
| 0.55 – 0.75 | ~3–8 kHz | Presence/treble |
| 0.75 – 1.00 | > ~8 kHz | Air/high-treble |

Accumulated energy across the available history (useful for sustain detection):

```glsl
float histEnergy(float freq) {
    float e = 0.0;
    for (int i = 0; i < spectrum_history_size; i++) {
        e += spectrumHist(i, freq);
    }
    return e;
}
```

---

### New Shader Families (Added 2026)

#### `ant_cache_spectrum8_*` series (35 shaders)
Audio-reactive shaders that combine frame history (`history`) with FFT history (`spectrum_history`). Each shader has a distinct visual theme but shares the same feedback architecture: the frame cache is used for zoom/rotate layering and FFT history modulates per-layer hue shift, zoom depth, and rotation speed. The `spectrum8` part of the family name is historical; shaders use the runtime array interfaces described above. All use `iTime` for smooth animation.

Members: `acid_rain`, `caustic_storm`, `chromatic_pulse`, `cosmic_web`, `echo_quad_mirror`, `fractal`, `fractal_xor_fold`, `galaxy_swirl`, `geometric_polar`, `glitch_boil`, `glitch_storm`, `hex_grid`, `holographic`, `kaleido_sin_osc`, `kaleidoscope`, `lava_flow`, `lightning`, `liquid_light`, `mandala`, `mirror_tile_rotor`, `neon_grid`, `neural`, `oilslick`, `plasma`, `radial_echo`, `spectrum_rings`, `starburst`, `strobe_tunnel`, `tremor_storm`, `tunnel`, `vignette_calm`, `voronoi_pulse`, `vortex`, `warp_drive`, `zebra_wave`.

#### `ant_peak_inversion_cache_spectrum_time_*` series (25 shaders)
Built on the same architecture as `ant_cache_spectrum8_*` but with effects tuned to be approximately 5× more intense. Historical FFT energy is accumulated across the available spectrum-history layers and then used with large multipliers for zoom collapse, rotation snap, and color inversion. Uses `iTime`. Adds hard peak inversion (`mix(color, 1-color, ...)`) at `amp_peak` thresholds.

Members: `acid_rain_flood`, `caustic_drowning`, `chromatic_quake`, `fractal_inferno`, `galaxy_devourer`, `glitch_apocalypse`, `hex_seizure`, `hologram_collapse`, `hyperspace_tunnel`, `kaleidoscope_storm`, `lightning_god`, `magma_eruption`, `mandala_pulse`, `neon_grid_inferno`, `neural_overload`, `oilslick_meltdown`, `plasma_furnace`, `radial_echo_chamber`, `spectrum_visualizer`, `starburst_supernova`, `strobe_void`, `voronoi_seizure`, `vortex_singularity`, `warp_drive_overload`, `zebra_riot`.

#### `ant_time_f_color_*` series (25 shaders)
A family that makes frame and FFT history **visually obvious and structural**: history is the primary compositional device rather than a subtle modifier. It uses `time_f`, which ACMX2 wraps at `65536 × 2π` to preserve useful continuity for trigonometric and `mod()` animation. The original effects were designed around eight cached frames and eight FFT ages; ACMX2 maps those logical indices through the array heads.

| Shader | How history is shown |
|--------|----------------------|
| `ringbuffer_spiral` | 9 spiral arms, each sampling a different cache frame |
| `echo_chamber` | 8 ghost copies of past frames offset in an audio-driven ring |
| `spectrum_waterfall` | y-axis = age; top row = FFT age 0 (now), bottom = age 7 |
| `timeline_strips` | Screen divided into 9 vertical strips, one per cache frame |
| `trail_blaze` | Motion-blur trail through all 9 frames along an audio path |
| `ghost_train` | 8 ghosts marching across the screen at different speeds |
| `memory_kaleidoscope` | Pie-slice kaleidoscope where each slice = different cache frame |
| `tunnel_recall` | Concentric rings, one ring per cache frame, with visible borders |
| `fft_aurora` | 8 aurora curtain bands, one per FFT-history age 0–7 |
| `shutter_burst` | 3×3 grid showing all 9 cache frames simultaneously |
| `polar_history` | Clock-face wedges: angle = age, radius = FFT frequency |
| `radial_smear` | Concentric rings of cache frames blended outward |
| `crosshatch_recall` | 3×3 grid cells with per-cell FFT history overlay bar |
| `afterimage_burn` | max-blend of all 9 frames for a long-exposure burn-in look |
| `quantum_freeze` | Random per-tile pick from 9 cache frames |
| `light_painting` | Additive long-exposure trail across all cache frames |
| `bass_pulse_rings` | 8 expanding rings; each ring's brightness = bass history at that age |
| `glitch_archive` | Scanline bands snap to different cache frames at audio intervals |
| `data_stream` | 8 vertical columns, each scrolling one FFT-history age |
| `parallax_layers` | 9 depth planes scrolling at speeds proportional to their age |
| `mirror_corridor` | 8 receding mirror planes, each showing an older cache frame |
| `timeline_swirl` | Spiral where angle encodes age and radius encodes FFT frequency |
| `acid_smear` | Each cache frame distorted by its matching `spectrum*` waveform |
| `spectrogram_paint` | Full 2-D spectrogram (x = frequency, y = age 0–7) |
| `holo_replay` | 9 transparent holographic layers with chromatic aberration per layer |

#### Additional 2026 shader families

These newer families extend the collection with high-detail, audio-reactive, cache-driven, and gameplay-oriented effects. The filename prefix identifies the shared rendering approach; the remainder of each name describes that shader's visual theme.

| Family | Count | Description |
|--------|------:|-------------|
| `ant_texture_cache_spectrum_scale_*` | 25 | Scalable trail-cache effects that read `history` with the runtime `SIZE`. FFT history controls the scale, color, displacement, and persistence of themes such as `chromatic`, `comet`, `ghost`, `kaleido`, `neon_trail`, `tunnel`, and `vortex`. |
| `code-frac-*` | 25 | Audio-reactive recursive folds and kaleidoscopic fractal texture remixes. Members range from `aurora-vault` and `crystal-tunnel` to `prism-wormhole` and `zero-gravity-fold`. |
| `code-frac-x-*` | 25 | Higher-detail fractal variants built for large displays, with derivative-filtered Julia fields, log-polar singularities, recursive geometry, chromatic refraction, and audio-driven motion. |
| `code-mirror-*` | 25 | Mirror tiling, radial reflection, kaleidoscopic folding, and animated refraction combined with themed palettes and audio response. Examples include `aurora-corridor`, `echo-temple`, `glass-tesseract`, and `vortex-gallery`. |
| `code-update-*` | 25 | Compact spectrum-reactive effects with distinct procedural scenes—ribbons, lattices, stained glass, ferrofluid, reefs, nebulae, and wormholes—plus peak-triggered flashes or inversion. |
| `codex_*` | 45 | Experimental effects split into several groups: four cartoon/cel/VHS looks; ten `codex_glitch_*` fractal glitches; ten `codex_grad_fractal_*` palette-heavy fractals; ten `codex_vhs_*` tape simulations; and standalone aura, chrome, mosaic, prism, topography, echo, and signal-decay effects. Variants use time and, where appropriate, mouse control. |
| `fractal-code-large-*` | 25 | Large-format, alpha-preserving fractal overlays. Three recursive folds, kaleidoscopic geometry, derivative-aware sampling, chromatic separation, and soft-light compositing keep the source visible while `iMouse` and the `amp_*` audio bands animate themes such as `aurora-veil`, `liquid-cathedral`, `ocean-mandala`, `rainbow-glass`, and `temporal-gem`. |
| `game_codex_*` | 20 | Readable gameplay overlays for recognizable events and states, including target lock, radar ping, critical hit, shield hit, low ammo, power-up, speed boost, stealth, underwater depth, and elemental damage. |
| `inthesky_cache_*` | 10 | Celestial frame-history compositions that layer `history` with FFT history to form auroras, cloud architecture, solar pillars, storm crowns, and mirrored skies. |
| `inv_cache_code_*` | 10 | Cache-driven perceptual fields inspired by afterimages, phosphenes, peripheral drift, entoptic patterns, and dreamlike visual persistence. |
| `inversion_code_cache_*` | 25 | Temporal inversion energy fields. Cached frames and spectrum history are folded into scientific and abstract structures such as charge maps, flux lattices, moiré tensors, quasicrystals, plasma filaments, and quantum foam. |
| `kale_code_*` | 15 | Nested, multi-domain kaleidoscopes with recursive folds, mirrored sampling, chromatic refraction, and audio-reactive segment counts or motion. |
| `liquid_code_*` | 5 | Fluid metallic warps (`chrome_nautilus`, `iridescent_whirlpool`, `mercury_vortex`, `molten_helix`, and `silver_riptide`) using noise fields, thin-film color, and audio-responsive lighting. |
| `metal-code-*` | 10 | Procedural metallic surfaces with animated height fields, reflected texture sampling, iridescence, and physically inspired highlights. |
| `mirror-code-x-*` | 25 | Lightweight mirror and symmetry transforms spanning horizontal, vertical, diagonal, quadrant, strip, checker, pinwheel, ripple, spiral, and 6/8/12-way kaleidoscope layouts. Most use only `samp`; animated variants add `time_f`, while radial variants use `iResolution` for aspect-correct folding. |
| `rainbow-code-*` | 10 | High-detail spectral materials and distortions: aurora silk, chromatic ribbons, diamond waves, holographic facets, liquid pearl, opal vortices, caustics, bloom, and stained-glass kaleidoscopes. |
| `rainbow_metal_code_*` | 25 | Audio-reactive rainbow metal with procedural normals, spectral lighting, and optional `slider1`–`slider4` controls. Themes include chrome, mercury, liquid mandalas, magnetic opal, radiant helixes, and foundry effects. |
| `spiral-code-*` | 25 | Time-animated spiral and polar-coordinate texture transformations. Mirrored sampling, tunnels, coils, helixes, kaleidoscopic folds, chromatic splits, and themed highlights produce effects such as `chromatic-tunnel`, `fractal-coil`, `galaxy-vortex`, `nautilus-glass`, and `prism-cyclone`. These require only `samp` and `time_f`. |
| `texture_cache_hq_*` | 12 | High-quality temporal compositions that blend the live frame with every entry in the scalable `history` array. Aspect-correct mirrored sampling, age-weighted layers, procedural warps, spectral palettes, and tone mapping create aurora, bio-lattice, cosmic-flower, crystal, kaleidoscope, liquid, molten, neon, prism, cathedral, tunnel, and mandala effects. |
| `twist-code-*` | 25 | Animated polar and radial tunnel warps, ranging from double helices and augers to gravity wells, shockwaves, turbines, and singularities. |
| `vhs-code-*` | 11 | Focused analog-tape artifacts including chroma bleed, RF noise, dropout, ghosting, head switching, pause jitter, tracking roll, tape warp, worn tape, and stylized home-movie/Kung Fury looks. |
| `water_hq_*` | 25 | High-quality, time-animated water refraction effects that preserve the input alpha and use mirrored UVs for safe edge sampling. The numbered set covers caustic shallows, ocean swell, rain ripples, glass refraction, currents, whirlpools, droplet lenses, shoreline, storm water, waterfall, and coral-lagoon looks using only `samp` and `time_f`. |
| `xor_code_*` | 15 | Byte-level XOR color transforms combined with procedural spatial masks. Includes bit-plane, halftone, circuit, kaleidoscope, feedback, solarized, and smooth pastel/prismatic variants. |

#### Cache-array shader families not covered above

The following current families use `--texture-cache-array`; audio-reactive members additionally require audio and spectrum-history buffers. They use `history`/`history_head` and, where applicable, `spectrum_history`/`spectrum_history_head`/`spectrum_history_size`.

| Family | Count | Description |
|--------|------:|-------------|
| `codex-gen-cache-*` | 100 | Large mixed collection of temporal scenes and signal-processing looks, including afterimages, spectrographs, geometric archives, tunnels, organic forms, CRT/glitch effects, and audio visualizers. |
| `color_peak_*` | 81 | Peak-responsive color effects. 80 members use frame history and 79 also use FFT history; `color_peak_inversion` is the non-cache member, while `color_peak_inversion_cache` uses frame history without FFT history. |
| `hue-cache-code-*` | 25 | Hue-focused temporal remixes with mirrored cache sampling and FFT-history-driven color motion. |
| `psyche-bubble-cache-*` | 25 | Dense bubble, liquid, lattice, orbital, and kaleidoscopic scenes built from the frame and spectrum arrays. |
| `ripple-cache-loom-crown-*` | 25 | Elaborate ripple/loom/crown compositions driven by temporal texture layers and FFT history. |
| `trail-cache-code-*` | 25 | Trail effects ranging from aurora drift and chromatic comets to recursive stars, sonar pulses, gravity wells, and temporal geometry. |
| `darkstar-spectrum-trail-cache-*` | 10 | Dark-space trail effects with spectrum-driven auroras, quasars, prisms, pulsars, and singularities. |
| `parallel-cache-*` | 10 | Parallel/multi-plane temporal remixes using array-backed cache layers. |
| `psyche-cache-code-*` | 10 | Psychedelic temporal fields including stained glass, Mobius, mandala, mycelium, sonar, and memory-tunnel themes. |

Recent standalone array-cache additions include `acid-crown-cache`, `darkstar_trail_cache`, `glitch-dragon-cache`, `phantom_drift_cache`, `spectrum-cache-breathe`, `trail-cache-blur`, `trail-cache-expand`, `trail-cache-realism`, `trail-cache-vibration`, `warp_cache`, and `warp_cache_intense`. Recent non-array additions that were previously absent from this overview include `af_scale2_dark`, `darkstar_cache`, `mirror-repeat`, and the 80-member `pilot_effect_*` family.

#### Library manifests and omitted files

`index.txt` and `library.json` currently contain the same 2,773 main-library fragment shaders. The 205 shaders under `material/` are overlay/material programs and are intentionally managed separately rather than listed in the main shader manifest. `M/material.glsl`, `P/purple_material.glsl`, and the root `vertex.glsl` are support programs, not selectable fragment effects.

Two selectable-looking fragment files are present on disk but missing from both main manifests: `D/DigitalLight.glsl` and `D/DigitalLightStorm.glsl`. They will not appear during normal library navigation unless the manifests are regenerated or the files are loaded directly with `--fragment`. Both also use the legacy `uamp` name as if it were instantaneous amplitude; current ACMX2 supplies audio sensitivity in `uamp`, so their audio response does not match their source comments.

#### Other recent additions

| Shaders | Description |
|---------|-------------|
| `blend_orig_10_cache`, `blend_orig_25_cache`, `blend_orig_50_cache`, `blend_orig_75_cache` | Blend the live frame with the oldest cached layer at fixed 10%, 25%, 50%, or 75% strengths. |
| `af_scale_pulse`, `ant_gem_metal_pulse_mouse` | A pulsing audio-frequency scale effect and a mouse-positioned metallic `ant_gem` pulse variant. |
| `echo_cache` | Builds a diagonally offset echo by repeatedly blending frame-history layers. |
| `fill_black`, `fill_black_fold` | Black-fill compositors; the fold variant combines the fill with mirrored/folded sampling. |
| `fractal_texture_large-nowrap`, `fractal_texture_large_spectrum` | Large-format fractal texture effects, with a non-wrapping variant and an FFT-reactive variant. |
| `hallu_code_abyssal_opaline`, `hallu_code_vesper_xenolith` | Audio-reactive hallucinatory fields with mirrored UVs, layered noise, opaline color, and deep procedural geometry. |
| `brightness_increase`, `grad_color`, `shift_grad`, `remove_flicker` | Utility color processors for brightness, gradient color, gradient shifting, and luminance-based flicker reduction. |
| `mirror-wrap-scale`, `pond`, `tunnel_x` | A scaled mirror-wrap, an extreme mouse/audio/cache-driven water ripple, and a tunnel distortion. |
| `vhs-color-mode` | A sharpened cyan-shadow/magenta-highlight VHS grade with chroma styling and analog noise. |

#### `crystal*` series
Crystal lattice / refraction overlays — `crystal`, `crystal-2`, `crystal-3`, `crystal-4`, `crystalball`, `crystalbend`, `crystalblend2`, `crystalprism`. Faceted UV reflections, often combined with chromatic dispersion.

#### `plasma*` series
Classic plasma-field overlays — `plasma`, `plasma2`, `plasma3`, `plasma_prism`, `plasma_rainbow`, `plasma_xor`. Sine-mixed sample positions yield the canonical demo-scene plasma color field.

#### `comb3*` series
Three-tap comb-filter / lattice samplers (`comb3`, `comb3-frac-mouse`, `comb3-frac-mouse2`, `comb3_geo_mouse`, `comb3_mouse`). Sample the input at three offset positions and recombine — pointer-controlled in `_mouse` variants.

#### `composite*` series
NTSC / CRT / VHS composite-video emulators: `composite`, `composite-static`, `composite2`, `composite3`, `composite_crt`, `composite_vhs`, `composite_vhs_flat`. Each adds chroma bleed, scanlines, and noise characteristic of analog signal degradation.

#### `pong-atan*` series
ATAN-based wave shapers reminiscent of CRT scope output: `pong-ataan-ex`, `pong-atan`, `pong-atan2`, `pong-atan3`, `pong_tex`. Polar-coordinate atan2 warps create rolling wave bands across the frame.

#### `fat-*` series
Thick / blocky color variants: `fat`, `fat-blue`, `fat-green`, `fat-red`, `fat-rgb`, `fat-slow`. Quantize and saturate the frame into chunky color regions.

#### Smaller named families
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

#### Standalone named shaders
Notable individual shaders not part of a family that may not be in the categories above: `wormhole`, `tornado`, `tridim`, `triwavedistort`, `twirl`, `twarp`, `twarp2`, `tv`, `weirdlines`, `whirlx`, `wlight`, `wrap`, `wspiral`, `xcordstrobe`, `yin`, `zigzag`, `today`, `timeval`, `underwaterenchanced`. Each is a single-file effect — see the source for specific behavior.

#### `material/` folder additions
Beyond the blending categories listed earlier, the `material/` folder also contains many less-common compositors. Patterns include `material_*_xor`, `material_*_blend`, `material_*_alpha`, `material_*_strobe`, and effect-specific variants such as `material_psychedelic`, `material_underwater`, `material_ripple`, `material_matrix`, `material_energy`, `material_pencil_*`. Most expect both `samp` (current frame) and `mat_samp` (overlay texture) plus `mat_size` and `image_pos`.

### Fragment-shader uniforms reference

The shaders in this collection expect the uniforms listed below. Not every shader uses every uniform — most use a small subset (typically `samp`, `time_f`, `iResolution`, and optionally `iMouse` or one of the `amp_*` audio uniforms). Hosts loading these shaders should provide whichever of these uniforms are referenced by the shader being run.

#### Core Inputs

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

#### Mouse / Pointer

| Uniform | Type | Description |
|---------|------|-------------|
| `iMouse` | `vec2` / `vec4` | Mouse position. As `vec2`: current pointer in pixels. As `vec4`: `(xy = current position, zw = last click position; z/w sign indicates button state)`. |
| `iMouseClick` | `vec2` | Position of the last mouse click in pixels. |

#### Additional Texture Samplers

Some shaders blend, echo, or composite multiple textures. Hosts should bind these as needed.

| Uniform | Type | Description |
|---------|------|-------------|
| `history` | `sampler2DArray` | Current frame-history interface. Contains `SIZE` cached input frames in a physical ring; convert a logical oldest-to-newest index with `(history_head + index) % SIZE`. Requires ACMX2's texture-array cache mode. |
| `history_head` | `int` | Physical `history` layer corresponding to logical index 0 (the oldest retained frame). |
| `SIZE` | compile-time macro | Frame-history depth injected by ACMX2 from `--texture-cache-size` (1–64, default 8). It is not a uniform. |
| `samp1` … `samp8` | `sampler2D` | Legacy fixed cache interface: oldest through newest. Supported by ACMX2's non-array compatibility mode but no longer declared by the current shader collection. |
| `textures[SIZE]` | `sampler2D[]` | Legacy scalable array-of-samplers interface, also oldest through newest. Do not use it with `--texture-cache-array`; current shaders declare `history` instead. |
| `mat_samp` | `sampler2D` | Material/overlay texture (paired with `mat_size` and `image_pos`). Used by shaders in the `material/` folder. |
| `mat_size` | `vec2` | Pixel dimensions of `mat_samp`. |
| `image_pos` | `vec2` | Position offset (in pixels or normalized coords) at which the material texture should be placed. |

#### Audio Reactivity

Shaders that respond to live audio expect any subset of these. Values are typically in the range `[0.0, 1.0]` unless noted.

| Uniform | Type | Description |
|---------|------|-------------|
| `amp` | `float` | Generic audio amplitude / bass level (0.0–1.0). Often the simple "loudness" input. |
| `uamp` | `float` | Current user audio-sensitivity value. Despite the legacy name, ACMX2 does not upload amplitude to this uniform. |
| `iamp` | `float` | Estimated dominant frequency in Hz (via zero-crossing rate); not a 0–1 value. |
| `amp_peak` | `float` | Peak absolute sample value in the current audio buffer. |
| `amp_rms` | `float` | RMS energy of the current audio buffer. |
| `amp_smooth` | `float` | Exponentially-smoothed amplitude for gradual transitions. |
| `amp_low` | `float` | Bass-band energy (below ~300 Hz). |
| `amp_mid` | `float` | Mid-band energy (~300–3000 Hz). |
| `amp_high` | `float` | Treble-band energy (above ~3000 Hz). |
| `spectrum` | `sampler1D` | 1-D frequency spectrum texture (FFT bins) for shaders that read individual bands. |  
| `spectrum0` | `sampler1D` | Alias of the live `spectrum` texture. It is not the first element of a `spectrum0`–`spectrum7` sampler set. |
| `spectrum_history` | `sampler1DArray` | Runtime-sized FFT history. Each `GL_R32F` layer contains normalized red-channel FFT magnitudes; address it with `(frequency, physicalLayer)`. |
| `spectrum_history_head` | `int` | Physical array layer holding FFT age 0 (the newest stored spectrum). |
| `spectrum_history_size` | `int` | Allocated FFT-history depth. Zero means no history array is available; shaders should fall back to `spectrum`. |
| `iSampleRate` | `float` | Audio sample rate in Hz (e.g. 44100). |
| `iChannelTime[4]` | `float[4]` | Playback time for each texture channel (Shadertoy-compatible). |
| `iChannelResolution[4]` | `vec3[4]` | Resolution of each texture channel. |

#### Color / Channel Controls

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

#### Effect / Animation Parameters

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
| `slider1` … `slider4` | `float` | Optional user controls exposed by the `rainbow_metal_code_*` family; their exact lighting, warp, and color mapping is shader-specific. |
| `seed`, `random_seed`, `random_var` | `float` / `vec4` | Seed inputs for hashed/randomized shaders. |
| `index_value` | `float` | Discrete index input (selector for palettes, modes, etc.). |
| `restore_black` | `float` | Toggle (0/1) used by the "strip black / restore black" pipeline so cropped letterboxing can be re-applied after a color-altering pass. |

#### 3-D / Geometry (rarely used)

A handful of shaders expect a model-view-projection setup for vertex transforms.

| Uniform | Type | Description |
|---------|------|-------------|
| `mv_matrix` | `mat4` | Model-view matrix. |
| `proj_matrix` | `mat4` | Projection matrix. |

## Compute Shaders (`compute/*.comp`)

The `compute/` directory is a separate collection of **182 image-processing compute shaders**. Every file targets GLSL 4.30, reads a source texture, and writes an opaque result directly to a binding-0 `rgba16f` image. Compute shaders are useful for effects that benefit from integer pixel addressing, shared workgroup memory, atomics, or explicit synchronization; they are not part of the fragment-shader manifests or uniform reference above.

### Compute families

| Family | Count | Workgroup | Description |
|--------|------:|-----------|-------------|
| `acidcam_000_*` – `acidcam_049_*` | 50 | 16×16 | Pixel, mirror, color, convolution, morphology, warp, noise, gradient, and temporal effects. |
| `acidcam_050_*` – `acidcam_099_*` | 50 | 16×16 | Digital glitches including datamoshing, packet loss, channel displacement, block corruption, scanline failure, address scrambling, and terminal-meltdown styles. |
| `acidcam_100_*` – `acidcam_149_*` | 50 | 16×16 | Channel sorting and shuffling, random-pixel and bar effects, strobe/XOR processing, RGB and mirror variants, line blending, and gradient corruption. |
| `code-compute-cache-*` | 25 | 8×8 | Cache-aware cooperative effects using shared tiles, barriers, reductions, scans, sorting, histograms, or atomics. Examples include optical-flow trails, reaction-diffusion memory, tile-histogram prism, bitonic luminance shuffle, and wavefront propagation. |
| Standalone utilities | 7 | 16×16 | `compute_blur`, `compute_temporal_blend_cache`, the `metalmedianblend_*` and `xorblend_*` pairs, and `square_block_resize_dir_cache`. |

Thirty-seven shaders are frame-cache-aware: eight `acidcam_000_*`–`acidcam_049_*` shaders, all 25 `code-compute-cache-*` shaders, and four standalone `_cache` utilities. The remaining 145 shaders use only the current source frame.

### Compute host interface

Every compute shader declares this core interface:

```glsl
#version 430 core

layout(local_size_x = 16, local_size_y = 16) in; // 8x8 for code-compute-cache-*
layout(rgba16f, binding = 0) writeonly uniform image2D outputImage;

uniform sampler2D samp;
```

Bind the current input texture to `samp` and a distinct `GL_RGBA16F` texture to image unit 0. Do not read from and write to the same texture in one dispatch. Every shader bounds-checks its global invocation against the output image size, so the host can round dispatch dimensions up to a whole workgroup:

```cpp
// Use 8 for both values when dispatching code-compute-cache-* shaders.
const GLuint localX = 16;
const GLuint localY = 16;
glDispatchCompute((width  + localX - 1) / localX,
                  (height + localY - 1) / localY,
                  1);
glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT |
                GL_TEXTURE_FETCH_BARRIER_BIT);
```

The barrier makes writes visible to later image operations and texture sampling. The 25 `code-compute-cache-*` shaders also synchronize invocations inside each 8×8 workgroup, so dispatch them with the workgroup size compiled into the shader.

Set only the optional uniforms declared by the selected file. Across the current collection these are `alpha` (152 shaders), `iFrame` (104), `time_f` (55), `iResolution` (10), and `iTime` (6). A uniform can occur alongside any of the others. `alpha` is effect-specific and may control blending, block size, thresholds, or general intensity rather than output transparency; all current compute shaders write alpha as 1.0.

### Compute frame history

The 37 cache-aware compute shaders support two compile-time frame-history representations. `SIZE` is the cache depth (default 8), and `USE_HISTORY_TEXTURE_ARRAY` selects the interface:

```glsl
#ifndef SIZE
#define SIZE 8
#endif

#ifndef USE_HISTORY_TEXTURE_ARRAY
#define USE_HISTORY_TEXTURE_ARRAY 0
#endif

#if USE_HISTORY_TEXTURE_ARRAY
uniform sampler2DArray history;
uniform int history_head;
#else
uniform sampler2D textures[SIZE];
#endif
```

- With `USE_HISTORY_TEXTURE_ARRAY=0` (the default), bind `textures[0]` through `textures[SIZE - 1]` in logical oldest-to-newest order.
- With `USE_HISTORY_TEXTURE_ARRAY=1`, bind the array texture to `history` and set `history_head` to the physical layer containing logical index 0, the oldest retained frame. Shaders map logical index `i` to `(history_head + i) % SIZE`.
- Compile `SIZE` to match the number of bound history entries. The cooperative `code-compute-cache-*` effects use at most the first eight logical history frames even when `SIZE` is larger.

The current input remains the separate `samp` texture and is not an additional history entry.

### Compute manifests

`compute/library.json` is the complete version-1 compute manifest and lists all 182 `.comp` files. The legacy `compute/index.txt` currently lists 82 files: `acidcam_000_*`–`acidcam_049_*`, the seven standalone utilities, and the 25 `code-compute-cache-*` shaders. It does not currently include `acidcam_050_*`–`acidcam_149_*`; use the JSON manifest or enumerate `compute/*.comp` when the complete collection is required. Files named `.shader_cache_*`, if present, are generated cache artifacts rather than shader sources.

## License

This shader collection is **free to use** and released under the **MIT License**. You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of these shaders in personal, educational, or commercial projects, provided that the original copyright notice and permission notice are included in all copies or substantial portions of the work.

The shaders are provided **"as is", without warranty of any kind**, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement.

See [LICENSE](LICENSE) for the full license text.
