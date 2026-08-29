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










float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float y = tc.y * iResolution.y;

    // Peak drives horizontal tear intensity
    float tearStrength = amp_peak * 0.1;
    float tearFreq = 8.0 + amp_low * 20.0;

    // Random horizontal bands that tear on peaks
    float bandIndex = floor(y / tearFreq);
    float bandHash = hash(bandIndex + floor(time_f * 4.0));

    if (bandHash < amp_peak * 0.6) {
        // Tear this band
        float tearOffset = (bandHash - 0.3) * tearStrength;
        uv.x += tearOffset;

        // Bass makes some bands jump vertically
        if (bandHash < amp_low * 0.3) {
            float jumpHash = hash(bandIndex * 13.0 + time_f);
            uv.y += (jumpHash - 0.5) * amp_low * 0.04;
        }
    }

    // Mids add subtle wave across all lines
    uv.x += amp_mid * 0.005 * sin(y * 0.1 + time_f * 3.0);

    uv = clamp(uv, 0.0, 1.0);

    // Treble chromatic tear
    float chromaTear = amp_high * 0.01 * step(bandHash, amp_peak * 0.4);
    float r = texture(samp, clamp(vec2(uv.x + chromaTear, uv.y), 0.0, 1.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, clamp(vec2(uv.x - chromaTear, uv.y), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Scanline darken
    float scanline = 0.97 + 0.03 * sin(y * 3.14159);
    col *= scanline;

    // RMS brightness
    col *= 1.0 + amp_rms * 0.2;

    // Peak flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.15;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
