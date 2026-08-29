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









void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float shatter = floor(atan(uv.y - 0.5, uv.x - 0.5) * (3.0 + 3.0 * aLow) / 3.14159);
    float shatterAngle = shatter * 0.5 + t * 0.3;
    float cs = cos(shatterAngle), sn = sin(shatterAngle);
    vec2 p = uv - 0.5;
    uv = vec2(p.x * cs - p.y * sn, p.x * sn + p.y * cs) + 0.5;
    uv += (uv - 0.5) * 0.1 * aMid * sin(t * 3.0 + shatter);
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float edge = abs(fract(shatter * 0.5) - 0.5) * 2.0;
    edge = smoothstep(0.9, 1.0, edge) * aHigh * 0.3;
    tex.rgb += edge * vec3(1.0, 0.6, 0.2);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
