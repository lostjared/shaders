#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

// rainbow-code-spectral-bloom
// Cinematic spectral bloom with multi-scale halos and a sharp protected source image.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;










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
