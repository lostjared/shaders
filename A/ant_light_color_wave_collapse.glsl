#version 330 core
// ant_light_color_wave_collapse
// Standing wave interference collapse with node glow and spectrum harmonic colors

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 harmonic(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Standing waves in X and Y
    float freqX = 8.0 + bass * 6.0;
    float freqY = 8.0 + mid * 6.0;
    float waveX = sin(uv.x * freqX * TAU + iTime * 3.0);
    float waveY = sin(uv.y * freqY * TAU + iTime * 2.5);

    // Interference pattern
    float standing = waveX * waveY;
    float nodes = 1.0 - abs(standing);
    float antinodes = abs(standing);

    // Collapse: bass drives transition from wave to particle
    float collapse = bass;
    float pattern = mix(standing, pow(antinodes, 4.0), collapse);

    // UV distortion from wave
    vec2 distort = vec2(waveX, waveY) * 0.02 * (1.0 + mid);
    vec2 sampUV = tc + distort;

    float chroma = treble * 0.03 + antinodes * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Harmonic color based on position in wave
    float harmIdx = atan(waveY, waveX) / TAU + 0.5;
    col *= harmonic(harmIdx + iTime * 0.15) * 1.3;

    // Node glow (where waves cancel)
    float nodeGlow = pow(nodes, 8.0);
    col += harmonic(uv.x + uv.y + iTime * 0.2) * nodeGlow * (0.5 + air * 1.5);

    // Antinode brightness pulse
    col += harmonic(iTime * 0.3) * pow(antinodes, 6.0) * bass * 0.5;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
