#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float uamp; // Uniform controlling spiral intensity based on audio
uniform float amp;  // Uniform controlling spiral speed based on audio

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
