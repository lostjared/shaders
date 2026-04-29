#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// On loud peaks the image collapses inward as the twist accelerates.
void main(void) {
    float bass = texture(spectrum, 0.05).r;
    float mid  = texture(spectrum, 0.35).r;
    float loud = clamp(bass + mid, 0.0, 1.0);

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float collapse = mix(1.0, 0.4, loud);
    d *= collapse;
    radius = length(d);

    float twistStrength = 1.0 + loud * 8.0;
    float angle = twistStrength * (radius - 1.0) + time_f * (1.0 + loud * 3.0);
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
