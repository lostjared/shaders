#version 330 core
// ant_light_color_quantum_fold
// Quantum interference fold patterns with probability-cloud color and bass collapse

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 quantum(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.8, 0.9, 0.3);
    return a + b * cos(TAU * (c * t + d));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Quantum fold: iterative folding with collapse
    vec2 q = p * (3.0 + bass * 2.0);
    float energy = 0.0;
    for (int i = 0; i < 8; i++) {
        q = abs(q);
        if (q.x < q.y) q = q.yx;
        q -= 0.5 + hiMid * 0.2;
        q = rot(iTime * 0.15 + float(i) * 0.4) * q;
        q *= 1.15;
        float d = dot(q, q);
        energy += exp(-d * (2.0 + treble * 4.0));
    }

    // Interference pattern
    float interference = sin(energy * 10.0 - iTime * 3.0) * 0.5 + 0.5;

    // Texture through fold space
    vec2 sampUV = fract(q * 0.05 + tc);
    float chroma = (treble + air) * 0.04 * interference;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Quantum probability cloud color
    vec3 qColor = quantum(energy * 0.3 + iTime * 0.1);
    col = mix(col, col * qColor * 2.0, 0.3 + mid * 0.4);

    // Interference fringes glow
    col += quantum(energy + iTime * 0.15) * pow(interference, 4.0) * (0.4 + air * 1.0);

    // Bass collapse flash
    float collapse = exp(-energy * 0.5) * bass;
    col += quantum(iTime * 0.2) * collapse * 2.0;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
