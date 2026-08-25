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










// Standard perceptual luminance weights
float getLuminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main(void) {
    vec3 baseColor = texture(samp, tc).rgb;

    // 1. Sparse Sampling: Estimate global frame brightness
    // Sampling 9 points across the texture to calculate an average luminance
    float frameLuma = 0.0;
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.9)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.9)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.9)).rgb);
    frameLuma /= 9.0;

    // 2. Automatic Gain Control: Dampen bright flashes
    // Threshold determines the luminance level where dimming begins
    float threshold = 0.45; 
    float exposure = 1.0;

    if (frameLuma > threshold) {
        // Calculate a reduction multiplier
        float targetExposure = threshold / (frameLuma + 0.001);
        
        // Mix ratio (0.8) controls how aggressively the flash is suppressed.
        // 1.0 = strict cap at threshold, lower values allow some brightness through.
        exposure = mix(1.0, targetExposure, 0.8); 
    }

    // Apply the global exposure reduction
    vec3 adjustedColor = baseColor * exposure;

    // 3. Local Highlight Compression (Reinhard Tonemapping)
    // Softens individual bright pixels to prevent harsh clipping
    float pixelLuma = getLuminance(adjustedColor);
    float toneMappedLuma = pixelLuma / (1.0 + pixelLuma);

    // Reapply the compressed luminance while preserving the original color ratios
    if (pixelLuma > 0.001) {
        adjustedColor *= (toneMappedLuma / pixelLuma);
    }

    color = vec4(adjustedColor, 1.0);
}