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
    float angle = atan(uv.y, uv.x);

    float spinAmt = aLow * 4.0 + 0.5;
    float spin1 = spinAmt * dist;
    float spin2 = -spinAmt * dist;

    float a1 = angle + spin1 + time_f * (0.5 + aSmth);
    float a2 = angle + spin2 - time_f * (0.5 + aSmth);

    vec2 uv1 = center + vec2(cos(a1), sin(a1)) * dist;
    vec2 uv2 = center + vec2(cos(a2), sin(a2)) * dist;

    uv1 = clamp(uv1, vec2(0.0), vec2(1.0));
    uv2 = clamp(uv2, vec2(0.0), vec2(1.0));

    vec4 c1 = texture(samp, uv1);
    vec4 c2 = texture(samp, uv2);

    float blendAmt = 0.5 + aMid * 0.3 * sin(time_f * 2.0);
    color = mix(c1, c2, blendAmt);
}
