#version 330 core

// Liquid Chrysalis -- silky domain-warped memories flowing around an
// iridescent cocoon. Uses the complete, runtime-sized history buffer.

#ifndef SIZE
#define SIZE 8
#endif

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

mat2 rotate2(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

float liquidField(vec2 p, float phase) {
    p = rotate2(0.37) * p;
    float field = sin(p.x * 5.7 + phase);
    field += sin(p.y * 7.3 - phase * 1.21);
    field += sin((p.x + p.y) * 4.6 + phase * 0.73);
    field += 0.55 * sin(length(p + vec2(sin(phase), cos(phase)) * 0.18) * 17.0 - phase * 1.8);
    return field * 0.282;
}

vec2 liquidFlow(vec2 p, float phase) {
    float epsilon = 0.006;
    float dx = liquidField(p + vec2(epsilon, 0.0), phase) -
               liquidField(p - vec2(epsilon, 0.0), phase);
    float dy = liquidField(p + vec2(0.0, epsilon), phase) -
               liquidField(p - vec2(0.0, epsilon), phase);
    return vec2(dy, -dx) / (2.0 * epsilon);
}

vec3 palette(float phase) {
    return 0.52 + 0.48 * cos(TAU * (phase + vec3(0.00, 0.27, 0.61)));
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return value / (1.0 + value);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * aspectScale;
    float t = time_f;

    float baseField = liquidField(p * 1.35, t * 0.34);
    vec2 baseFlow = liquidFlow(p * 1.35, t * 0.34);
    float cocoonRadius = length(vec2(p.x * 1.38, p.y * 0.76));

    vec3 current = texture(samp, mirrorUV(tc + baseFlow / aspectScale * 0.006)).rgb;
    vec3 accumulation = current * 0.62;
    float totalWeight = 0.62;

    for (int index = 0; index < SIZE; ++index) {
        float layer = float(index + 1);
        float age = layer / float(SIZE);
        float phase = t * (0.22 + 0.04 * age) - layer * 0.67;

        vec2 q = p;
        vec2 flow = liquidFlow(q * (1.15 + age * 0.42), phase);
        q += flow * (0.010 + 0.017 * age);
        q += baseFlow * (0.004 + 0.010 * age);
        q = rotate2(0.035 * sin(phase + cocoonRadius * 4.0)) * q;
        q *= 1.0 + (baseField * 0.025 - 0.065 * age);

        vec2 historyUV = mirrorUV(q / aspectScale + 0.5);
        vec3 memory = texture(history, vec3(historyUV, float(CACHE_HISTORY_LAYER(index)))).rgb;
        vec3 film = palette(baseField * 0.30 + age * 0.84 + t * 0.015);
        float weight = pow(0.89, layer) * (0.78 + 0.22 * cos(phase) * cos(phase));

        accumulation += mix(memory, memory * film * 1.42, 0.43) * weight;
        totalWeight += weight;
    }

    vec3 result = accumulation / max(totalWeight, 0.001);

    float shell = exp(-abs(cocoonRadius - 0.35 - baseField * 0.045) * 45.0);
    float innerShell = exp(-abs(cocoonRadius - 0.22 + baseField * 0.025) * 64.0);
    float silk = pow(0.5 + 0.5 * sin(baseField * 18.0 + cocoonRadius * 34.0 - t), 9.0);
    vec3 iridescence = palette(cocoonRadius * 1.8 + baseField * 0.33 + t * 0.024);

    result = 1.0 - (1.0 - result) *
             (1.0 - clamp(iridescence * shell * 0.68, 0.0, 0.92));
    result += iridescence * (innerShell * 0.31 + silk * shell * 0.28);

    float luminance = dot(result, vec3(0.2126, 0.7152, 0.0722));
    result = mix(vec3(luminance), result, 1.20);
    color = vec4(clamp(toneMap(result * 1.42), 0.0, 1.0), 1.0);
}
