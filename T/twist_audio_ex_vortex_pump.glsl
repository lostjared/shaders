#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Bass pumps a vortex that breathes with the beat, tightening at peaks.
void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float pump = pow(bass, 1.5);

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float twistStrength = (1.0 + pump * 10.0) * (1.0 - radius * 0.5);
    float angle = twistStrength + time_f * (1.0 + pump * 3.0);
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * (0.02 + pump * 0.05);
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * (0.02 + pump * 0.05);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
