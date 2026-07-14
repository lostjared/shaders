#version 330 core
// rainbow-code-spectral-bloom
// Cinematic spectral bloom with multi-scale halos and a sharp protected source image.

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

const float TAU = 6.28318530718;
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.01, .34, .67)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
vec3 blurRing(vec2 uv, vec2 radius) {
    vec3 s = texture(samp, uv).rgb * .20;
    for (int i = 0; i < 8; i++) {
        float a = (float(i) + .5) * TAU / 8.0;
        s += texture(samp, mirrorUV(uv + vec2(cos(a), sin(a)) * radius)).rgb * .10;
    }
    return s;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float r = length(p), a = atan(p.y, p.x), t = time_f * .22;
    vec2 drift = vec2(cos(a * 3.0 - t), sin(a * 2.0 + t)) * sin(r * 20.0 - t * 3.0) *
                 (.003 + amp_low * .006);
    vec2 uv = mirrorUV(tc + drift);
    vec3 sharp = texture(samp, uv).rgb;
    vec3 nearBlur = blurRing(uv, vec2(.006, .006 * aspect) * (1.0 + amp_mid));
    vec3 farBlur = blurRing(uv, vec2(.018, .018 * aspect) * (1.0 + amp_low * .7));
    float lum = dot(farBlur, vec3(.2126, .7152, .0722));
    float bright = smoothstep(.28, .86, lum);
    float rings = .5 + .5 * sin(r * (28.0 + amp_low * 8.0) - time_f * 2.0);
    vec3 tint = spectral(a / TAU + r * .5 - time_f * .035 + amp_high * .12);
    vec3 bloom = mix(nearBlur, farBlur, .55) * tint * (bright * .72 + .08);
    bloom += tint * pow(rings, 12.0) * (.06 + amp_peak * .34);
    vec3 result = sharp * .84 + bloom * (1.0 + amp_rms * .75);
    result += tint * exp(-r * 5.5) * (.04 + amp_smooth * .16);
    color = vec4(aces(result), texture(samp, uv).a);
}
