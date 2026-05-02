#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform float time_speed;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI = 3.1415926535897932384626433832795;
const float TAU = 6.28318530718;

void main(void) {
    vec2 uv = tc;

    // 1. The Zero-Axis Pull
    // Lines are sucked toward the center as the "negative energy" increases.
    float pull = (amp_low * 0.2);
    vec2 center_dist = uv - 0.5;
    uv -= center_dist * pull * sin(iTime * 2.0);

    // 2. Fragmented Scanlines
    // High-frequency jitter to mimic the "fragment the eye" lyric.
    float scan_jitter = sin(uv.y * 100.0 + iTime * 10.0) * (amp_high * 0.02);
    uv.x += scan_jitter;

    // 3. Chromatic Shift (The Neon Tide)
    float shift = amp_smooth * 0.05;
    float r = texture(samp, uv + vec2(shift, 0.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - vec2(shift, 0.0)).b;
    vec3 tex = vec3(r, g, b);

    // 4. The "Negative Energy" Inversion
    // We mix the original color with its inverse based on the low-end pulse.
    // At high intensity (bass hits), the image inverts.
    // If they hit exactly 0.5, they 'neutralize' each other.
    vec3 negative = 1.0 - tex;
    float neutralizer = clamp(amp_low * 1.8, 0.0, 1.0);
    vec3 final_color = mix(tex, negative, neutralizer);

    // 5. Divine Dissolution
    // A strobe effect that hits absolute zero (black) on peak transients.
    if (amp_peak > 0.98) {
        final_color = vec3(0.0);
    }

    color = vec4(final_color, 1.0);
}