#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Sub-bass causes earthquake-like screen-space shake before the twist.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    float subBass = texture(spectrum, 0.02).r;
    vec2 quake = (vec2(hash(vec2(time_f * 7.0, 0.0)), hash(vec2(0.0, time_f * 7.0))) - 0.5) * subBass * 0.06;
    vec2 uv = tc + quake;

    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float radius = length(d);

    float twistStrength = 1.0 + subBass * 4.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(uv.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(uv.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = uv + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
