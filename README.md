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

## Common Uniforms

These shaders typically expect the following GLSL uniforms:

| Uniform | Type | Description |
|---------|------|-------------|
| `iResolution` | `vec2`/`vec3` | Viewport resolution in pixels |
| `iTime` / `time_f` | `float` | Elapsed time in seconds |
| `iMouse` | `vec2`/`vec4` | Mouse position |
| `samp` / `iChannel0` | `sampler2D` | Input texture (camera/video) |

## License

See [LICENSE](LICENSE) for details.
