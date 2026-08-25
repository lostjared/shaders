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
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;





void main(void) {
    float loopDuration = 100.0;
    float currentTime = mod(amp, loopDuration);

    // Normalize texture coordinates to [-1, 1] and adjust for aspect ratio
    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    normCoord.x = abs(normCoord.x); // Make the spiral symmetric horizontally

    // Calculate distance and angle for polar coordinates
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);

    // Spiral parameters influenced by audio
    float spiralSpeed = 5.0 + uamp * 10.0;  // Reacting to `amp` for speed
    float inwardSpeed = currentTime / loopDuration;
    angle += (1.0 - smoothstep(0.0, 8.0, dist)) * currentTime * spiralSpeed;

    // Use `uamp` to influence the inward distortion of the spiral
    dist *= 1.0 - inwardSpeed * (1.0 + uamp * 0.5);

    // Calculate new spiral coordinates
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * tan(dist);

    // Normalize spiral coordinates back to texture space
    spiralCoord = (spiralCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) / 2.0;

    // Sample texture with the spiraled coordinates
    color = texture(samp, spiralCoord);
}
