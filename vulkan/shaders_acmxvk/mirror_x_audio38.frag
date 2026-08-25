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
#define amp ext.u1.y
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;









vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float dp = max(abs(p.x), abs(p.y));
    float diamondA = atan(abs(p.y), abs(p.x));
    float scale = 1.0 + 0.3 * aLow * sin(t * 2.0);
    dp *= scale;
    float twist = t * 0.5 + aMid * 1.5;
    diamondA += twist * exp(-dp * 2.0);
    vec2 warped = vec2(cos(diamondA), sin(diamondA)) * dp;
    warped.x /= aspect;
    warped += 0.5;
    warped = mirror(warped);
    vec4 tex = texture(samp, warped);
    float pulse = 0.5 + 0.5 * sin(dp * 15.0 - t * 4.0);
    pulse *= aHigh * 0.2;
    tex.rgb += pulse * vec3(0.2, 0.5, 1.0);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
