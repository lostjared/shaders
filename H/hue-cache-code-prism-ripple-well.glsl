#version 330 core
// hue-cache-code-prism-ripple-well
// Concentric prism well with displaced rings and deep zooming memories.
// Left drag: primary origin. Right drag: effect rotation/scale and feedback flow.

#define EFFECT_ID 1

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float RIGHT_TURN = 0.80;
const float RIGHT_SCALE = 0.72;
const float HUE_OFFSET = 0.20;
const int FEEDBACK_STYLE = 2;

mat2 rotate_2d(float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirror_repeat(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

float hash_21(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float noise_21(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point);
    part = part * part * (3.0 - 2.0 * part);
    return mix(mix(hash_21(cell), hash_21(cell + vec2(1.0, 0.0)), part.x),
               mix(hash_21(cell + vec2(0.0, 1.0)),
                   hash_21(cell + vec2(1.0, 1.0)), part.x), part.y);
}

vec2 voronoi_edges(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point);
    float nearest = 8.0;
    float second_nearest = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 random_point = vec2(hash_21(cell + offset),
                                     hash_21(cell + offset + 5.17));
            float distance_to_point = length(offset + random_point - part);
            if (distance_to_point < nearest) {
                second_nearest = nearest;
                nearest = distance_to_point;
            } else if (distance_to_point < second_nearest) {
                second_nearest = distance_to_point;
            }
        }
    }
    return vec2(nearest, second_nearest);
}

vec2 hex_cell(vec2 point) {
    vec2 scale = vec2(1.0, 1.7320508);
    vec2 first = mod(point, scale) - scale * 0.5;
    vec2 second = mod(point - scale * 0.5, scale) - scale * 0.5;
    return dot(first, first) < dot(second, second) ? first : second;
}

vec2 kaleidoscope(vec2 point, float sides) {
    float radius = length(point);
    float sector = TAU / max(sides, 2.0);
    float angle = abs(mod(atan(point.y, point.x) + sector * 0.5, sector) -
                      sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec3 acid_palette(float phase) {
    vec3 target = vec3(0.3647, 0.0275, 0.4549);
    vec3 oscillation = 0.5 + 0.5 *
                       cos(TAU * (phase + HUE_OFFSET +
                           vec3(0.00, 0.13, 0.27)));
    return target * (0.45 + oscillation * 1.25) +
           vec3(0.12, 0.01, 0.18) * oscillation;
}

vec3 hue_rotate(vec3 value, float angle) {
    vec3 axis = normalize(vec3(1.0));
    return value * cos(angle) + cross(axis, value) * sin(angle) +
           axis * dot(axis, value) * (1.0 - cos(angle));
}

uvec3 color_bytes(vec3 value) {
    return uvec3(clamp(floor(value * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xor_color(vec3 first, vec3 second) {
    return vec3((color_bytes(first) ^ color_bytes(second)) & uvec3(255u)) /
           255.0;
}

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    if (index == 0)
        return texture(samp1, uv);
    if (index == 1)
        return texture(samp2, uv);
    if (index == 2)
        return texture(samp3, uv);
    if (index == 3)
        return texture(samp4, uv);
    if (index == 4)
        return texture(samp5, uv);
    if (index == 5)
        return texture(samp6, uv);
    if (index == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

float sample_history(int index, float frequency) {
    if (index == 0)
        return texture(spectrum1, frequency).r;
    if (index == 1)
        return texture(spectrum2, frequency).r;
    if (index == 2)
        return texture(spectrum3, frequency).r;
    if (index == 3)
        return texture(spectrum4, frequency).r;
    if (index == 4)
        return texture(spectrum5, frequency).r;
    if (index == 5)
        return texture(spectrum6, frequency).r;
    return texture(spectrum7, frequency).r;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    float bass = texture(spectrum0, 0.03).r;
    float middle = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    vec2 mouse_control = clamp(iMouse.xy / resolution, 0.0, 1.0);
    float left_down = step(0.5, iMouse.z);
    float right_down = step(0.5, iMouse.w);
    vec2 center = mix(vec2(0.5), mouse_control, left_down);
    float manual_axis = (mouse_control.x - 0.5) * 2.0 * right_down;
    float manual_amount = (mouse_control.y - 0.5) * 2.0 * right_down;

    vec2 point = (tc - center) * vec2(aspect, 1.0);
    point = rotate_2d(manual_axis * RIGHT_TURN) * point;
    point *= max(0.18, 1.0 + manual_amount * RIGHT_SCALE);

    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    vec2 radial_direction = point / radius;
    vec2 effect_point = point;
    float field = 0.0;
    float feature = 0.0;

    float ring = sin(radius * (38.0 + middle * 20.0) - time_f * 7.0);
    float well = 1.0 / (0.72 + radius * (1.4 + bass));
    effect_point = rotate_2d(ring * 0.08) * point * well;
    field = ring;
    feature = pow(abs(ring), 12.0) * exp(-radius * 0.9);
    effect_point += radial_direction * ring * 0.035;

    vec2 mapped = mirror_repeat(effect_point / vec2(aspect, 1.0) + center);
    vec2 chroma_direction = effect_point /
                            (length(effect_point) + 0.0001);
    float chroma = 0.006 + abs(field) * 0.012 + treble * 0.025;
    vec3 live_color;
    live_color.r = texture(samp, mirror_repeat(mapped +
                           chroma_direction * chroma)).r;
    live_color.g = texture(samp, mapped).g;
    live_color.b = texture(samp, mirror_repeat(mapped -
                           chroma_direction * chroma)).b;

    live_color = hue_rotate(live_color, time_f * 0.45 + HUE_OFFSET +
                            field * 0.24);
    live_color *= acid_palette(field * 0.13 + time_f * 0.035) *
                  (1.15 + bass * 0.40);
    live_color += acid_palette(radius - time_f * 0.08) * feature *
                  (0.24 + air * 0.65);

    vec3 accumulated = live_color;
    float total_weight = 1.0;
    for (int layer = 0; layer < 8; ++layer) {
        float generation = float(layer + 1);
        float historical_bass = sample_history(layer, 0.03);
        float historical_middle = sample_history(layer, 0.22);
        float historical_treble = sample_history(layer, 0.58);
        vec2 cache_uv = tc - center;

        if (FEEDBACK_STYLE == 0) {
            float zoom = clamp(0.965 - historical_bass * 0.065 +
                               manual_amount * 0.055, 0.84, 1.08);
            cache_uv = rotate_2d(generation *
                       (0.018 + historical_treble * 0.085 +
                        manual_axis * 0.025)) * cache_uv;
            cache_uv *= pow(zoom, generation);
        } else if (FEEDBACK_STYLE == 1) {
            cache_uv.x = abs(cache_uv.x) - 0.02 * generation;
            cache_uv = rotate_2d(generation * (0.012 + manual_axis * 0.018)) *
                       cache_uv;
            cache_uv *= 0.98 - historical_bass * 0.035;
        } else if (FEEDBACK_STYLE == 2) {
            float cache_radius = length(cache_uv) + 0.0001;
            cache_uv += cache_uv / cache_radius *
                        sin(cache_radius * 24.0 - time_f * 4.0 +
                            generation) * (0.003 * generation);
            cache_uv *= 0.975 - historical_bass * 0.035 +
                        manual_amount * 0.035;
        } else if (FEEDBACK_STYLE == 3) {
            float row = floor((cache_uv.y + 0.5) * 42.0);
            cache_uv.x += (hash_21(vec2(row, generation)) - 0.5) *
                          (0.006 * generation + historical_treble * 0.025);
            cache_uv.y += sin(generation + time_f * 0.3) * 0.003;
        } else {
            float blocks = 56.0 - generation * 3.0;
            cache_uv = (floor((cache_uv + 0.5) * blocks) + 0.5) / blocks -
                       0.5;
            cache_uv = rotate_2d(manual_axis * generation * 0.018) * cache_uv;
            cache_uv *= 0.98 - historical_bass * 0.025;
        }

        cache_uv += center;
        vec3 cached = sample_cache(layer, cache_uv).rgb;
        cached = hue_rotate(cached, historical_treble * 0.32 +
                            generation * HUE_OFFSET * 0.018);
        cached = mix(cached, cached *
                     acid_palette(historical_middle + generation * 0.07) * 1.5,
                     0.18 + generation * 0.035);
        float weight = pow(0.78, generation);
        accumulated += cached * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    float average = dot(result, vec3(0.333333));
    result = mix(vec3(average), result, 1.30);
    result = (result - 0.5) * (1.20 + amp_smooth * 0.22) + 0.48;
    result = max(result, 0.0);
    result = result / (1.0 + result);
    result = mix(result, vec3(1.0) - result,
                 smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
