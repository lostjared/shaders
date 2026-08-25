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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 ap = abs(p);

    // Diamond distance
    float diamond = ap.x + ap.y;

    // Bass pulses diamond rings
    float ringFreq = 8.0 + amp_low * 20.0;
    float rings = sin(diamond * ringFreq - time_f * (2.0 + amp_low * 5.0));
    rings = smoothstep(0.0, 0.3, rings);

    // Mids rotate the diamond pattern
    float ca = time_f * (0.3 + amp_mid * 1.5);
    float cc = cos(ca), ss = sin(ca);
    vec2 rp = vec2(cc * p.x - ss * p.y, ss * p.x + cc * p.y);
    float diamond2 = abs(rp.x) + abs(rp.y);

    // Sample texture with diamond distortion
    float warp = rings * (0.03 + amp_peak * 0.05);
    vec2 uv = tc + normalize(p + 0.001) * warp;
    uv = clamp(uv, 0.0, 1.0);

    vec4 tex = texture(samp, uv);

    // Treble adds diamond edge glow
    float edge = fract(diamond * 4.0 + time_f * 0.5);
    edge = smoothstep(0.45, 0.5, edge) - smoothstep(0.5, 0.55, edge);
    vec3 glow = vec3(0.8, 0.3, 1.0) * edge * amp_high * 2.0;
    tex.rgb += glow;

    // Peak brightness flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth amp warmth
    tex.rgb *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
