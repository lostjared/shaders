#version 330 core

// Temporal inversion energy field: reaction front.

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
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float HUE_OFFSET = 0.27;

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
        p = basis * p * 2.03 + vec2(1.7, 2.4);
        weight *= 0.5;
    }
    return value;
}

vec2 rotate2(vec2 p, float angle) {
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine) * p;
}

float segmentDistance(vec2 p, vec2 a, vec2 b) {
    vec2 segment = b - a;
    float position = clamp(dot(p - a, segment) / max(dot(segment, segment), 0.0001), 0.0, 1.0);
    return length(p - a - segment * position);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 palette(float phase) {
    vec3 colorWave = 0.5 + 0.5 * cos(TAU * (phase + HUE_OFFSET + vec3(0.00, 0.28, 0.63)));
    return clamp((colorWave - 0.08) * 1.16, 0.0, 1.0);
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

vec3 energyField(vec2 p, float age, vec4 band) {
    float t = clockTime();
    vec2 domain = p + vec2(fbm(p * 2.0 + t * 0.05), fbm(p * 2.0 + 7.0 - t * 0.04)) * 0.32;
    float activator = fbm(domain * (4.0 + band.x * 3.0) + age * 0.17);
    float inhibitor = fbm(domain * (8.0 + band.y * 4.0) - age * 0.13);
    float reaction = activator * 1.25 - inhibitor * 0.78;
    float front = exp(-abs(reaction - 0.28 - band.z * 0.15) * 14.0);
    vec2 flow = vec2(sin(reaction * 9.0 + t), cos(reaction * 7.0 - t));
    return vec3(front, flow * (0.4 + front));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * aspectScale;
    vec3 live = texture(samp, tc).rgb;

    vec3 accumulation = live * 0.10;
    float totalWeight = 0.10;
    vec4 newestBands = historyBands(0);
    vec4 oldestBands = historyBands(7);
    float temporalChange = length(newestBands - oldestBands);

    for (int index = 0; index < 8; ++index) {
        float age = float(index);
        vec4 bands = historyBands(index);
        vec3 field = energyField(p, age, bands);
        float energy = clamp(abs(field.x) * 1.65 + bands.x * 0.30, 0.0, 3.5);
        vec2 vectorField = clamp(field.yz * 1.35, vec2(-2.8), vec2(2.8));

        // The field itself drives a layered geometric transform.
        vec2 geometry = p;
        float transformAngle =
            age * 0.16 + bands.z * 1.35 + field.x * 0.24 + sin(clockTime() * 0.19 - age) * 0.12;
        geometry = rotate2(geometry, transformAngle);

        float shear = sin(clockTime() * 0.27 + age * 0.71 + bands.y * 4.0) * (0.16 + energy * 0.09);
        geometry = mat2(1.0, shear, -shear * 0.72, 1.0) * geometry;

        float bendFrequency = 4.5 + bands.z * 10.0 + age * 0.55;
        vec2 bend = vec2(sin(geometry.y * bendFrequency + clockTime() * 0.8 + age),
                         cos(geometry.x * (bendFrequency * 0.87) - clockTime() * 0.67 + age * 0.6));
        geometry += bend * (0.045 + energy * 0.035 + bands.y * 0.075);

        float recursiveScale =
            1.0 + sin(clockTime() * 0.31 - age * 0.38) * 0.12 - age * 0.026 - bands.x * 0.10;
        geometry *= recursiveScale;

        float foldMix = smoothstep(0.28, 1.10, energy);
        vec2 folded = abs(geometry) - vec2(0.24 + bands.x * 0.10, 0.20 + bands.y * 0.08);
        folded = rotate2(folded, -transformAngle * 0.63 + field.x * 0.18);
        geometry = mix(geometry, folded, foldMix * 0.58);

        vec2 historyUV = geometry / aspectScale + 0.5;
        historyUV += vectorField / aspectScale * (0.024 + bands.y * 0.060 + bands.z * 0.035);
        historyUV = mirrorUV(historyUV);

        vec2 echoOffset = rotate2(vectorField, transformAngle + 1.5707963) / aspectScale *
                          (0.008 + energy * 0.012 + bands.w * 0.018);
        vec3 cachedPrimary = cacheFrame(index, historyUV).rgb;
        vec3 cachedEcho = cacheFrame(index, mirrorUV(historyUV + echoOffset)).bgr;
        vec3 cached = mix(cachedPrimary, cachedEcho, 0.20 + bands.z * 0.24);

        vec3 fieldColor =
            palette(energy * 0.31 + age * 0.103 + bands.w * 0.42 + clockTime() * 0.018);
        float emissive = pow(clamp(energy, 0.0, 1.35), 1.45);
        float geometryLine =
            pow(0.5 + 0.5 * sin(dot(geometry, vec2(9.0 + age, 7.0 + bands.y * 8.0)) + energy * TAU -
                                clockTime() * 1.3),
                7.0);
        vec3 layer = mix(cached, cached * fieldColor * 1.62, 0.76);
        layer += fieldColor * emissive * (0.48 + bands.z * 1.35);
        layer += palette(fieldColor.r + age * 0.07) * geometryLine * (0.18 + energy * 0.30);

        float weight = pow(0.84, age) * (0.70 + bands.x * 1.05 + bands.y * 0.62 + energy * 0.12);
        accumulation += layer * weight;
        totalWeight += weight;
    }

    vec3 result = accumulation / max(totalWeight, 0.001);
    vec3 currentField = energyField(p, 0.0, newestBands);
    float currentEnergy = clamp(abs(currentField.x) * 1.75 + newestBands.x * 0.25, 0.0, 2.0);
    float edgeEnergy = fwidth(currentField.x);
    vec3 currentColor = palette(currentEnergy * 0.39 + temporalChange * 0.34 + clockTime() * 0.020);

    float aura = pow(clamp(currentEnergy, 0.0, 1.0), 1.65);
    result = 1.0 - (1.0 - result) * (1.0 - clamp(currentColor * aura * 0.78, 0.0, 0.94));
    result += currentColor * aura * (0.32 + newestBands.y * 0.48);
    result += currentColor * edgeEnergy * (3.2 + newestBands.w * 5.0);

    float pulseGeometry =
        pow(0.5 + 0.5 * sin(length(p) * 32.0 + currentField.x * 9.0 - clockTime() * 2.1), 8.0);
    result += palette(currentEnergy + 0.23) * pulseGeometry * (0.14 + newestBands.z * 0.42);

    float luminance = dot(result, vec3(0.299, 0.587, 0.114));
    result = mix(vec3(luminance), result, 1.28);
    result *= 1.12 + clamp(amp_smooth, 0.0, 1.0) * 0.42;

    result = toneMap(result);
    float inversion =
        smoothstep(0.48, 0.88, amp_peak) * (0.34 + 0.66 * smoothstep(0.04, 0.42, temporalChange));
    vec3 inverted = 1.0 - result;
    inverted = mix(inverted, inverted.bgr, 0.28 + newestBands.z * 0.42);
    result = mix(result, inverted, inversion * 0.94);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
