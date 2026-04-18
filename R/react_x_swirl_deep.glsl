#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 center = vec2(0.5);
    vec2 uv = tc - center;
    float dist = length(uv);
    float angle = time_f * (1.0 + aSmth * 3.0) + dist * (5.0 + aLow * 15.0);
    float s = sin(angle), c = cos(angle);

    uv = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);

    float zoom = 1.0 + aMid * 0.3;
    uv *= zoom;
    uv += center;

    color = texture(samp, uv);
}
