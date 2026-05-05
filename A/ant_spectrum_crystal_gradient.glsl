#version 330 core
// ant_spectrum_crystal_gradient
// Crystal gradient field with mirror symmetry, echo facets, and rainbow band shifts

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.20).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.55).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Crystal symmetry: quad mirror + rotation
    uv *= rot(iTime * 0.03);
    uv = abs(uv);
    if (uv.y > uv.x) uv = uv.yx;
    uv = abs(uv);

    // Voronoi-like crystal structure
    float cellSize = 0.3 + bass * 0.15;
    vec2 cellID = floor(uv / cellSize);
    vec2 cellUV = fract(uv / cellSize) - 0.5;
    cellUV = abs(cellUV);

    // Gradient field: smooth color bands across crystals
    float gradT = length(cellID) * 0.2 + dot(cellUV, vec2(1.0)) + iTime * 0.3;
    vec3 gradColor = rainbow(gradT + bass);

    // Map to texture
    vec2 texUV = mirror(cellUV * 2.0 + tc);

    // Echo facets
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float cellRot = hash(cellID + e) * PI;
        vec2 eUV = cellUV * rot(cellRot * 0.3);
        eUV = abs(eUV);
        vec3 s = texture(samp, mirror(eUV * 2.0 + tc + vec2(e * 0.01))).rgb;
        s *= rainbow(e * 0.2 + gradT + iTime * 0.15);
        result += s * (1.0 / (1.0 + e * 0.35));
    }
    result /= 2.8;

    // Apply gradient coloring
    result = mix(result, result * gradColor * 1.4, 0.35 + mid * 0.2);

    // Band shift: horizontal rainbow bands
    float band = sin(uv.y * 10.0 + iTime * 2.0) * 0.5 + 0.5;
    result = mix(result, result * rainbow(band + iTime * 0.2), 0.2 * hiMid);

    // Color shift
    result = mix(result, result.brg, treble * 0.4);

    // Edge highlight
    float edge = smoothstep(0.0, 0.05, min(0.5 - abs(cellUV.x), 0.5 - abs(cellUV.y)));
    result = mix(result + rainbow(iTime * 0.5) * 0.3, result, edge);

    result += air * 0.06 * rainbow(iTime + length(uv));
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
