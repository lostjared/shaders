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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    float time_z = pingPong(time_f, 4.0) + 0.5;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 normPos = uv * 2.0 - 1.0 * time_z;
    float dist = length(normPos);

    float phaseSpeed = mix(3.0, 6.0, aRms);
    float phase = sin(dist * (10.0 + aLow * 8.0) - time_f * phaseSpeed);
    vec2 tcAdjusted = tc + (normPos * 0.305 * phase);

    float dispersionScale = 0.02 + aPk * 0.04;
    vec2 dispersionOffset = normPos * dist * dispersionScale;

    float r = texture(samp, tcAdjusted - dispersionOffset).r;
    float g = texture(samp, tcAdjusted).g;
    float b = texture(samp, tcAdjusted + dispersionOffset).b;
    vec3 texColor = vec3(r, g, b);

    float angle = atan(normPos.y, normPos.x) + time_f * (1.0 + aHigh);
    float hue = mod((angle + aHigh * 3.14159) / 6.28318, 1.0);
    vec3 rainbowColor = hsv2rgb(vec3(hue, 0.8 + aMid * 0.2, 1.0));

    float mixAmt = 0.3 + 0.4 * aMid;
    vec3 finalColor = mix(texColor, texColor * rainbowColor, mixAmt);

    finalColor *= 1.0 + aPk * 0.7;
    finalColor = mix(finalColor,
                     finalColor * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.3),
                     aPk);

    float time_t = pingPong(time_f, 8.0) + 2.0;
    color = vec4(sin(finalColor * time_t), 1.0);
}
