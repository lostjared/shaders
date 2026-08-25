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
#define iChannelTime ext.custom_uniforms[3].x
#define iFrame int(ext.u2.x)
#define iFrameRate ext.u1.w
#define iMouse ext.mouse
#define iMouseClick ext.mouse.xy
#define iResolution ext.u0.zw
#define iSampleRate ext.u2.z
#define iTime ext.u0.y
#define iTimeDelta ext.u1.x
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

// --- Uniforms ---

layout(set = 0, binding = 0) uniform sampler2D samp; 







uniform vec4 iDate;


uniform vec3 iChannelResolution[4];



// --- Configuration ---
const float DARKNESS_THRESHOLD = 0.2; // Pixels darker than this become rainbow
const float RAINBOW_SPEED = 1.0;      // Speed of the color shift
const float RAINBOW_SCALE = 3.0;      // Size of the rainbow waves
const float BLEND_SOFTNESS = 0.1;     // How soft the transition is between image and rainbow

// Helper: Cosine based palette (The "Rainbow" Generator)
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67); // Classic Rainbow spread
    return a + b * cos(6.28318 * (c * t + d));
}

// Helper: Calculate perceived brightness
float getLuma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void main(void) {
    // 1. Sample the original texture
    vec4 texColor = texture(samp, tc);
    
    // 2. Calculate how bright this pixel is
    float brightness = getLuma(texColor.rgb);

    // 3. Create a mask based on darkness
    // smoothstep creates a value between 0.0 and 1.0. 
    // If brightness is high (light pixel), mask becomes 0.0.
    // If brightness is low (dark pixel), mask becomes 1.0.
    float mask = 1.0 - smoothstep(DARKNESS_THRESHOLD, DARKNESS_THRESHOLD + BLEND_SOFTNESS, brightness);

    // 4. Generate the Rainbow Gradient
    // We mix x, y, and time to create a diagonal wave pattern
    vec3 rainbow = palette((tc.x + tc.y * 0.5) * RAINBOW_SCALE + iTime * RAINBOW_SPEED);

    // 5. Mix them together
    // The 'mask' controls the mix. 
    // 0.0 = Pure Original Image
    // 1.0 = Pure Rainbow
    vec3 finalRGB = mix(texColor.rgb, rainbow, mask);

    color = vec4(finalRGB, 1.0);
}