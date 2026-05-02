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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 uv = tc - 0.5;
    float radius = length(uv);
    float angle = atan(uv.y, uv.x);

    float twist = 10.0 + aLow * 20.0;
    float speed = 0.5 + aSmth * 2.0;
    angle += radius * twist + time_f * speed;

    vec2 spiralUV = vec2(cos(angle), sin(angle)) * radius;
    float zoom = 1.0 - aMid * 0.2;
    color = texture(samp, spiralUV * zoom + 0.5);
}
