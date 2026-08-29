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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

// rainbow_trail_kaleidoscope
// Folded cache frames form a mirrored rainbow strobe mandala.
#define TRAIL_MODE 3
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









const float TAU = 6.28318530718;
const int MODE = TRAIL_MODE;

mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec2 seamlessUV(vec2 uv) {
    vec2 mirrored = mirrorUV(uv);
    vec2 cosineFold = 0.5 - 0.5 * cos(3.14159265359 * uv);
    vec2 edgeDistance = min(mirrored, 1.0 - mirrored);
    vec2 feather = 1.0 - smoothstep(vec2(0.015), vec2(0.08), edgeDistance);
    return mix(mirrored, cosineFold, feather);
}

vec2 kaleido(vec2 p, float sides) {
    float radius = length(p);
    float sector = TAU / sides;
    float angle = abs(mod(atan(p.y, p.x) + sector * 0.5, sector) - sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec3 rainbow(float x) {
    float offset = float(MODE) * 0.087;
    return 0.52 + 0.48 * cos(TAU * (x + offset + vec3(0.0, 0.333, 0.667)));
}

vec3 hueRotate(vec3 c, float angle) {
    const mat3 toYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.211, -0.523, 0.312);
    const mat3 toRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.106, 1.703);
    vec3 yiq = toYIQ * c;
    float hue = atan(yiq.z, yiq.y) + angle;
    float chroma = length(yiq.yz);
    return clamp(toRGB * vec3(yiq.x, chroma * cos(hue), chroma * sin(hue)), 0.0, 1.0);
}

vec4 sampleCache(int index, vec2 uv) {
    uv = seamlessUV(uv);
    if (index == 0)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (index == 1)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (index == 2)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (index == 3)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (index == 4)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (index == 5)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (index == 6)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

vec2 trailUV(vec2 uv, float age, float bass, float mid, float treble) {
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / max(iResolution, vec2(1.0)) : vec2(0.5);
    vec2 p = uv - center;
    float strength = 0.006 + amp_smooth * 0.018;

    if (MODE == 0) {
        p += vec2(age * strength * (1.0 + bass), -age * strength * 0.35);
    } else if (MODE == 1) {
        p = rotate2D(age * (0.035 + treble * 0.12)) * p;
        p *= pow(max(0.985 - bass * 0.045, 0.5), age);
    } else if (MODE == 2) {
        p.x += sin(p.y * 15.0 - time_f * 2.0 + age) * strength * age;
        p.y += cos(p.x * 11.0 + time_f * 1.4 - age) * strength * 0.6 * age;
    } else if (MODE == 3) {
        p = kaleido(rotate2D(age * 0.025) * p, 6.0 + floor(treble * 5.0));
        p *= 1.0 - age * 0.012;
    } else if (MODE == 4) {
        p *= pow(max(0.955 - bass * 0.07, 0.35), age);
        p = rotate2D(sin(time_f * 0.4) * 0.018 * age) * p;
    } else if (MODE == 5) {
        vec2 direction = normalize(vec2(cos(time_f * 0.35), sin(time_f * 0.27)));
        p -= direction * age * strength * (1.5 + bass * 2.0);
        p += vec2(-direction.y, direction.x) * sin(age + time_f) * strength;
    } else if (MODE == 6) {
        float cells = 10.0 + floor(treble * 12.0);
        vec2 cell = floor((uv + age * 0.003) * cells) / cells;
        vec2 local = uv - cell;
        p = cell - center + rotate2D(age * 0.07) * local;
    } else if (MODE == 7) {
        float plasma = sin(p.x * 18.0 + time_f + age) * cos(p.y * 16.0 - time_f * 1.3);
        p += vec2(plasma, -plasma) * strength * age * (1.0 + mid);
    } else if (MODE == 8) {
        float radius = length(p) + 0.001;
        p = rotate2D(log(radius + 0.08) * 0.06 * age + treble * 0.08 * age) * p;
        p *= pow(max(0.965 - bass * 0.06, 0.4), age);
    } else {
        p.x += sin(p.y * 9.0 + time_f * 0.8) * strength * age;
        p.y *= 1.0 + age * (0.008 + mid * 0.02);
        p = rotate2D(sin(p.x * 7.0 - time_f) * 0.018 * age) * p;
    }

    return p + center;
}

vec3 rgbStrobeCore(float bass, float mid, float treble, out vec3 ageDifference) {
    // MatrixCollection frames[1], frames[4], frames[7] map to samp2, samp5, samp8.
    vec2 uv1 = trailUV(tc, 2.0, bass, mid, treble);
    vec2 uv4 = trailUV(tc, 5.0, bass, mid, treble);
    vec2 uv7 = trailUV(tc, 8.0, bass, mid, treble);
    vec3 frame1 = sampleCache(1, uv1).rgb;
    vec3 frame4 = sampleCache(4, uv4).rgb;
    vec3 frame7 = sampleCache(7, uv7).rgb;

    float strobeRate = 7.0 + float(MODE % 4) * 1.75 + amp_peak * 5.0;
    bool strobe = mod(floor(time_f * strobeRate), 2.0) > 0.5;

    // Same temporal channel permutation as the OpenCV loop.
    vec3 forwardRoute = vec3(frame1.r, frame4.g, frame7.b);
    vec3 reverseRoute = vec3(frame7.r, frame4.g, frame1.b);
    ageDifference = abs(frame1 - frame7);
    return strobe ? forwardRoute : reverseRoute;
}

void main() {
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    vec3 ageDifference;
    vec3 routed = rgbStrobeCore(bass, mid, treble, ageDifference);
    vec3 live = texture(samp, seamlessUV(tc)).rgb;

    // Use all eight cache layers as faint rainbow persistence behind the exact 1/4/7 routing.
    vec3 persistence = vec3(0.0);
    float persistenceWeight = 0.0;
    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float weight = pow(0.69 + float(MODE % 3) * 0.025, age);
        vec3 echo = sampleCache(i, trailUV(tc, age, bass, mid, treble)).rgb;
        persistence += echo * rainbow(age * 0.075 + time_f * 0.04) * weight;
        persistenceWeight += weight;
    }
    persistence /= max(persistenceWeight, 0.001);

    float motion = dot(ageDifference, vec3(0.333));
    vec3 result = mix(live, routed, 0.68 + motion * 0.25);
    result = mix(result, persistence * 1.45, 0.24 + amp_smooth * 0.2);

    float huePhase = time_f * (0.22 + treble * 0.2) + motion * 2.0 + float(MODE) * 0.17;
    result = hueRotate(result, huePhase);
    result += rainbow(huePhase * 0.16 + length(tc - 0.5)) * motion * (0.45 + air * 1.8);

    // AddInvert equivalent: alternating complement, with peak inversion layered on top.
    float invertClock = mod(floor(time_f * (3.5 + float(MODE % 5))), 2.0);
    float invertMix = mix(0.12, 0.82, invertClock);
    result = mix(result, vec3(1.0) - result, invertMix);
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    result = (result - 0.5) * (1.32 + amp_smooth * 0.28) + 0.5;

    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
