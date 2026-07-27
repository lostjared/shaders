#version 330 core
// rainbow_trail_difference_comet
// Changing regions stretch into a directional rainbow difference comet.
#define TRAIL_MODE 5

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
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

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

vec3 differenceTrailCore(float bass, float mid, float treble, out float motionMask) {
    // MatrixCollection frames[1], frames[4], frames[7] map to samp2, samp5, samp8.
    vec2 uv1 = trailUV(tc, 2.0, bass, mid, treble);
    vec2 uv4 = trailUV(tc, 5.0, bass, mid, treble);
    vec2 uv7 = trailUV(tc, 8.0, bass, mid, treble);
    vec3 frame1 = sampleCache(1, uv1).rgb;
    vec3 frame4 = sampleCache(4, uv4).rgb;
    vec3 frame7 = sampleCache(7, uv7).rgb;
    vec3 liveAt1 = texture(samp, seamlessUV(uv1)).rgb;
    vec3 liveAt4 = texture(samp, seamlessUV(uv4)).rgb;
    vec3 liveAt7 = texture(samp, seamlessUV(uv7)).rgb;

    // The original boolean toggles once per frame; the reference video is 30 fps.
    float strobeRate = 30.0;
    bool strobe = mod(floor(time_f * strobeRate), 2.0) > 0.5;

    // Same-UV live/history comparisons cancel the room and retain filled old silhouettes.
    vec3 difference1 = abs(frame1 - liveAt1);
    vec3 difference4 = abs(frame4 - liveAt4);
    vec3 difference7 = abs(frame7 - liveAt7);
    float motion1 = dot(difference1, vec3(0.333));
    float motion4 = dot(difference4, vec3(0.333));
    float motion7 = dot(difference7, vec3(0.333));

    // Alternating scalar age routing creates the reference's cyan/magenta/yellow overlaps.
    vec3 forwardRoute = vec3(motion1, motion4, motion7);
    vec3 reverseRoute = vec3(motion7, motion4, motion1);
    vec3 routedDifference = strobe ? forwardRoute : reverseRoute;

    float rawMotion = max(max(motion1, motion4), motion7);
    float threshold = 0.025 + (1.0 - amp_smooth) * 0.018;
    motionMask = smoothstep(threshold, threshold + 0.1, rawMotion);
    return smoothstep(vec3(threshold), vec3(threshold + 0.13), routedDifference) * motionMask;
}

void main() {
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    float coreMotion;
    vec3 coreDifference = differenceTrailCore(bass, mid, treble, coreMotion);
    vec3 live = texture(samp, tc).rgb;

    // Each cache age is compared to live at one shared coordinate.
    vec3 differenceTrail = vec3(0.0);
    float trailMask = 0.0;
    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        vec2 differenceUV = trailUV(tc, age, bass, mid, treble);
        vec3 history = sampleCache(i, differenceUV).rgb;
        vec3 currentAtUV = texture(samp, seamlessUV(differenceUV)).rgb;
        vec3 delta = abs(history - currentAtUV);
        float magnitude = dot(delta, vec3(0.333));
        float mask = smoothstep(0.025, 0.13, magnitude);
        float weight = pow(0.82 + float(MODE % 3) * 0.015, age);
        vec3 bandColor = rainbow(age * 0.13 + time_f * 0.025 + float(MODE) * 0.07);
        differenceTrail += bandColor * mask * weight * (0.75 + magnitude * 1.5);
        trailMask += mask * weight;
    }

    differenceTrail += coreDifference * (1.1 + coreMotion * 1.4);
    float motion = clamp(max(coreMotion, trailMask * 0.22), 0.0, 1.0);

    float huePhase = time_f * (0.22 + treble * 0.2) + motion * 2.0 + float(MODE) * 0.17;
    differenceTrail = hueRotate(differenceTrail, huePhase);
    differenceTrail += rainbow(huePhase * 0.16 + length(tc - 0.5)) * motion * (0.18 + air * 0.9);

    // The AddInvert idea affects only the colored trail, never the base frame.
    float invertClock = mod(floor(time_f * (3.5 + float(MODE % 5))), 2.0);
    differenceTrail = mix(differenceTrail, motion - differenceTrail, mix(0.08, 0.72, invertClock));
    differenceTrail =
        mix(differenceTrail, motion - differenceTrail, smoothstep(0.88, 1.0, amp_peak));
    differenceTrail = max(differenceTrail, 0.0) * (1.3 + amp_smooth * 0.8);

    // Screen blending keeps stationary areas identical to the live frame.
    vec3 trail = clamp(differenceTrail, 0.0, 1.0) * motion;
    vec3 result = 1.0 - (1.0 - live) * (1.0 - trail);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
