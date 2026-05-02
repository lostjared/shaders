#version 330 core
// ant_light_color_neon_mandala
// Sacred mandala geometry with neon dot/line patterns and breathing symmetry

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 neon(float t) {
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

    // Breathing zoom
    p *= 1.0 - bass * 0.3 + sin(iTime * 0.5) * 0.05;
    p = rot(iTime * 0.1) * p;

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Multi-fold symmetry
    float folds = 8.0 + floor(mid * 8.0);
    float stepA = TAU / folds;
    angle = mod(angle, stepA);
    angle = abs(angle - stepA * 0.5);

    // Mandala concentric rings
    float ringPattern = sin(r * (20.0 + treble * 15.0) - iTime * 2.0);
    float ringLine = smoothstep(0.0, 0.1, abs(ringPattern));

    // Radial spoke lines
    float spoke = smoothstep(0.03, 0.0, abs(angle) * r);

    // Dot grid along rings
    float dotAngle = mod(angle, stepA / 4.0);
    float dotR = mod(r * 10.0 + iTime * 0.5, 1.0);
    float dot_val = smoothstep(0.1, 0.0, length(vec2(dotAngle * r * 10.0, dotR) - 0.5));

    // Texture sample through mandala fold
    vec2 kUV = vec2(cos(angle), sin(angle)) * r;
    kUV.x /= aspect;
    vec2 sampUV = kUV + 0.5;

    vec3 col = texture(samp, sampUV).rgb;

    // Neon pattern overlay
    float pattern = max(max(1.0 - ringLine, spoke), dot_val);
    col += neon(r + iTime * 0.2 + angle / TAU) * pattern * (0.5 + air * 2.0);

    // Inner glow
    float inner = exp(-r * (3.0 - bass * 2.0));
    col += neon(iTime * 0.25) * inner * (1.0 + amp_peak * 2.0);

    // Color wash
    col *= neon(r * 2.0 - iTime * 0.15 + bass * 0.5) * 0.4 + 0.8;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
