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










float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    // Peak-driven pixel scatter intensity
    float scatterAmt = amp_peak * 0.08 + amp_rms * 0.02;

    // Block size from mids
    float blockSize = 16.0 + amp_mid * 48.0;
    vec2 block = floor(tc * iResolution / blockSize);

    // Each block gets a random displacement on peaks
    float h1 = hash(block + floor(time_f * 6.0));
    float h2 = hash(block.yx + floor(time_f * 6.0) + 37.0);

    vec2 offset = vec2(0.0);
    if (h1 < amp_peak * 0.4) {
        offset.x = (h1 - 0.5) * scatterAmt * 2.0;
        offset.y = (h2 - 0.5) * scatterAmt * 2.0;
    }

    vec2 uv = tc + offset;

    // Bass adds a global wave scatter
    uv.x += amp_low * 0.015 * sin(tc.y * 30.0 + time_f * 4.0);
    uv.y += amp_low * 0.01 * cos(tc.x * 25.0 + time_f * 3.0);

    vec4 tex = texture(samp, clamp(uv, 0.0, 1.0));

    // Treble noise overlay
    float noise = hash(tc * iResolution + time_f) * amp_high * 0.15;
    tex.rgb += noise;

    // Smooth brightness
    tex.rgb *= 1.0 + amp_smooth * 0.2;

    // Peak brightness flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
