#version 330 core
// ant_light_color_helix_aurora
// DNA double helix with aurora-colored connecting bars and twisting glow

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 aurora(float t) {
    vec3 a = vec3(0.1, 0.4, 0.2);
    vec3 b = vec3(0.3, 0.5, 0.4);
    vec3 c = vec3(1.0, 1.0, 0.5);
    vec3 d = vec3(0.0, 0.33, 0.67);
    return a + b * cos(TAU * (c * t + d));
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Scroll along helix
    float scroll = uv.y * 8.0 + iTime * (1.5 + bass * 2.0);

    // Two helix strands
    float helixWidth = 0.25 + mid * 0.1;
    float strand1X = sin(scroll) * helixWidth;
    float strand2X = sin(scroll + 3.14159) * helixWidth;

    float d1 = abs(uv.x - strand1X);
    float d2 = abs(uv.x - strand2X);

    float strandGlow1 = 0.003 / (d1 * d1 + 0.001);
    float strandGlow2 = 0.003 / (d2 * d2 + 0.001);

    // Connecting bars between strands
    float barPhase = fract(scroll * 0.5);
    float barY = abs(barPhase - 0.5) * 2.0;
    float inBar = step(barY, 0.1);
    float barX = mix(strand1X, strand2X, fract(scroll * 0.5));
    float betweenStrands = smoothstep(min(strand1X, strand2X) - 0.01, min(strand1X, strand2X), uv.x)
                         * smoothstep(max(strand1X, strand2X) + 0.01, max(strand1X, strand2X), uv.x);
    // Simplified bar: glow between strands at intervals
    float barInterval = abs(sin(scroll * 3.0));
    float bar = (1.0 - betweenStrands) * step(0.9, barInterval) * smoothstep(0.05, 0.0, abs(uv.x - (strand1X + strand2X) * 0.5));

    // Texture sample
    vec2 sampUV = tc + vec2((strandGlow1 - strandGlow2) * 0.005, 0.0);
    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Strand glow colors
    col += aurora(scroll * 0.1 + 0.0) * min(strandGlow1, 3.0) * (0.3 + air * 0.5);
    col += aurora(scroll * 0.1 + 0.5) * min(strandGlow2, 3.0) * (0.3 + air * 0.5);

    // Bar glow
    col += aurora(scroll * 0.2 + iTime * 0.1) * bar * (2.0 + bass * 3.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
