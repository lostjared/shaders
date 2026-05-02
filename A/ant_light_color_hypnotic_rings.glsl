#version 330 core
// ant_light_color_hypnotic_rings
// Concentric hypnotic rings with alternating color rotation and depth pulse

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Ring index and fractional position
    float ringFreq = 12.0 + bass * 8.0;
    float ringPhase = r * ringFreq - iTime * 2.0;
    float ringIdx = floor(ringPhase);
    float ringFrac = fract(ringPhase);

    // Alternating rotation per ring
    float ringRot = mod(ringIdx, 2.0) * 2.0 - 1.0;
    float rotAngle = ringRot * iTime * (1.0 + mid) + ringIdx * 0.5;

    vec2 ringUV = rot(rotAngle) * p;
    ringUV.x /= aspect;
    vec2 sampUV = ringUV * (0.5 + ringFrac * 0.3) + 0.5;

    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Ring color cycling
    vec3 ringColor = rainbow(ringIdx * 0.15 + iTime * 0.2 + bass);
    col *= mix(vec3(1.0), ringColor, 0.3 + mid * 0.4);

    // Ring edge glow
    float edgeDist = abs(ringFrac - 0.5);
    float edgeGlow = smoothstep(0.5, 0.45, edgeDist);
    col += rainbow(ringIdx * 0.1 + iTime * 0.3) * (1.0 - edgeGlow) * (0.5 + air * 1.5);

    // Depth pulse: brightness oscillation
    float pulse = sin(ringPhase * 3.14159) * 0.5 + 0.5;
    col *= 0.7 + pulse * 0.6;

    // Center eye
    float eye = exp(-r * (5.0 - bass * 3.0));
    col += rainbow(iTime * 0.4) * eye * (1.0 + amp_peak * 3.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
