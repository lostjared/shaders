#version 330 core
// ant_spectrum_rainbow_shatter
// Shattered glass mirror with rainbow refractions and echo fragments

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Shatter: grid of mirrored cells with random offsets
    float cellSize = 0.15 + bass * 0.1;
    vec2 cellID = floor(uv / cellSize);
    vec2 cellUV = fract(uv / cellSize) - 0.5;

    // Random rotation and offset per cell
    float cellHash = hash(cellID);
    float cellRot = cellHash * PI * 2.0 + iTime * 0.3 * (cellHash - 0.5);
    cellUV *= rot(cellRot);

    // Mirror within each cell
    cellUV = abs(cellUV);

    // Refraction offset per cell
    vec2 refract = vec2(cellHash - 0.5) * 0.1 * (1.0 + mid);

    // Map to texture
    vec2 texUV = mirror(cellUV * 2.0 + tc + refract);

    // Rainbow chromatic split per shard
    float spread = 0.01 + treble * 0.04;
    vec3 result;
    result.r = texture(samp, mirror(texUV + vec2(spread * cellHash, 0.0))).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - vec2(spread * cellHash, 0.0))).b;

    // Echo fragments
    for (float e = 1.0; e < 4.0; e++) {
        float freq = texture(spectrum, e * 0.1).r;
        vec2 eRefract = refract * (1.0 + e * 0.2);
        vec3 echoCol = texture(samp, mirror(cellUV * 2.0 + tc + eRefract)).rgb;
        echoCol *= rainbow(cellHash + e * 0.25 + iTime * 0.2 + freq);
        result += echoCol * (0.25 / e);
    }

    // Shard edge glow
    vec2 edgeDist = 0.5 - abs(fract(uv / cellSize) - 0.5);
    float edge = smoothstep(0.0, 0.05 + hiMid * 0.03, min(edgeDist.x, edgeDist.y));
    vec3 edgeColor = rainbow(cellHash + iTime * 0.4);
    result = mix(result + edgeColor * 0.5, result, edge);

    // Color shift
    result = mix(result, result.brg, air * 0.4);

    // Gradient
    float dist = length(uv);
    result *= mix(vec3(1.0), rainbow(dist + iTime * 0.3), 0.2);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
