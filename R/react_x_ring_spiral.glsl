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
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec2 center = vec2(0.5);
    vec2 uv = tc - center;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    float numRings = 6.0 + aLow * 8.0;
    float ringPhase = dist * numRings - time_f * (1.0 + aSmth * 3.0);
    float ringMask = 0.5 + 0.5 * sin(ringPhase * 6.28318);

    float spiralSpeed = 1.0 + aRms * 3.0;
    float spiralTwist = 5.0 + aMid * 10.0;
    float spiralAngle = angle + dist * spiralTwist + time_f * spiralSpeed;
    float s = sin(spiralAngle), c = cos(spiralAngle);
    vec2 warpUV = center + vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c) * (1.0 + aPk * 0.2);

    vec4 tex = texture(samp, warpUV);

    float hue = fract(angle / 6.28318 + dist * 2.0 + time_f * 0.1 + aHigh * 0.5);
    vec3 rainbowColor = rainbow(hue);

    float rainbowMix = ringMask * (0.3 + aPk * 0.4);
    vec3 finalColor = mix(tex.rgb, rainbowColor, rainbowMix);

    finalColor *= 1.0 + aPk * 0.5;
    finalColor = mix(finalColor,
                     finalColor * vec3(1.0 + aLow * 0.2, 1.0 + aMid * 0.15, 1.0 + aHigh * 0.2),
                     aSmth);

    color = vec4(finalColor, 1.0);
}
