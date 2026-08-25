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