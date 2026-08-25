#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// darkstar-spectrum-trail-cache-obsidian-prism
// Dark prismatic facets driven by low-mid spectral pressure.
#define STYLE_ID 2
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif




const float PI = 3.14159265359;
const float TAU = 6.28318530718;

mat2 rotate_2d(float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec2 mirror_gradient(vec2 uv, vec2 screen_gradient) {
    vec2 periodic_gradient = screen_gradient - round(screen_gradient * 0.5) * 2.0;
    vec2 direction = vec2(1.0) - 2.0 * step(vec2(1.0), mod(uv, 2.0));
    return periodic_gradient * direction;
}

vec4 sample_live(vec2 uv) {
    vec2 gradient_x = mirror_gradient(uv, dFdx(uv));
    vec2 gradient_y = mirror_gradient(uv, dFdy(uv));
    return textureGrad(samp, mirror_repeat(uv), gradient_x, gradient_y);
}

vec4 sample_cache(vec2 uv, int index) {
    vec2 gradient_x = mirror_gradient(uv, dFdx(uv));
    vec2 gradient_y = mirror_gradient(uv, dFdy(uv));
    float layer = float(CACHE_HISTORY_LAYER(index));
    return textureGrad(history, vec3(mirror_repeat(uv), layer), gradient_x, gradient_y);
}

float spectrum_band(float center, float width) {
    float left = texture(spectrum0, clamp(center - width, 0.0, 1.0)).r;
    float middle = texture(spectrum0, clamp(center, 0.0, 1.0)).r;
    float right = texture(spectrum0, clamp(center + width, 0.0, 1.0)).r;
    return (left + middle * 2.0 + right) * 0.25;
}

float history_band(int index, float center, float width) {
    float layer = float(SPECTRUM_HISTORY_LAYER(index + 1));
    float left = texture(spectrum_history, vec2(clamp(center - width, 0.0, 1.0), layer)).r;
    float middle = texture(spectrum_history, vec2(clamp(center, 0.0, 1.0), layer)).r;
    float right = texture(spectrum_history, vec2(clamp(center + width, 0.0, 1.0), layer)).r;
    return (left + middle * 2.0 + right) * 0.25;
}

vec3 palette(float phase) {
    float style_hue = float(STYLE_ID) * 0.083;
    return 0.5 + 0.5 * cos(TAU * (phase + style_hue + vec3(0.02, 0.35, 0.68)));
}

vec3 tone_map(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) /
                     (value * (2.43 * value + 0.59) + 0.14),
                 0.0, 1.0);
}

vec2 rotate_uv(vec2 uv, float angle, vec2 center, float aspect) {
    vec2 point = (uv - center) * vec2(aspect, 1.0);
    point = rotate_2d(angle) * point;
    return point / vec2(aspect, 1.0) + center;
}

vec2 kaleidoscope_uv(vec2 uv, float segments, vec2 center, float aspect) {
    vec2 point = (uv - center) * vec2(aspect, 1.0);
    float radius = length(point);
    float sector = TAU / segments;
    float angle = abs(mod(atan(point.y, point.x) + sector * 0.5, sector) - sector * 0.5);
    point = vec2(cos(angle), sin(angle)) * radius;
    return point / vec2(aspect, 1.0) + center;
}

vec2 diamond_fold(vec2 uv, vec2 center, float aspect) {
    vec2 point = abs((uv - center) * vec2(aspect, 1.0));
    if (point.y > point.x) point = point.yx;
    return point / vec2(aspect, 1.0) + center;
}

vec2 fractal_fold(vec2 uv, vec2 center, float aspect, float zoom,
                  float bass, float middle) {
    vec2 point = uv;
    for (int iteration = 0; iteration < 3; ++iteration) {
        float phase = time_f * (0.23 + bass * 0.24) + float(iteration) * 1.7;
        point = abs((point - center) * (zoom + sin(phase) * (0.08 + middle * 0.13))) -
                0.5 + center;
        point = rotate_uv(point, time_f * 0.07 + float(iteration) * 0.11,
                          center, aspect);
    }
    return point;
}

vec2 style_warp(vec2 uv, vec2 center, float aspect, float sub, float bass,
                float low_mid, float middle, float presence, float high,
                float air, float flux) {
    vec2 point = (uv - center) * vec2(aspect, 1.0);
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);

#if STYLE_ID == 0
    point = abs(point);
    if (point.y > point.x) point = point.yx;
    point *= 1.0 + sin(radius * (12.0 + bass * 15.0) - time_f * 2.7) *
                         (0.08 + sub * 0.18);
#elif STYLE_ID == 1
    float petals = 7.0 + floor(middle * 7.0);
    float sector = TAU / petals;
    float folded_angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    radius *= 1.0 + cos(folded_angle * petals * 2.0 + time_f) *
                        (0.12 + low_mid * 0.2);
    point = vec2(cos(folded_angle), sin(folded_angle)) * radius;
#elif STYLE_ID == 2
    point = rotate_2d(PI * 0.25 + presence * 0.2) * point;
    point = abs(point);
    point = vec2(point.x + point.y, abs(point.x - point.y)) * 0.72;
    point += sin(point.yx * (9.0 + high * 12.0) + time_f) * (0.015 + flux * 0.06);
#elif STYLE_ID == 3
    point = rotate_2d(log(radius + 0.035) * (0.45 + bass * 0.8) -
                      time_f * (0.12 + low_mid * 0.16)) * point;
    point *= 1.0 + sin(log(radius + 0.02) * 13.0 - time_f * 2.0) *
                         (0.06 + sub * 0.14);
#elif STYLE_ID == 4
    float jet = pow(abs(cos(angle * 2.0)), 9.0);
    point.x += sign(point.x) * jet * (0.08 + presence * 0.22);
    point.y += sin(point.x * (11.0 + high * 9.0) - time_f * 3.0) *
               (0.025 + air * 0.08);
#elif STYLE_ID == 5
    for (int iteration = 0; iteration < 4; ++iteration) {
        point = abs(point) / max(dot(point, point), 0.12) -
                vec2(0.72 + bass * 0.12, 0.54 + middle * 0.11);
        point = rotate_2d(0.31 + presence * 0.14) * point;
    }
    point *= 0.17 + flux * 0.05;
#elif STYLE_ID == 6
    point.x += sin(point.y * (10.0 + middle * 11.0) - time_f * 1.7) *
               (0.035 + low_mid * 0.1);
    point.y += cos(point.x * (9.0 + high * 13.0) + time_f * 1.3) *
               (0.03 + air * 0.09);
    point = rotate_2d(sin(radius * 8.0 - time_f) * (0.08 + bass * 0.16)) * point;
#elif STYLE_ID == 7
    float petals = 8.0 + floor(presence * 6.0);
    float sector = TAU / petals;
    float folded_angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    float lotus = sin(radius * (17.0 + high * 15.0) - time_f * 3.4);
    radius *= 1.0 + lotus * (0.07 + bass * 0.12);
    point = vec2(cos(folded_angle), sin(folded_angle)) * radius;
#elif STYLE_ID == 8
    float shock = sin(radius * (24.0 + bass * 18.0) - time_f * (4.0 + flux * 3.0));
    point *= 1.0 + shock * (0.04 + sub * 0.16);
    point = rotate_2d(shock * (0.05 + presence * 0.12)) * point;
#else
    vec2 chamber = abs(fract(point * (3.0 + floor(middle * 5.0))) - 0.5);
    point += (chamber.yx - 0.25) * (0.08 + high * 0.16);
    point = rotate_2d(floor(radius * (8.0 + bass * 6.0)) * PI * 0.25 +
                      time_f * 0.04) * point;
#endif

    return point / vec2(aspect, 1.0) + center;
}

vec2 darkstar_wrap(vec2 uv, vec2 center, float aspect, float sub, float bass,
                   float middle, float high, float flux) {
    vec2 point = (uv - center) * vec2(aspect, 1.0);
    vec2 diamond = abs(point);
    if (diamond.y > diamond.x) diamond = diamond.yx;

    float radius = max(diamond.x, diamond.y) + 0.006;
    float period = 0.32 + bass * 0.26 + middle * 0.12;
    float travel = time_f * (0.28 + sub * 0.34 + flux * 0.18);
    float shell = fract((log(radius) - travel) / period);
    float wrapped_radius = exp(shell * period) * (0.32 + bass * 0.09);
    float angle = atan(diamond.y, diamond.x) + travel * 0.37 +
                  sin(radius * (17.0 + high * 13.0) + time_f) *
                      (0.16 + middle * 0.2);
    vec2 wrapped = vec2(cos(angle), sin(angle)) * wrapped_radius;
    return wrapped / vec2(aspect, 1.0) + center;
}

vec3 soft_live(vec2 uv, vec2 texel, float spread) {
    vec3 result = sample_live(uv).rgb * 4.0;
    result += sample_live(uv + vec2(texel.x, 0.0) * spread).rgb * 2.0;
    result += sample_live(uv - vec2(texel.x, 0.0) * spread).rgb * 2.0;
    result += sample_live(uv + vec2(0.0, texel.y) * spread).rgb * 2.0;
    result += sample_live(uv - vec2(0.0, texel.y) * spread).rgb * 2.0;
    return result / 12.0;
}

vec2 trail_transform(vec2 uv, vec2 center, float aspect, float progress,
                     float old_sub, float old_bass, float old_middle,
                     float old_high, float old_air) {
    vec2 point = (uv - center) * vec2(aspect, 1.0);
    float shrink = 1.0 + progress * (0.38 + old_sub * 1.4 + old_bass * 0.8);
    point *= shrink;

#if STYLE_ID % 5 == 0
    point = rotate_2d(progress * (0.08 + old_high * 0.7) * sin(time_f * 0.4)) * point;
    point += normalize(point + vec2(0.001)) * old_bass * progress * 0.08;
#elif STYLE_ID % 5 == 1
    point.x += sin(point.y * (8.0 + old_middle * 12.0) + progress * TAU) *
               progress * (0.025 + old_air * 0.08);
    point.y += cos(point.x * 7.0 - progress * TAU) * old_high * progress * 0.05;
#elif STYLE_ID % 5 == 2
    float radius = length(point) + 0.001;
    point = rotate_2d(sin(radius * 14.0 - time_f) * progress *
                      (0.08 + old_middle * 0.2)) * point;
#elif STYLE_ID % 5 == 3
    point.x *= 1.0 + progress * old_middle * 0.25;
    point.y *= 1.0 - progress * old_high * 0.12;
    point += vec2(old_air, old_bass) * progress * 0.045;
#else
    float radius = length(point) + 0.001;
    vec2 tangent = vec2(-point.y, point.x) / radius;
    point += tangent * progress * (0.035 + old_high * 0.16);
    point += normalize(point + vec2(0.001)) * sin(radius * 19.0 + time_f) *
             old_bass * progress * 0.05;
#endif

    return point / vec2(aspect, 1.0) + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 texel = 1.0 / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);

    float sub = spectrum_band(0.018, 0.012);
    float bass = spectrum_band(0.055, 0.025);
    float low_mid = spectrum_band(0.14, 0.04);
    float middle = spectrum_band(0.29, 0.055);
    float presence = spectrum_band(0.47, 0.06);
    float high = spectrum_band(0.68, 0.055);
    float air = spectrum_band(0.87, 0.045);

    float previous_sub = history_band(0, 0.018, 0.012);
    float previous_mid = history_band(0, 0.29, 0.055);
    float previous_high = history_band(0, 0.68, 0.055);
    float flux = clamp(abs(sub - previous_sub) * 1.5 +
                       abs(middle - previous_mid) +
                       abs(high - previous_high) * 0.8, 0.0, 1.5);
    float energy = sub * 0.24 + bass * 0.22 + low_mid * 0.17 +
                   middle * 0.15 + presence * 0.1 + high * 0.08 + air * 0.04;

    float segments = 4.0 + float(STYLE_ID % 5) + floor(middle * 7.0);
    vec2 warped_uv = kaleidoscope_uv(tc, segments, center, aspect);
    warped_uv = diamond_fold(warped_uv, center, aspect);
    float fold_zoom = 1.08 + sub * 0.38 + bass * 0.28 + flux * 0.11;
    warped_uv = fractal_fold(warped_uv, center, aspect, fold_zoom, bass, middle);
    warped_uv = style_warp(warped_uv, center, aspect, sub, bass, low_mid,
                           middle, presence, high, air, flux);
    warped_uv = darkstar_wrap(warped_uv, center, aspect, sub, bass, middle,
                              high, flux);

    vec2 direction = normalize((warped_uv - center) * vec2(aspect, 1.0) + vec2(0.001));
    vec2 chroma_offset = direction * vec2(1.0 / aspect, 1.0) *
                         (0.002 + presence * 0.008 + air * 0.016 + flux * 0.006);
    float blur_spread = 1.0 + low_mid * 2.5;
    vec3 red_sample = soft_live(warped_uv + chroma_offset, texel, blur_spread);
    vec3 green_sample = soft_live(warped_uv, texel, blur_spread);
    vec3 blue_sample = soft_live(warped_uv - chroma_offset, texel, blur_spread);
    vec3 kaleido = vec3(red_sample.r, green_sample.g, blue_sample.b);

    vec3 base = sample_live(tc).rgb;
    float radial = length((tc - center) * vec2(aspect, 1.0));
    float spectral_ring = 0.5 + 0.5 * sin(log(radial + 0.025) *
                          (10.0 + middle * 13.0) - time_f *
                          (2.0 + bass * 3.0));
    float live_mix = clamp(0.52 + energy * 0.32 + flux * 0.22, 0.0, 0.94);
    vec3 live = mix(base, kaleido, live_mix);
    live *= 0.72 + spectral_ring * (0.28 + presence * 0.32);
    live += palette(spectral_ring * 0.18 + time_f * 0.035 + high) *
            pow(spectral_ring, 8.0) * (0.04 + flux * 0.3);

    vec3 trail_accum = vec3(0.0);
    float trail_weight = 0.0;
    for (int index = 0; index < SIZE; ++index) {
        float progress = float(index + 1) / float(max(SIZE, 1));
        float old_sub = history_band(index, 0.018, 0.012);
        float old_bass = history_band(index, 0.055, 0.025);
        float old_middle = history_band(index, 0.29, 0.055);
        float old_high = history_band(index, 0.68, 0.055);
        float old_air = history_band(index, 0.87, 0.045);
        vec2 history_uv = trail_transform(warped_uv, center, aspect, progress,
                                          old_sub, old_bass, old_middle,
                                          old_high, old_air);
        vec3 cached = sample_cache(history_uv, index).rgb;
        float old_energy = old_sub * 0.32 + old_bass * 0.25 +
                           old_middle * 0.22 + old_high * 0.13 + old_air * 0.08;
        vec3 tint = palette(float(STYLE_ID) * 0.07 + progress * 0.62 +
                            old_middle * 0.5 + old_high * 0.28);
        float weight = exp(-progress * (2.6 + high * 0.8)) *
                       (0.72 + old_energy * 0.5);
        trail_accum += mix(cached, cached * tint, 0.42 + progress * 0.4) * weight;
        trail_weight += weight;
    }

    vec3 trail = trail_accum / max(trail_weight, 0.001);
    trail *= 0.45 + bass * 0.22 + middle * 0.13;
    vec3 result = live + trail - live * trail;
    result += palette(energy * 0.6 + time_f * 0.06) * flux * 0.18;
    result = (result - 0.5) * (1.04 + presence * 0.2 + flux * 0.1) + 0.5;

    color = vec4(tone_map(result), sample_live(tc).a);
}
