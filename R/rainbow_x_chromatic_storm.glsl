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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    float r = length(uv);
    float theta = atan(uv.y, uv.x);

    float stormRotation = time_f * mix(0.5, 3.0, aSmth);
    float stormTwist = aLow * 6.0 + 2.0;
    vec2 stormUV = rotate2D(uv, stormRotation + r * stormTwist);

    float warp = sin(stormUV.x * 8.0 + time_f * 2.0) * (0.02 + aLow * 0.04);
    warp += cos(stormUV.y * 6.0 + time_f * 1.5) * (0.02 + aMid * 0.03);

    float chromaStr = 0.005 + aPk * 0.025 + aHigh * 0.01;
    vec2 chromaDir = normalize(uv + 0.001) * chromaStr;

    vec2 tcR = tc + chromaDir + vec2(warp, 0.0);
    vec2 tcG = tc + vec2(0.0, warp);
    vec2 tcB = tc - chromaDir - vec2(warp, 0.0);

    float rChan = texture(samp, tcR).r;
    float gChan = texture(samp, tcG).g;
    float bChan = texture(samp, tcB).b;
    vec3 texColor = vec3(rChan, gChan, bChan);

    float hue = fract(theta / 6.28318 + time_f * 0.1 + r * 0.5 + aHigh * 0.5);
    vec3 stormRainbow = rainbow(hue);

    float ringPulse = 0.5 + 0.5 * sin(r * (12.0 + aLow * 10.0) - time_f * 3.0);
    ringPulse *= mix(0.5, 1.5, aPk);

    float mixAmt = 0.3 + aMid * 0.3;
    vec3 finalColor = mix(texColor, texColor * stormRainbow, mixAmt);
    finalColor *= 0.85 + 0.15 * ringPulse;

    finalColor *= 1.0 + aPk * 0.7;
    finalColor = mix(finalColor,
                     finalColor * vec3(1.0 + aLow * 0.3, 1.0 - aLow * 0.1, 1.0 + aHigh * 0.3),
                     aPk);

    float time_t = pingPong(time_f, 10.0) + 1.5;
    color = vec4(sin(finalColor * time_t), 1.0);
}
