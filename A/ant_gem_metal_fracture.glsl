#version 330 core
// ant_gem_metal_fracture
// Fractured metal surface with Voronoi cracks and spectrum-colored stress lines

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Voronoi fracture pattern
    float cellScale = 6.0 + bass * 4.0;
    vec2 cellUV = uv * cellScale;
    vec2 cellID = floor(cellUV);
    vec2 cellF = fract(cellUV);

    float minDist = 10.0;
    float secondDist = 10.0;
    vec2 nearestID = vec2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(cellID + neighbor);
            point = 0.5 + 0.5 * sin(time_f * 0.5 + 6.28318 * point);
            float d = length(cellF - neighbor - point);
            if (d < minDist) {
                secondDist = minDist;
                minDist = d;
                nearestID = cellID + neighbor;
            } else if (d < secondDist) {
                secondDist = d;
            }
        }
    }

    // Crack lines at cell boundaries
    float crack = secondDist - minDist;
    float crackMask = smoothstep(0.0, 0.05 + treble * 0.03, crack);
    float crackGlow = 1.0 - crackMask;

    // Texture per cell with offset
    float cellHash = fract(sin(dot(nearestID, vec2(12.9898, 78.233))) * 43758.5453);
    vec2 cellOffset = vec2(cellHash * 0.02, fract(cellHash * 7.0) * 0.02);
    vec2 sampUV = tc + cellOffset * (1.0 + mid * 2.0);

    // Chromatic split
    float chroma = 0.008 + air * 0.02;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Stress coloring in cracks
    vec3 stressColor = metalSpectrum(cellHash + time_f * 0.2 + bass);
    vec3 crackColor = stressColor * crackGlow * (2.0 + hiMid * 3.0);

    // Metallic sheen on cells
    float sheen = sin(r * 10.0 + angle * 3.0 + time_f) * 0.5 + 0.5;
    vec3 metalSheen = metalSpectrum(sheen + time_f * 0.1) * 0.15;

    vec3 finalColor = baseTex * crackMask + crackColor;
    finalColor += metalSheen * crackMask;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.95, 0.9) * center * (1.5 + amp_peak * 2.0);

    color = vec4(finalColor, 1.0);
}
