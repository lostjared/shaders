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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    vec2 uv = tc;
    float amplitude = aRms * 0.8 + 0.1;
    float freq = 10.0 + aLow * 15.0;
    float speed = 1.0 + aHigh * 3.0;
    vec2 distortedUV = uv + vec2(
                                sin(uv.y * freq + time_f * speed) * 0.1,
                                cos(uv.x * freq + time_f * speed) * 0.1) *
                                amplitude;
    color = texture(samp, distortedUV);
}
