#version 330 core

// Cache-driven perceptual energy field: synesthetic veil.

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
const float HUE_OFFSET = 0.64;
const float DISTORTION = 0.86;
const float PERSISTENCE = 0.87;

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

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 perceptualPalette(float phase) {
    vec3 wave = 0.5 + 0.5 * cos(TAU * (phase + HUE_OFFSET + vec3(0.00, 0.30, 0.66)));
    vec3 opponent = mix(wave, wave.gbr, 0.22);
    return clamp((opponent - 0.05) * 1.10, 0.0, 1.0);
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return 1.0 - exp(-value * (1.12 + value * 0.08));
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

vec3 perceptualField(vec2 p, float age, vec4 band) {
    float t = clockTime();
    vec2 q = p;
    float low = band.x;
    float middle = band.y;
    float high = band.z;
    q.x += sin(q.y * (3.0 + middle * 5.0) - t * 0.26 + age * 0.2) * 0.16;
    float veilA = fbm(q * vec2(2.2, 6.0) + vec2(t * 0.05, -t * 0.11));
    float veilB = fbm(q * vec2(5.0, 11.0) - vec2(t * 0.07, t * 0.17));
    float strand = exp(-abs(sin(q.x * (7.0 + high * 9.0) + veilA * 5.0)) * 4.5);
    float energy = strand * (0.42 + veilA * 0.45 + veilB * 0.24 + low * 0.35);
    vec2 flow = vec2(veilA - veilB, -0.25 - middle * 0.35);
    return vec3(energy, flow);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * aspectScale;
    float eccentricity = smoothstep(0.06, 0.92, length(p));
    vec3 live = texture(samp, tc).rgb;

    vec3 accumulation = live * 0.42;
    float totalWeight = 0.42;
    vec4 newest = historyBands(0);
    vec4 oldest = historyBands(7);
    float temporalDelta = length(newest - oldest);

    for (int index = 0; index < 8; ++index) {
        float age = float(index);
        vec4 bands = historyBands(index);
        vec3 field = perceptualField(p, age, bands);
        float energy = clamp(abs(field.x), 0.0, 2.0);
        vec2 flow = clamp(field.yz, vec2(-2.0), vec2(2.0));

        float breathing = 1.0 + sin(clockTime() * 0.21 - age * 0.16) * (0.006 + bands.x * 0.018);
        vec2 historyUV = (tc - 0.5) * breathing + 0.5;
        float peripheralGain = mix(0.45, 1.0, eccentricity);
        historyUV += flow / aspectScale * DISTORTION * (0.007 + bands.y * 0.018) * peripheralGain;
        historyUV = mirrorUV(historyUV);

        vec3 cached = cacheFrame(index, historyUV).rgb;
        vec3 afterimage = mix(cached, cached.gbr, 0.10 + age * 0.025);
        vec3 fieldColor =
            perceptualPalette(energy * 0.21 + age * 0.073 + bands.w * 0.27 + clockTime() * 0.010);
        float luminous = pow(clamp(energy, 0.0, 1.0), 2.0);
        vec3 layer = mix(afterimage, afterimage * fieldColor * 1.18, 0.44);
        layer += fieldColor * luminous * (0.10 + bands.z * 0.48);

        float weight = pow(PERSISTENCE, age + 1.0) * (0.46 + bands.x * 0.66 + bands.y * 0.34);
        accumulation += layer * weight;
        totalWeight += weight;
    }

    vec3 result = accumulation / max(totalWeight, 0.001);
    vec3 currentField = perceptualField(p, 0.0, newest);
    float currentEnergy = clamp(abs(currentField.x), 0.0, 1.4);
    vec3 auraColor =
        perceptualPalette(currentEnergy * 0.28 + temporalDelta * 0.18 + clockTime() * 0.012);
    float aura = pow(clamp(currentEnergy, 0.0, 1.0), 2.5);
    float fieldEdge = fwidth(currentField.x);

    result = 1.0 - (1.0 - result) * (1.0 - clamp(auraColor * aura * 0.28, 0.0, 0.72));
    result += auraColor * fieldEdge * (1.1 + newest.w * 2.2);
    result = mix(result, live, 0.10 * (1.0 - eccentricity));
    result *= 1.0 + clamp(amp_smooth, 0.0, 1.0) * 0.16;
    result = toneMap(result);

    float inversion =
        smoothstep(0.72, 0.98, amp_peak) * smoothstep(0.06, 0.48, temporalDelta) * 0.64;
    vec3 inverted = mix(vec3(1.0) - result, (vec3(1.0) - result).brg, 0.24);
    result = mix(result, inverted, inversion);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
