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









float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float spiral = r * (6.0 + 4.0 * aLow) + t * 2.0;
    a += sin(spiral) * 0.3 * aMid;
    r *= 1.0 + 0.1 * sin(a * 3.0 + t);
    vec2 warped = vec2(cos(a), sin(a)) * r;
    warped.x /= aspect;
    warped += 0.5;
    float pp = pingPong(t * 0.3, 3.0) / 3.0;
    warped = mix(warped, fract(warped * 2.0), pp * aMid);
    vec4 tex = texture(samp, fract(warped));
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
