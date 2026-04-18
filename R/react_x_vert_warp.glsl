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
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    float amplitude = aLow * 3.0 + 0.2;
    float distFromCenter = abs(tc.y - 0.5);
    vec2 distorted_tc = tc;
    float warpFreq = 1.0 + aMid * 4.0;
    distorted_tc.y += amplitude * (0.5 - distFromCenter) * distFromCenter * sin(time_f * warpFreq);
    distorted_tc.x += aPk * 0.05 * sin(tc.y * 30.0 + time_f * 8.0);
    distorted_tc = clamp(distorted_tc, vec2(0.0), vec2(1.0));
    color = texture(samp, distorted_tc);
}
