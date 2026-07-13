#version 330 core

// History-manipulated in-the-sky effect: aurora rupture.

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

uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float time_f;
uniform float iTime;
uniform float amp;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float SEGMENTS = 10.0;
const float HUE_OFFSET = 0.14;
const float INTENSITY = 1.48;
const float PERSISTENCE = 0.79;

float clockTime() {
    return max(time_f, iTime);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash22(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453123);
}

float noise21(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    local = local * local * (3.0 - 2.0 * local);
    return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), local.x),
               mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + 1.0), local.x), local.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float weight = 0.5;
    mat2 basis = mat2(0.80, -0.60, 0.60, 0.80);
    for (int octave = 0; octave < 5; ++octave) {
        value += noise21(p) * weight;
        p = basis * p * 2.04 + vec2(1.8, 2.4);
        weight *= 0.5;
    }
    return value;
}

vec2 rotate2(vec2 p, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine) * p;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec2 kaleidoUV(vec2 uv, float segments, vec2 center, float aspect) {
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float sector = TAU / segments;
    angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    vec2 folded = vec2(cos(angle), sin(angle)) * radius;
    return folded / vec2(aspect, 1.0) + center;
}

vec2 fractalSkyFold(vec2 uv, float zoom, float rotation, vec2 center, float aspect) {
    vec2 p = uv;
    for (int iteration = 0; iteration < 5; ++iteration) {
        float fi = float(iteration);
        p = abs((p - center) * (zoom + fi * 0.035)) - 0.5 + center;
        vec2 scaled = (p - center) * vec2(aspect, 1.0);
        scaled = rotate2(scaled, rotation + fi * 0.075);
        p = scaled / vec2(aspect, 1.0) + center;
    }
    return p;
}

vec3 skyPalette(float phase) {
    vec3 wave = 0.5 + 0.5 * cos(TAU * (phase + HUE_OFFSET + vec3(0.00, 0.31, 0.67)));
    return clamp((wave - 0.08) * 1.18, 0.0, 1.0);
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) / (value * (2.43 * value + 0.59) + 0.14), 0.0,
                 1.0);
}

vec4 cacheFrame(int index, vec2 uv) {
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

float spectrumHistory(int index, float frequency) {
    if (index == 0)
        return texture(spectrum0, frequency).r;
    if (index == 1)
        return texture(spectrum1, frequency).r;
    if (index == 2)
        return texture(spectrum2, frequency).r;
    if (index == 3)
        return texture(spectrum3, frequency).r;
    if (index == 4)
        return texture(spectrum4, frequency).r;
    if (index == 5)
        return texture(spectrum5, frequency).r;
    if (index == 6)
        return texture(spectrum6, frequency).r;
    return texture(spectrum7, frequency).r;
}

vec4 historyBands(int index) {
    return vec4(spectrumHistory(index, 0.04), spectrumHistory(index, 0.22),
                spectrumHistory(index, 0.58), spectrumHistory(index, 0.86));
}

vec3 skyField(vec2 p, float age, vec4 band) {
    float t = clockTime();
    vec2 q = p;
    q.x += sin(q.y * 3.0 - t * 0.28 + age * 0.3) * 0.22;
    float cloudA = fbm(q * vec2(2.0, 5.0) + vec2(t * 0.05, -t * 0.13));
    float cloudB = fbm(q * vec2(6.0, 12.0) - vec2(t * 0.08, t * 0.2));
    float curtain = exp(-abs(sin(q.x * (7.0 + band.y * 8.0) + cloudA * 6.0)) * 4.2);
    float rupture = pow(abs(cloudA - cloudB), 2.0);
    vec2 flow = vec2(cloudA - cloudB, -0.35 - band.x * 0.4);
    return vec3(curtain * (0.65 + rupture), flow);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 mouseCenter = iMouse.z > 0.5 ? iMouse.xy / max(iResolution, vec2(1.0)) : vec2(0.5);
    vec2 center = vec2(0.5) + (mouseCenter - 0.5) * (0.7 + amp * 0.25);
    vec2 p = (tc - center) * aspectScale;
    vec3 live = texture(samp, tc).rgb;

    vec3 accumulation = live * 0.28;
    float totalWeight = 0.28;
    vec4 newest = historyBands(0);
    vec4 oldest = historyBands(7);
    float temporalChange = length(newest - oldest);

    for (int index = 0; index < 8; ++index) {
        float age = float(index);
        vec4 bands = historyBands(index);
        vec3 field = skyField(p, age, bands);
        float energy = clamp(abs(field.x), 0.0, 2.2);
        vec2 flow = clamp(field.yz, vec2(-2.0), vec2(2.0));

        float segmentCount = SEGMENTS + 2.0 * floor(bands.z * 4.0);
        vec2 historyUV = kaleidoUV(tc, segmentCount, center, aspect);
        float zoom =
            1.28 + bands.x * 0.42 + energy * 0.08 + 0.08 * sin(clockTime() * 0.22 - age * 0.18);
        float rotation = clockTime() * (0.025 + bands.y * 0.08) + age * 0.035 + energy * 0.04;
        historyUV = fractalSkyFold(historyUV, zoom, rotation, center, aspect);
        historyUV += flow / aspectScale * (0.006 + bands.z * 0.018) * INTENSITY;
        historyUV = mirrorUV(historyUV);

        vec3 cached = cacheFrame(index, historyUV).rgb;
        vec3 tint = skyPalette(energy * 0.22 + age * 0.081 + bands.w * 0.32 + clockTime() * 0.013);
        float emission = pow(clamp(energy, 0.0, 1.0), 2.3);
        vec3 layer = mix(cached, cached * tint * 1.32, 0.50);
        layer += tint * emission * (0.16 + bands.z * 0.72);

        float weight = pow(PERSISTENCE, age + 1.0) * (0.52 + bands.x * 0.76 + bands.y * 0.38);
        accumulation += layer * weight;
        totalWeight += weight;
    }

    vec3 result = accumulation / max(totalWeight, 0.001);
    vec3 currentField = skyField(p, 0.0, newest);
    float currentEnergy = clamp(abs(currentField.x), 0.0, 1.5);
    vec3 energyColor =
        skyPalette(currentEnergy * 0.28 + temporalChange * 0.24 + clockTime() * 0.015);
    float crown = pow(clamp(currentEnergy, 0.0, 1.0), 2.6);
    float edge = fwidth(currentField.x);

    result = 1.0 - (1.0 - result) * (1.0 - clamp(energyColor * crown * 0.48, 0.0, 0.88));
    result += energyColor * edge * (1.8 + newest.w * 3.2);
    result *= 1.0 + clamp(amp_smooth + amp * 0.25, 0.0, 1.5) * 0.24;
    result = toneMap(result);

    float inversion =
        smoothstep(0.72, 0.98, amp_peak) * smoothstep(0.06, 0.50, temporalChange) * 0.68;
    vec3 inverted = mix(vec3(1.0) - result, (vec3(1.0) - result).gbr, 0.26);
    result = mix(result, inverted, inversion);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
