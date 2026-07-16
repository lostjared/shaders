# GLSL Shader Collection

A collection of **2500+ OpenGL GLSL fragment shaders** for real-time video and image processing. These shaders are designed to be used as post-processing effects applied to live camera feeds, video textures, or generated visuals.

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
- **Spiral & swirl** — `spiral_wave`, `spiral_mirror`, `spiral-code-*`, `swirl_by_mouse`, `color_swirl_beautiful`, `gptswirl`, `g_swirl`
- **Page turn & fold** — `page_turn`, `fold`, `fold-mirror`, `fold-spin`, `tex_fold`

### Fractal & Mathematical
- **Fractal patterns** — `fractal`, `frac_shader01`–`frac_shader05`, `frac_zoom1`–`frac_zoom8`, `fractal-code-large-*`, `new_fractal`, `fractal_diamond_rainbow`
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
- **Water effects** — `water`, `water_full`, `water_rgb`, `water_hq_01`–`water_hq_25`, `waterbend`, `underwater`, `ocean`, `fold-water`
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

---

## Frame Cache & Spectrum History

### Frame Cache Uniforms (`samp1`–`samp8`)

The host maintains a rolling ring buffer of the most recently rendered frames and binds them to `samp1`–`samp8`:

| Uniform | Age | Meaning |
|---------|-----|----------|
| `samp` | 0 (now) | Current live frame |
| `samp8` | −1 | 1 frame ago (newest cache entry) |
| `samp7` | −2 | 2 frames ago |
| `samp6` | −3 | 3 frames ago |
| `samp5` | −4 | 4 frames ago |
| `samp4` | −5 | 5 frames ago |
| `samp3` | −6 | 6 frames ago |
| `samp2` | −7 | 7 frames ago |
| `samp1` | −8 | 8 frames ago (oldest cache entry) |

The cache is only populated when the host has texture caching enabled. In that mode, shaders can:
- **Stack ghost echoes** — blend `samp` through `samp8` at decreasing opacity.
- **Build feedback tunnels** — zoom/rotate before each cache lookup so older frames appear as receding rings.
- **Drive motion blur trails** — offset each cache layer along an audio-driven direction vector.
- **Detect movement** — subtract `samp8` from `samp` to isolate pixel change.

Convenience helper used by many shaders in this collection:
```glsl
vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(samp1, uv);
    // ... samp2 through samp8 ...
    return texture(samp8, uv);
}
```

### Spectrum History Uniforms (`spectrum0`–`spectrum7`)

In addition to the per-frame FFT exposed through `amp_*` scalars and `spectrum`, the host maintains a ring of 8 consecutive FFT frames:

| Uniform | Age | Meaning |
|---------|-----|----------|
| `spectrum0` | 0 (now) | Current frame's FFT spectrum |
| `spectrum1` | −1 | 1 FFT frame ago |
| `spectrum2` | −2 | 2 FFT frames ago |
| `spectrum3` | −3 | 3 FFT frames ago |
| `spectrum4` | −4 | 4 FFT frames ago |
| `spectrum5` | −5 | 5 FFT frames ago |
| `spectrum6` | −6 | 6 FFT frames ago |
| `spectrum7` | −7 | 7 FFT frames ago (oldest) |

Each is a `sampler1D` with `GL_R32F` internal format. Sample with a normalized frequency coordinate `[0, 1]`:
```glsl
float bass_now    = texture(spectrum0, 0.03).r;
float bass_oldest = texture(spectrum7, 0.03).r;
```

Common frequency landmarks (approximate, depends on FFT size and sample rate):

| Frequency coord | Approx. range | Band |
|----------------|---------------|------|
| 0.00 – 0.06 | < ~150 Hz | Sub-bass |
| 0.06 – 0.20 | ~150–500 Hz | Bass |
| 0.20 – 0.35 | ~500–1 kHz | Low-mid |
| 0.35 – 0.55 | ~1–3 kHz | Mid |
| 0.55 – 0.75 | ~3–8 kHz | Presence/treble |
| 0.75 – 1.00 | > ~8 kHz | Air/high-treble |

Convenience helper for reading any history slot:
```glsl
float specHist(int i, float freq) {
    if (i == 0) return texture(spectrum0, freq).r;
    if (i == 1) return texture(spectrum1, freq).r;
    // ... spectrum2 through spectrum7 ...
    return texture(spectrum7, freq).r;
}

// Accumulated energy across all 8 slots (useful for sustain detection)
float histEnergy(float freq) {
    float e = 0.0;
    for (int i = 0; i < 8; i++) e += specHist(i, freq);
    return e;
}
```

---

## New Shader Families (Added 2026)

### `ant_cache_spectrum8_*` series (25 shaders)
Audio-reactive shaders that combine an 8-frame texture cache (`samp1`–`samp8`) with per-slot FFT history (`spectrum0`–`spectrum7`). Each shader has a distinct visual theme but shares the same feedback architecture: the cache is used for zoom/rotate feedback layering and the spectrum history modulates per-layer hue shift, zoom depth, and rotation speed. All use `iTime` for smooth animation.

Members: `acid_rain`, `caustic_storm`, `chromatic_pulse`, `fractal`, `galaxy_swirl`, `glitch_storm`, `hex_grid`, `holographic`, `kaleidoscope`, `lava_flow`, `lightning`, `mandala`, `neon_grid`, `neural`, `oilslick`, `plasma`, `radial_echo`, `spectrum_rings`, `starburst`, `strobe_tunnel`, `tunnel`, `voronoi_pulse`, `vortex`, `warp_drive`, `zebra_wave`.

### `ant_peak_inversion_cache_spectrum_time_*` series (25 shaders)
Built on the same architecture as `ant_cache_spectrum8_*` but with effects tuned to be approximately 5× more intense. Historical FFT energy is accumulated across all 8 spectrum slots via `histEnergy()` and then used with large multipliers for zoom collapse, rotation snap, and color inversion. Uses `iTime`. Adds hard peak inversion (`mix(color, 1-color, ...)`) at `amp_peak` thresholds.

Members: `acid_rain_flood`, `caustic_drowning`, `chromatic_quake`, `fractal_inferno`, `galaxy_devourer`, `glitch_apocalypse`, `hex_seizure`, `hologram_collapse`, `hyperspace_tunnel`, `kaleidoscope_storm`, `lightning_god`, `magma_eruption`, `mandala_pulse`, `neon_grid_inferno`, `neural_overload`, `oilslick_meltdown`, `plasma_furnace`, `radial_echo_chamber`, `spectrum_visualizer`, `starburst_supernova`, `strobe_void`, `voronoi_seizure`, `vortex_singularity`, `warp_drive_overload`, `zebra_riot`.

### `ant_time_f_color_*` series (25 shaders)
A new family that makes the use of frame history and FFT history **visually obvious and structural** — the history is not just a subtle feedback modifier but the primary compositional device. Uses `time_f` (safe to use since the host now wraps at `65536 × 2π` rather than `2π`, preserving trig and `mod()` continuity). Each shader presents the 9 cache frames and/or 8 spectrum slots as explicit visible elements:

| Shader | How history is shown |
|--------|----------------------|
| `ringbuffer_spiral` | 9 spiral arms, each sampling a different cache frame |
| `echo_chamber` | 8 ghost copies of past frames offset in an audio-driven ring |
| `spectrum_waterfall` | y-axis = age; top row = `spectrum0` (now), bottom = `spectrum7` |
| `timeline_strips` | Screen divided into 9 vertical strips, one per cache frame |
| `trail_blaze` | Motion-blur trail through all 9 frames along an audio path |
| `ghost_train` | 8 ghosts marching across the screen at different speeds |
| `memory_kaleidoscope` | Pie-slice kaleidoscope where each slice = different cache frame |
| `tunnel_recall` | Concentric rings, one ring per cache frame, with visible borders |
| `fft_aurora` | 8 aurora curtain bands, one per `spectrum0`–`spectrum7` |
| `shutter_burst` | 3×3 grid showing all 9 cache frames simultaneously |
| `polar_history` | Clock-face wedges: angle = age, radius = FFT frequency |
| `radial_smear` | Concentric rings of cache frames blended outward |
| `crosshatch_recall` | 3×3 grid cells with per-cell FFT history overlay bar |
| `afterimage_burn` | max-blend of all 9 frames for a long-exposure burn-in look |
| `quantum_freeze` | Random per-tile pick from 9 cache frames |
| `light_painting` | Additive long-exposure trail across all cache frames |
| `bass_pulse_rings` | 8 expanding rings; each ring's brightness = bass history at that age |
| `glitch_archive` | Scanline bands snap to different cache frames at audio intervals |
| `data_stream` | 8 vertical columns, each scrolling one `spectrum*` slot |
| `parallax_layers` | 9 depth planes scrolling at speeds proportional to their age |
| `mirror_corridor` | 8 receding mirror planes, each showing an older cache frame |
| `timeline_swirl` | Spiral where angle encodes age and radius encodes FFT frequency |
| `acid_smear` | Each cache frame distorted by its matching `spectrum*` waveform |
| `spectrogram_paint` | Full 2-D spectrogram (x = frequency, y = age 0–7) |
| `holo_replay` | 9 transparent holographic layers with chromatic aberration per layer |

### Additional 2026 shader families

These newer families extend the collection with high-detail, audio-reactive, cache-driven, and gameplay-oriented effects. The filename prefix identifies the shared rendering approach; the remainder of each name describes that shader's visual theme.

| Family | Count | Description |
|--------|------:|-------------|
| `ant_texture_cache_spectrum_scale_*` | 25 | Scalable trail-cache effects that read `textures[SIZE]` instead of a fixed eight-frame cache. FFT history controls the scale, color, displacement, and persistence of themes such as `chromatic`, `comet`, `ghost`, `kaleido`, `neon_trail`, `tunnel`, and `vortex`. |
| `code-frac-*` | 25 | Audio-reactive recursive folds and kaleidoscopic fractal texture remixes. Members range from `aurora-vault` and `crystal-tunnel` to `prism-wormhole` and `zero-gravity-fold`. |
| `code-frac-x-*` | 25 | Higher-detail fractal variants built for large displays, with derivative-filtered Julia fields, log-polar singularities, recursive geometry, chromatic refraction, and audio-driven motion. |
| `code-mirror-*` | 25 | Mirror tiling, radial reflection, kaleidoscopic folding, and animated refraction combined with themed palettes and audio response. Examples include `aurora-corridor`, `echo-temple`, `glass-tesseract`, and `vortex-gallery`. |
| `code-update-*` | 25 | Compact spectrum-reactive effects with distinct procedural scenes—ribbons, lattices, stained glass, ferrofluid, reefs, nebulae, and wormholes—plus peak-triggered flashes or inversion. |
| `codex_*` | 45 | Experimental effects split into several groups: four cartoon/cel/VHS looks; ten `codex_glitch_*` fractal glitches; ten `codex_grad_fractal_*` palette-heavy fractals; ten `codex_vhs_*` tape simulations; and standalone aura, chrome, mosaic, prism, topography, echo, and signal-decay effects. Variants use time and, where appropriate, mouse control. |
| `fractal-code-large-*` | 25 | Large-format, alpha-preserving fractal overlays. Three recursive folds, kaleidoscopic geometry, derivative-aware sampling, chromatic separation, and soft-light compositing keep the source visible while `iMouse` and the `amp_*` audio bands animate themes such as `aurora-veil`, `liquid-cathedral`, `ocean-mandala`, `rainbow-glass`, and `temporal-gem`. |
| `game_codex_*` | 20 | Readable gameplay overlays for recognizable events and states, including target lock, radar ping, critical hit, shield hit, low ammo, power-up, speed boost, stealth, underwater depth, and elemental damage. |
| `inthesky_cache_*` | 10 | Celestial frame-history compositions that layer `samp1`–`samp8` with FFT history to form auroras, cloud architecture, solar pillars, storm crowns, and mirrored skies. |
| `inv_cache_code_*` | 10 | Cache-driven perceptual fields inspired by afterimages, phosphenes, peripheral drift, entoptic patterns, and dreamlike visual persistence. |
| `inversion_code_cache_*` | 25 | Temporal inversion energy fields. Cached frames and spectrum history are folded into scientific and abstract structures such as charge maps, flux lattices, moiré tensors, quasicrystals, plasma filaments, and quantum foam. |
| `kale_code_*` | 15 | Nested, multi-domain kaleidoscopes with recursive folds, mirrored sampling, chromatic refraction, and audio-reactive segment counts or motion. |
| `liquid_code_*` | 5 | Fluid metallic warps (`chrome_nautilus`, `iridescent_whirlpool`, `mercury_vortex`, `molten_helix`, and `silver_riptide`) using noise fields, thin-film color, and audio-responsive lighting. |
| `metal-code-*` | 10 | Procedural metallic surfaces with animated height fields, reflected texture sampling, iridescence, and physically inspired highlights. |
| `rainbow-code-*` | 10 | High-detail spectral materials and distortions: aurora silk, chromatic ribbons, diamond waves, holographic facets, liquid pearl, opal vortices, caustics, bloom, and stained-glass kaleidoscopes. |
| `rainbow_metal_code_*` | 25 | Audio-reactive rainbow metal with procedural normals, spectral lighting, and optional `slider1`–`slider4` controls. Themes include chrome, mercury, liquid mandalas, magnetic opal, radiant helixes, and foundry effects. |
| `spiral-code-*` | 25 | Time-animated spiral and polar-coordinate texture transformations. Mirrored sampling, tunnels, coils, helixes, kaleidoscopic folds, chromatic splits, and themed highlights produce effects such as `chromatic-tunnel`, `fractal-coil`, `galaxy-vortex`, `nautilus-glass`, and `prism-cyclone`. These require only `samp` and `time_f`. |
| `twist-code-*` | 25 | Animated polar and radial tunnel warps, ranging from double helices and augers to gravity wells, shockwaves, turbines, and singularities. |
| `vhs-code-*` | 11 | Focused analog-tape artifacts including chroma bleed, RF noise, dropout, ghosting, head switching, pause jitter, tracking roll, tape warp, worn tape, and stylized home-movie/Kung Fury looks. |
| `water_hq_*` | 25 | High-quality, time-animated water refraction effects that preserve the input alpha and use mirrored UVs for safe edge sampling. The numbered set covers caustic shallows, ocean swell, rain ripples, glass refraction, currents, whirlpools, droplet lenses, shoreline, storm water, waterfall, and coral-lagoon looks using only `samp` and `time_f`. |
| `xor_code_*` | 15 | Byte-level XOR color transforms combined with procedural spatial masks. Includes bit-plane, halftone, circuit, kaleidoscope, feedback, solarized, and smooth pastel/prismatic variants. |

### Other recent additions

| Shaders | Description |
|---------|-------------|
| `blend_orig_10_cache`, `blend_orig_25_cache`, `blend_orig_50_cache`, `blend_orig_75_cache` | Blend the live frame with `textures[0]` at fixed 10%, 25%, 50%, or 75% strengths. |
| `af_scale_pulse`, `ant_gem_metal_pulse_mouse` | A pulsing audio-frequency scale effect and a mouse-positioned metallic `ant_gem` pulse variant. |
| `echo_cache` | Builds a diagonally offset echo by repeatedly blending the fixed frame-history samplers. |
| `fill_black`, `fill_black_fold` | Black-fill compositors; the fold variant combines the fill with mirrored/folded sampling. |
| `fractal_texture_large-nowrap`, `fractal_texture_large_spectrum` | Large-format fractal texture effects, with a non-wrapping variant and an FFT-reactive variant. |
| `hallu_code_abyssal_opaline`, `hallu_code_vesper_xenolith` | Audio-reactive hallucinatory fields with mirrored UVs, layered noise, opaline color, and deep procedural geometry. |
| `brightness_increase`, `grad_color`, `shift_grad`, `remove_flicker` | Utility color processors for brightness, gradient color, gradient shifting, and luminance-based flicker reduction. |
| `mirror-wrap-scale`, `pond`, `tunnel_x` | A scaled mirror-wrap, an extreme mouse/audio/cache-driven water ripple, and a tunnel distortion. |
| `vhs-color-mode` | A sharpened cyan-shadow/magenta-highlight VHS grade with chroma styling and analog noise. |

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
| `samp1` … `samp8` | `sampler2D` | **Frame history ring buffer.** When the texture cache is enabled the host fills these as a rolling window of the 8 most-recently rendered frames: `samp1` = oldest (furthest back in time), `samp8` = newest (most recent previous frame), `samp` = the current live frame. Shaders can build motion-blur trails, persistent ghost echoes, feedback tunnels, and other time-layered effects by sampling across this ring. See *Frame Cache Uniforms* below. |
| `textures[SIZE]` | `sampler2D[]` | Configurable frame-cache array used by `ant_texture_cache_spectrum_scale_*` and `blend_orig_*_cache`. `SIZE` is supplied by the host/build configuration (the shader fallback is usually 8). |
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
| `spectrum0` … `spectrum7` | `sampler1D` | **FFT history ring.** Eight 1-D spectrum textures capturing recent FFT frames: `spectrum0` = the current frame's spectrum (newest), `spectrum7` = the oldest stored spectrum. Each texture contains `FFT_SIZE/2` red-channel texels in `[0, 1]` representing normalized magnitude per frequency bin. Shaders can compare current and historical spectra to detect transients, build spectrograms, or drive effects whose intensity depends on how long a band has been active. See *Spectrum History Uniforms* below. |
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
| `slider1` … `slider4` | `float` | Optional user controls exposed by the `rainbow_metal_code_*` family; their exact lighting, warp, and color mapping is shader-specific. |
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

This shader collection is **free to use** and released under the **MIT License**. You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of these shaders in personal, educational, or commercial projects, provided that the original copyright notice and permission notice are included in all copies or substantial portions of the work.

The shaders are provided **"as is", without warranty of any kind**, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement.

See [LICENSE](LICENSE) for the full license text.
