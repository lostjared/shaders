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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;










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
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
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
