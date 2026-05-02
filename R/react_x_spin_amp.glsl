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
    float angle = time_f * (0.5 + aSmth * 2.0) + aLow * 8.0;
    float s = sin(angle), c = cos(angle);
    mat2 rotation = mat2(c, -s, s, c);
    vec2 rotatedUV = rotation * uv;

    float zoom = 1.0 + aMid * 0.3;
    rotatedUV *= zoom;

    color = texture(samp, rotatedUV + 0.5);
}
