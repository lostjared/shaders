#version 330 core
// ant_spectrum_echo_diamond
// Diamond tile mirrors with echo depth, rainbow facets, and kaleidoscopic symmetry

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Diamond tiling
    uv *= rot(PI / 4.0);
    float tileSize = 0.5 + bass * 0.2;
    vec2 tileID = floor(uv / tileSize);
    vec2 tileUV = fract(uv / tileSize);

    // Mirror within diamond tile
    tileUV = abs(tileUV - 0.5);
    if (tileUV.y > tileUV.x) tileUV = tileUV.yx;

    // Additional kaleidoscopic fold
    float kAngle = atan(tileUV.y, tileUV.x);
    float kR = length(tileUV);
    float kSeg = 4.0;
    float kStep = 2.0 * PI / kSeg;
    kAngle = mod(kAngle, kStep);
    kAngle = abs(kAngle - kStep * 0.5);
    tileUV = vec2(cos(kAngle), sin(kAngle)) * kR;

    // Map to texture
    vec2 texUV = mirror(tileUV * 2.0 + tc * 0.5);

    // Echo depth: receding diamond layers
    vec3 result = vec3(0.0);
    float totalW = 0.0;
    for (float e = 0.0; e < 6.0; e++) {
        float scale = 1.0 + e * (0.1 + mid * 0.05);
        vec2 eUV = tileUV * scale;
        eUV = abs(eUV - 0.5 * scale);
        if (eUV.y > eUV.x) eUV = eUV.yx;
        vec3 s = texture(samp, mirror(eUV * 2.0 + tc * 0.5)).rgb;
        s *= rainbow(e * 0.16 + length(tileID) * 0.2 + iTime * 0.25);
        float w = 1.0 / (1.0 + e * 0.4);
        result += s * w;
        totalW += w;
    }
    result /= totalW;

    // Rainbow facet coloring
    vec3 facetCol = rainbow(length(tileID) * 0.3 + iTime * 0.3 + bass);
    result = mix(result, result * facetCol * 1.3, 0.3 + hiMid * 0.2);

    // Diamond edge glow
    float edge = smoothstep(0.0, 0.05, min(tileUV.x, tileUV.y));
    result = mix(result + rainbow(iTime * 0.5 + treble) * 0.3, result, edge);

    // Color shift
    result = mix(result, result.gbr, air * 0.35);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
