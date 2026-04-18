#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);

    vec2 uv = tc;
    float hueSpeed = 0.05 + aHigh * 0.2;
    vec3 rainbowColor = rainbow(uv.x + time_f * hueSpeed + aMid * 0.5);

    float yWave = sin(uv.x * (15.0 + aLow * 20.0) + time_f * 3.0) * (0.01 + aLow * 0.03);
    vec4 texColor = texture(samp, uv + vec2(0.0, yWave));

    float mixAmt = 0.3 + aMid * 0.4;
    color = mix(texColor, vec4(rainbowColor, 1.0), mixAmt);
}
