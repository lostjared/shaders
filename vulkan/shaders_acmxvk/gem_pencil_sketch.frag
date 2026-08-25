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
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define iamp ext.u1.z
#define time_f ext.u2.y
#define time_speed ext.custom_uniforms[3].y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;


layout(set = 0, binding = 0) uniform sampler2D samp;







uniform vec4 iDate;


uniform vec3 iChannelResolution[4];










const float PI  = 3.1415926535897932384626433832795;
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