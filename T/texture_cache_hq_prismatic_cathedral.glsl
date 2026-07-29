#version 330 core

// Prismatic Cathedral -- stained-glass temporal vaults built from every
// frame in the scalable texture cache.

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

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

mat2 rotate2(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.54 + 0.46 * cos(TAU * (phase + vec3(0.02, 0.31, 0.67)));
}

vec3 toneMap(vec3 value) {
    value = max(value, 0.0);
    return clamp((value * (2.51 * value + 0.03)) /
                 (value * (2.43 * value + 0.59) + 0.14), 0.0, 1.0);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 aspectScale = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * aspectScale;
    float t = time_f;

    // Twelve mirrored aisles form the cathedral's radial nave.
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float sector = PI / 6.0;
    float foldedAngle = abs(mod(angle + 0.5 * sector, sector) - 0.5 * sector);
    vec2 vault = vec2(cos(foldedAngle), sin(foldedAngle)) * radius;

    vec3 current = texture(samp, tc).rgb;
    vec3 accumulation = current * 0.72;
    float totalWeight = 0.72;

    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(SIZE);
        float layer = float(index + 1);

        vec2 q = vault;
        q = rotate2(0.045 * layer + 0.10 * sin(t * 0.23 + layer)) * q;
        q.x *= 1.0 + 0.16 * sin(t * 0.31 - layer * 0.73);
        q.y += sin(q.x * (12.0 + 3.0 * age) - t * 0.82 + layer) *
               (0.012 + 0.025 * age);
        q *= 1.0 - 0.19 * age + 0.035 * sin(t * 0.19 + layer);

        vec2 historyUV = mirrorUV(q / aspectScale + 0.5);
        vec3 memory = texture(history, vec3(historyUV, float(CACHE_HISTORY_LAYER(index)))).rgb;
        vec3 tint = palette(age * 0.92 + radius * 0.38 + t * 0.018);
        float weight = pow(0.88, layer) * (0.72 + 0.28 * sin(layer * 2.17 + t) * sin(layer * 2.17 + t));

        accumulation += mix(memory, memory * tint * 1.55, 0.48) * weight;
        totalWeight += weight;
    }

    vec3 result = accumulation / max(totalWeight, 0.001);

    // Fine mortar, rose-window rings, and luminous lancet arches.
    float radialGrid = abs(sin(radius * 42.0 - t * 1.15));
    float angularGrid = abs(sin(foldedAngle * 36.0 + radius * 7.0));
    float mortarDistance = min(radialGrid, angularGrid);
    float mortarAA = max(fwidth(mortarDistance), 0.002);
    float mortar = 1.0 - smoothstep(0.025, 0.025 + mortarAA * 2.0, mortarDistance);

    float archDistance = abs(length(vec2(vault.x * 0.82, vault.y + 0.12)) -
                             (0.23 + 0.035 * sin(t * 0.4)));
    float arch = exp(-archDistance * 68.0);
    vec3 glowColor = palette(foldedAngle / sector + radius * 0.9 + t * 0.025);

    result *= 1.0 - mortar * 0.54;
    result += glowColor * (mortar * 0.35 + arch * 0.72);
    result = mix(result, result.brg, 0.08 + 0.06 * sin(t * 0.17));

    color = vec4(toneMap(result * 1.14), 1.0);
}
