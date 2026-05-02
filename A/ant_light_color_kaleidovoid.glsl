#version 330 core
// ant_light_color_kaleidovoid
// Deep void kaleidoscope with recursive fold zoom and chromatic bloom

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 voidColor(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.1, 0.4, 0.7)));
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

    // Recursive fold zoom
    float seg = 6.0 + floor(bass * 4.0);
    for (int i = 0; i < 4; i++) {
        float angle = atan(p.y, p.x);
        float r = length(p);
        float stepA = TAU / seg;
        angle = mod(angle, stepA);
        angle = abs(angle - stepA * 0.5);
        p = vec2(cos(angle), sin(angle)) * r;

        p = abs(p) - (0.3 - float(i) * 0.05);
        p = rot(iTime * 0.05 + float(i) * 0.7 + mid * 0.3) * p;
        p *= 1.3;
    }

    p.x /= aspect;
    vec2 sampUV = p + 0.5;

    // Chromatic bloom dispersion
    float disp = (treble + air) * 0.05;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(disp, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(disp, 0.0)).b;

    // Void depth color
    float depth = length(p);
    col *= voidColor(depth * 0.5 + iTime * 0.1 + bass) * 1.5;

    // Fold edge glow
    float edgeGlow = 0.01 / (min(abs(p.x), abs(p.y)) + 0.01);
    edgeGlow = min(edgeGlow, 3.0);
    col += voidColor(depth + iTime * 0.2) * edgeGlow * (0.1 + air * 0.3);

    // Center void
    float voidCenter = exp(-depth * (2.0 - bass * 1.5));
    col += voidColor(iTime * 0.3) * voidCenter * (1.0 + amp_peak * 3.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
