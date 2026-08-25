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
    // RMS controls mosaic resolution (low RMS = big pixels, high RMS = small pixels)
    float mosaicSize = mix(64.0, 4.0, clamp(amp_rms * 3.0, 0.0, 1.0));
    vec2 mosaicUV = floor(tc * iResolution / mosaicSize) * mosaicSize / iResolution;

    // Center of each mosaic cell
    vec2 cellCenter = mosaicUV + (mosaicSize * 0.5) / iResolution;

    vec3 tex = texture(samp, cellCenter).rgb;

    // Bass adds color quantization (fewer colors on beat)
    float levels = 16.0 - amp_low * 12.0;
    levels = max(levels, 2.0);
    tex = floor(tex * levels) / levels;

    // Mids shift cell borders
    vec2 cellFrac = fract(tc * iResolution / mosaicSize);
    float border = step(cellFrac.x, 0.05 + amp_mid * 0.1) + step(cellFrac.y, 0.05 + amp_mid * 0.1);
    border = min(border, 1.0);
    tex = mix(tex, tex * 0.5, border * 0.5);

    // Treble adds sparkle to random cells
    float sparkle = fract(sin(dot(mosaicUV, vec2(12.9898, 78.233)) + time_f) * 43758.5453);
    if (sparkle < amp_high * 0.2) {
        tex += amp_high * 0.4;
    }

    // Peak flash
    tex += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth brightness
    tex *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(tex, 0.0, 1.0), 1.0);
}
