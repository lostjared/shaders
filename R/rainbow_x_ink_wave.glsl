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

float noise(vec2 p, sampler2D s) {
    return texture(s, p * 0.1).r;
}

vec2 swirl(vec2 p, float t, float audioStr) {
    float radius = length(p);
    float swirlAmt = 0.5 + audioStr * 1.5;
    float angle = atan(p.y, p.x) + sin(t + radius * 10.0 + noise(p * 10.0, samp) * 10.0) * swirlAmt;
    return vec2(cos(angle), sin(angle)) * radius;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aSmth = clamp(amp_smooth, 0.0, 1.0);

    float mod_time = mod(time_f, 25.0);
    vec2 uv = tc * 2.0 - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    uv = swirl(uv, mod_time * 0.1, aLow);
    uv *= 0.5 + aPk * 0.3;

    float n = noise(uv * (0.5 + aHigh * 2.0) + mod_time * 0.05, samp);
    float hueSpeed = mix(0.05, 0.3, aSmth);
    vec3 rainbow_color = rainbow(n + mod_time * hueSpeed + aMid * 0.5);

    vec4 tex = texture(samp, tc);
    float inkSpread = 0.4 + aLow * 0.4;
    vec3 blended = mix(tex.rgb, rainbow_color, inkSpread);

    blended *= 1.0 + aPk * 0.6;
    blended = mix(blended,
                  blended * vec3(1.0 + aLow * 0.2, 1.0 + aMid * 0.15, 1.0 + aHigh * 0.25),
                  aSmth);

    color = vec4(blended, 1.0);
}
