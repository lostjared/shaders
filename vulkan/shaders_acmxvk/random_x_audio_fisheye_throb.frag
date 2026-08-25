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
    vec2 center = vec2(0.5);
    vec2 delta = tc - center;
    float dist = length(delta * vec2(iResolution.x / iResolution.y, 1.0));

    // Bass pulses the fisheye lens intensity
    float lensStrength = 0.3 + amp_low * 0.8;
    float lensRadius = 0.8 + amp_smooth * 0.3;

    vec2 uv = tc;
    if (dist < lensRadius) {
        float normalDist = dist / lensRadius;
        float bend = normalDist * normalDist * lensStrength;
        uv = center + delta * (1.0 + bend);
    }

    // Mids add a secondary wobble
    uv.x += amp_mid * 0.01 * sin(uv.y * 20.0 + time_f * 3.0);
    uv.y += amp_mid * 0.008 * cos(uv.x * 15.0 + time_f * 2.5);

    uv = clamp(uv, 0.0, 1.0);

    // Treble chromatic split
    float chroma = amp_high * 0.015;
    float r = texture(samp, clamp(uv + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, clamp(uv - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Peak breathing flash
    col *= 1.0 + smoothstep(0.5, 1.0, amp_peak) * 0.35;

    // RMS warmth
    col.r += amp_rms * 0.04;
    col.g += amp_rms * 0.02;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
