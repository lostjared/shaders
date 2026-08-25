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


layout(set = 0, binding = 0) uniform sampler2D samp; // input video frame texture







uniform vec4 iDate;


uniform vec3 iChannelResolution[4]; // resolution of each texture channel










mat2 rotate(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 centered = tc - 0.5;
    float dist = length(centered);

    // Bass pulse: radial breathing that throbs with low frequencies
    float bassPulse = 1.0 + amp_low * 0.35 * sin(dist * 14.0 - time_f * 4.0);
    centered *= bassPulse;

    // Kaleidoscope: segment count driven by RMS energy
    float segments = floor(mix(3.0, 10.0, clamp(amp_rms * 4.0, 0.0, 1.0)));
    float segAngle = 6.2831853 / segments;
    float kalAngle = atan(centered.y, centered.x);
    float kalDist = length(centered);
    kalAngle = mod(kalAngle, segAngle);
    kalAngle = abs(kalAngle - segAngle * 0.5);
    centered = kalDist * vec2(cos(kalAngle), sin(kalAngle));

    // Mid-range rotation: spin speed driven by mids
    float rotAmount = time_f * (0.3 + amp_mid * 2.5) + amp_mid * 1.5;
    centered = rotate(rotAmount) * centered;

    // Drifting mirror origin from smoothed amplitude
    vec2 drift = amp_smooth * 0.2 * vec2(sin(time_f * 0.8), cos(time_f * 0.6));
    vec2 uv = mirror(centered + 0.5 + drift);

    // Peak ripple: concentric wave on loud transients
    float ripple = amp_peak * sin(dist * 35.0 - time_f * 10.0) * 0.025;
    uv += ripple * normalize(centered + 0.001);

    // Chromatic aberration driven by treble energy
    float chroma = amp_high * 0.02;
    vec2 chromaDir = normalize(centered + 0.001);
    float r = texture(samp, clamp(uv + chromaDir * chroma, 0.0, 1.0)).r;
    float g = texture(samp, clamp(uv, 0.0, 1.0)).g;
    float b = texture(samp, clamp(uv - chromaDir * chroma, 0.0, 1.0)).b;

    color = vec4(r, g, b, 1.0);

    // Brightness flash on peaks
    color.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.3;

    // Subtle color tint shift per frequency band
    color.r += amp_low * 0.05;
    color.b += amp_high * 0.05;
}

