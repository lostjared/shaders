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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);

    float chromaStr = 0.01 + aPk * 0.04;
    float rSpeed = 5.0 + aLow * 8.0;
    float gSpeed = 7.0 + aMid * 6.0;
    float bSpeed = 3.0 + aHigh * 10.0;

    vec2 redOffset = vec2(sin(time_f * rSpeed), cos(time_f * rSpeed)) * chromaStr;
    vec2 greenOffset = vec2(cos(time_f * gSpeed), sin(time_f * gSpeed)) * chromaStr;
    vec2 blueOffset = vec2(sin(time_f * bSpeed), cos(time_f * bSpeed)) * chromaStr;

    float r = texture(samp, tc + redOffset).r;
    float g = texture(samp, tc + greenOffset).g;
    float b = texture(samp, tc + blueOffset).b;

    vec3 col = vec3(r, g, b);
    col *= 1.0 + aPk * 0.5;
    color = vec4(col, 1.0);
}
