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

    // 1. Bass-Driven Spatial Warp
    // Uses amp_low to create a heavy fluid "bend" in the sketch lines
    float wave = sin(uv.y * 8.0 + iTime * 2.0) * (amp_low * 0.12);
    uv.x += wave;

    // 2. Mid-Range Vortex
    // Gently swirls the center of the frame based on mid-range intensity
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    float swirl = amp_mid * PI * exp(-dist * 2.0);
    float s = sin(swirl);
    float c = cos(swirl);
    centered = mat2(c, -s, s, c) * centered;
    uv = centered + 0.5;

    // 3. High-Frequency Jitter
    // Adds sharp horizontal offsets for that glitch aesthetic during peaks
    if (amp_high > 0.4) {
        float noise = fract(sin(dot(uv.yx, vec2(12.9898, 78.233))) * 43758.5453);
        uv.x += noise * amp_high * 0.05;
    }

    // 4. Chromatic Aberration
    // Splits the RGB channels using amp_smooth for a persistent "vibe"
    float offset = amp_smooth * 0.04;
    float r = texture(samp, uv + vec2(offset, 0.0)).r;
    float g = texture(samp, uv).g;
    float b = texture(samp, uv - vec2(offset, 0.0)).b;

    vec3 result = vec3(r, g, b);

    // 5. Ultimate Dimension Pulse
    // Flashes and enhances the sketch contrast during peaks
    result *= (0.8 + amp_peak * 1.5);

    // Dramatic inversion on the highest peaks
    if (amp_peak > 0.96) {
        result = 1.0 - result;
    }

    color = vec4(result, 1.0);
}