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

vec3 getRainbowColor(float t) {
    float r = 0.5 + 0.5 * cos(6.28318 * (t + 0.0));
    float g = 0.5 + 0.5 * cos(6.28318 * (t + 0.333));
    float b = 0.5 + 0.5 * cos(6.28318 * (t + 0.666));
    return vec3(r, g, b);
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);

    float chromaStr = 0.01 + aPk * 0.04;
    vec2 redOffset   = vec2(sin(time_f * 5.0), cos(time_f * 5.0)) * chromaStr;
    vec2 greenOffset = vec2(cos(time_f * 7.0), sin(time_f * 7.0)) * chromaStr;
    vec2 blueOffset  = vec2(sin(time_f * 3.0), cos(time_f * 3.0)) * chromaStr;

    float r = texture(samp, tc + redOffset).r;
    float g = texture(samp, tc + greenOffset).g;
    float b = texture(samp, tc + blueOffset).b;

    vec4 originalColor = vec4(r, g, b, 1.0);
    float hueSpeed = 0.05 + aHigh * 0.2;
    vec3 rainbowColor = getRainbowColor(time_f * hueSpeed + aMid * 0.5);
    float mixAmt = 0.3 + aMid * 0.4;
    vec3 mixedColor = mix(originalColor.rgb, rainbowColor, mixAmt);

    float beat = aPk;
    color = vec4(mix(originalColor.rgb, mixedColor, beat), 1.0);
}
