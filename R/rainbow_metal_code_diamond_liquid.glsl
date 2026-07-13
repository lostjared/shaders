#version 330 core

// diamond-faceted liquid metal: high-detail rainbow metal with audio-reactive physical lighting.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;
uniform float slider1;
uniform float slider2;
uniform float slider3;
uniform float slider4;

const float TAU = 6.28318530718;
const int STYLE = 3;
const float ARMS = 12.0;
const float DENSITY = 54.0;
const float HUE_OFFSET = 0.98;
const float WARP_STRENGTH = 1.42;
const float BASE_ROUGHNESS = 0.15;
const float MOTION_SPEED = 1.16;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
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
    mat2 rotation = mat2(0.80, -0.60, 0.60, 0.80);
    for (int octave = 0; octave < 6; ++octave) {
        value += noise21(p) * weight;
        p = rotation * p * 2.04 + vec2(1.7, 2.3);
        weight *= 0.5;
    }
    return value;
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 rainbowPalette(float phase) {
    vec3 raw = 0.5 + 0.5 * cos(TAU * (phase + HUE_OFFSET + vec3(0.00, 0.33, 0.67)));
    return clamp((raw - 0.12) * 1.22, 0.0, 1.0);
}

vec3 acesToneMap(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) / (value * (2.43 * value + 0.59) + 0.14), 0.0,
                 1.0);
}

float heightField(vec2 p) {
    float t = time_f * MOTION_SPEED;
    float radius = length(p) + 0.001;
    float angle = atan(p.y, p.x);
    float bass = clamp(amp_low, 0.0, 1.0);
    float mids = clamp(amp_mid, 0.0, 1.0);
    float high = clamp(amp_high, 0.0, 1.0);
    float detail = fbm(p * (3.0 + slider2 * 2.0) + vec2(t * 0.08, -t * 0.11));

    if (STYLE == 0) {
        vec2 sourceA = vec2(sin(t * 0.37), cos(t * 0.29)) * 0.32;
        vec2 sourceB = vec2(cos(t * 0.31), -sin(t * 0.43)) * 0.27;
        vec2 sourceC = vec2(sin(t * 0.23), sin(t * 0.35)) * 0.18;
        float waveA = sin(length(p - sourceA) * DENSITY - t * 4.0);
        float waveB = cos(length(p - sourceB) * (DENSITY * 0.73) - t * 3.1);
        float waveC = sin(length(p - sourceC) * (DENSITY * 1.21) + t * 5.2);
        return waveA * (0.30 + bass * 0.15) + waveB * 0.22 + waveC * 0.13 + detail * 0.48;
    }

    if (STYLE == 1) {
        float coilA = sin(angle * ARMS + radius * DENSITY - t * 3.2);
        float coilB = cos(angle * (ARMS + 4.0) - radius * DENSITY * 0.62 + t * 2.4);
        float depth = sin(-log(radius) * 12.0 + angle * 4.0 - t * 2.0);
        return coilA * (0.31 + bass * 0.12) + coilB * 0.20 + depth * 0.14 + detail * 0.42;
    }

    if (STYLE == 2) {
        vec2 domain = p;
        domain += vec2(fbm(p * 2.2 + t * 0.07), fbm(p * 2.2 + 8.4 - t * 0.06)) *
                  (0.28 + WARP_STRENGTH * 0.12);
        float flow = fbm(domain * 4.5 + vec2(0.0, -t * 0.15));
        float ridges = sin(domain.x * DENSITY * 0.45 + domain.y * 9.0 - t * 2.8);
        return flow * 0.68 + detail * 0.26 + ridges * (0.15 + mids * 0.08);
    }

    if (STYLE == 3) {
        float facet = cos(angle * ARMS);
        float rings = sin(radius * DENSITY - t * 3.6 + facet * 3.0);
        float diamond = max(abs(p.x), abs(p.y));
        float crystal = cos(diamond * DENSITY * 1.25 + facet * 2.0 + t * 1.7);
        return rings * 0.30 + crystal * 0.22 + abs(facet) * 0.12 + detail * 0.45;
    }

    vec2 poleA = vec2(cos(t * 0.31), sin(t * 0.37)) * 0.31;
    vec2 poleB = -poleA;
    vec2 poleC = vec2(sin(t * 0.23), cos(t * 0.28)) * 0.15;
    vec2 deltaA = p - poleA;
    vec2 deltaB = p - poleB;
    vec2 deltaC = p - poleC;
    float fieldA = sin(atan(deltaA.y, deltaA.x) * ARMS + 1.2 / (length(deltaA) + 0.06));
    float fieldB = cos(atan(deltaB.y, deltaB.x) * (ARMS + 2.0) - 1.0 / (length(deltaB) + 0.06));
    float fieldC = sin(length(deltaC) * DENSITY - t * 4.0);
    return fieldA * (0.26 + bass * 0.12) + fieldB * 0.22 + fieldC * 0.13 +
           detail * (0.42 + high * 0.08);
}

vec3 surfaceNormal(vec2 p, float epsilon) {
    float center = heightField(p);
    float right = heightField(p + vec2(epsilon, 0.0));
    float top = heightField(p + vec2(0.0, epsilon));
    vec2 gradient = vec2(right - center, top - center) / epsilon;
    return normalize(vec3(-gradient * (0.13 + WARP_STRENGTH * 0.045), 1.0));
}

float ggxDistribution(float normalHalf, float roughness) {
    float alpha = roughness * roughness;
    float alphaSquared = alpha * alpha;
    float denominator = normalHalf * normalHalf * (alphaSquared - 1.0) + 1.0;
    return alphaSquared / max(3.14159265 * denominator * denominator, 0.0001);
}

vec3 lightMetal(vec3 base, vec3 normal, vec2 p, float roughness, float filmPhase) {
    vec3 view = normalize(vec3(-p * 0.10, 1.6));
    vec3 lightA = normalize(vec3(-0.62, 0.68, 0.58));
    vec3 lightB = normalize(vec3(0.76, -0.24, 0.61));
    vec3 lightC = normalize(vec3(0.18, 0.82, 0.48));
    vec3 lightColorA = vec3(1.00, 0.82, 0.62);
    vec3 lightColorB = vec3(0.28, 0.56, 1.20);
    vec3 lightColorC = rainbowPalette(filmPhase + 0.35);

    float normalView = max(dot(normal, view), 0.0);
    vec3 f0 = mix(vec3(0.56), base, 0.67);
    vec3 result = base * 0.045;
    vec3 lights[3] = vec3[3](lightA, lightB, lightC);
    vec3 colors[3] = vec3[3](lightColorA, lightColorB, lightColorC);

    for (int index = 0; index < 3; ++index) {
        vec3 halfVector = normalize(view + lights[index]);
        float normalLight = max(dot(normal, lights[index]), 0.0);
        float normalHalf = max(dot(normal, halfVector), 0.0);
        float viewHalf = max(dot(view, halfVector), 0.0);
        vec3 fresnel = f0 + (1.0 - f0) * pow(1.0 - viewHalf, 5.0);
        float specular = ggxDistribution(normalHalf, roughness);
        result +=
            colors[index] * (base * normalLight * 0.055 + fresnel * specular * normalLight * 0.20);
    }

    vec3 reflected = reflect(-view, normal);
    vec3 environment =
        rainbowPalette(reflected.x * 0.16 + reflected.y * 0.11 + reflected.z * 0.08 + filmPhase);
    vec3 rimFresnel = f0 + (1.0 - f0) * pow(1.0 - normalView, 5.0);
    return result + environment * rimFresnel * 0.92;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * aspectScale;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float epsilon = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);

    float fftBass = texture(spectrum, 0.05).r;
    float fftMid = texture(spectrum, 0.30).r;
    float fftHigh = texture(spectrum, 0.72).r;
    float fftRadius = texture(spectrum, clamp(radius * 0.72, 0.0, 1.0)).r;
    float bass = max(clamp(amp_low, 0.0, 1.0), fftBass);
    float mids = max(clamp(amp_mid, 0.0, 1.0), fftMid);
    float high = max(clamp(amp_high, 0.0, 1.0), fftHigh);
    float energy = clamp(amp_rms + amp_peak * 0.7 + fftRadius * 0.8, 0.0, 1.8);

    float height = heightField(p);
    vec3 normal = surfaceNormal(p, epsilon);
    vec2 radial = normalize(p + vec2(0.0001)) / aspectScale;
    float travelingWave =
        sin(radius * DENSITY - time_f * MOTION_SPEED * 4.0 + height * 6.0 + fftRadius * 8.0);
    vec2 flow = normal.xy * (0.018 + WARP_STRENGTH * 0.012 + bass * 0.016);
    flow += radial * travelingWave * (0.004 + slider4 * 0.008);
    vec2 uv = mirrorUV(tc + flow);

    float dispersion = 0.0018 + WARP_STRENGTH * 0.0018 + high * 0.007 + slider3 * 0.005;
    vec3 textureColor =
        vec3(texture(samp, mirrorUV(uv + normal.xy * dispersion)).r, texture(samp, uv).g,
             texture(samp, mirrorUV(uv - normal.xy * dispersion)).b);
    float luminance = dot(textureColor, vec3(0.299, 0.587, 0.114));
    vec3 silverBase = vec3(luminance) * vec3(0.78, 0.86, 0.96);
    vec3 metalBase = mix(silverBase, textureColor, 0.30 + mids * 0.12);

    float roughness = clamp(BASE_ROUGHNESS + fbm(p * 5.0) * 0.10 - amp_peak * 0.045, 0.055, 0.42);
    float filmPhase =
        height * 0.24 + radius * 0.18 + time_f * 0.016 * MOTION_SPEED + fftRadius * 0.35;
    vec3 result = lightMetal(metalBase, normal, p, roughness, filmPhase);

    float ringCrest = pow(0.5 + 0.5 * travelingWave, 8.0);
    float angularCrest = pow(0.5 + 0.5 * sin(angle * ARMS + height * 5.0), 10.0);
    vec3 ringColor = rainbowPalette(filmPhase + radius * DENSITY / TAU);
    float ringStrength = ringCrest * (0.18 + energy * 0.55 + fftRadius * 0.65);
    result = 1.0 - (1.0 - result) * (1.0 - clamp(ringColor * ringStrength, 0.0, 0.82));
    result += ringColor * ringStrength * (0.28 + slider4 * 0.35);
    result += rainbowPalette(filmPhase + 0.25) * angularCrest * high * 0.28;

    float core = exp(-radius * (4.8 - amp_smooth * 2.6));
    result += vec3(1.0, 0.96, 0.88) * core * (0.35 + energy * 0.75);
    result *= 1.0 + clamp(amp_smooth, 0.0, 1.0) * 0.18;
    color = vec4(acesToneMap(result), texture(samp, uv).a);
}
