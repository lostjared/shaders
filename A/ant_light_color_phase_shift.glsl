#version 330 core
// ant_light_color_phase_shift
// RGB phase-shifted channels with kaleidoscope fold and spectrum-driven offset

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

vec2 kaleidoscope(vec2 p, float seg) {
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = TAU / seg;
    ang = mod(ang, s);
    ang = abs(ang - s * 0.5);
    return vec2(cos(ang), sin(ang)) * r;
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(p);

    // Phase offsets per channel driven by spectrum
    float phaseR = iTime * 0.7 + bass * 3.0;
    float phaseG = iTime * 0.7 + mid * 3.0 + TAU / 3.0;
    float phaseB = iTime * 0.7 + treble * 3.0 + TAU * 2.0 / 3.0;

    float seg = 6.0 + floor(bass * 6.0);

    // Each channel gets different rotation + kaleidoscope
    vec2 pR = kaleidoscope(rot(phaseR * 0.1) * p, seg);
    vec2 pG = kaleidoscope(rot(phaseG * 0.1) * p, seg);
    vec2 pB = kaleidoscope(rot(phaseB * 0.1) * p, seg);

    pR.x /= aspect; pG.x /= aspect; pB.x /= aspect;

    vec3 col;
    col.r = texture(samp, pR + 0.5).r;
    col.g = texture(samp, pG + 0.5).g;
    col.b = texture(samp, pB + 0.5).b;

    // Phase interference pattern
    float interference = sin(r * 20.0 + phaseR) + sin(r * 20.0 + phaseG) + sin(r * 20.0 + phaseB);
    interference /= 3.0;
    float glow = pow(max(interference, 0.0), 4.0);
    col += rainbow(r + iTime * 0.2) * glow * (0.3 + air * 0.8);

    // Center convergence
    float center = exp(-r * (4.0 - bass * 2.0));
    col += rainbow(iTime * 0.3) * center * (0.5 + amp_peak * 2.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
