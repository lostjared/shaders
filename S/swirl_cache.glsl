#version 330 core

out vec4 color;
in vec2 tc; // The default texture coordinate passed from your vertex shader

// Our five input textures
uniform sampler2D samp;  // base
uniform sampler2D samp1; // layer 1
uniform sampler2D samp2; // layer 2
uniform sampler2D samp3; // layer 3
uniform sampler2D samp4; // layer 4

// Screen resolution and time
uniform vec2 iResolution;
uniform float time_f;

// ---------------------------------------------------
// A helper function to shift hue by a normalized amount [0..1]
vec3 hueShift(vec3 color, float shift) {
    // 'shift' is in [0..1]; convert it to an angle in radians
    float angle = 6.28318530718 * shift; // 2 * PI
    float s = sin(angle);
    float c = cos(angle);

    // Precalculate constants for a typical hue rotation matrix
    // For reference: https://en.wikipedia.org/wiki/HSL_and_HSV#Hue_and_chroma
    mat3 toYCbCr = mat3(
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114);
    mat3 adjust = mat3(
        0.701, -0.587, -0.114,
        -0.299, 0.413, -0.114,
        -0.300, -0.588, 0.886);
    mat3 rot = mat3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0);

    // Combine
    return (toYCbCr + adjust * rot) * color;
}

// ---------------------------------------------------
// A helper function to apply a swirl-like distortion around a center point.
// radius controls the region of swirling, angle is the swirl intensity.
vec2 swirl(vec2 uv, vec2 center, float radius, float angle) {
    vec2 pos = uv - center;
    float r = length(pos);

    // Only swirl if within the swirl's radius
    if (r < radius) {
        float percent = (radius - r) / radius;
        float theta = atan(pos.y, pos.x) + angle * percent;
        pos = r * vec2(cos(theta), sin(theta));
    }
    return pos + center;
}

// ---------------------------------------------------
// Main fragment shader entry point
void main(void) {
    // Normalized UVs in [0..1], making sure we have a consistent orientation
    vec2 uv = tc;

    // You can play with swirling center in NDC or in pixel space:
    // For example, use iResolution to find the center in pixel coordinates,
    // then normalize by iResolution.
    // Here we simply swirl around the center (0.5, 0.5) in [0..1].
    vec2 center = vec2(0.5, 0.5);

    // The swirl radius and intensity factor
    float radius = 0.5;         // swirling radius in [0..1]
    float swirlStrength = 0.75; // swirl angle scale
    float swirlAngle = swirlStrength * sin(time_f * 0.8);

    // Apply swirl differently for each texture
    // Add some wave-based warping as well
    float waveX = sin(uv.y * 6.0 + time_f * 2.0) * 0.03;
    float waveY = cos(uv.x * 6.0 + time_f * 2.0) * 0.03;

    // Distorted UVs for each sampler
    vec2 uv0 = swirl(uv + vec2(waveX, waveY), center, radius, swirlAngle);
    vec2 uv1 = swirl(uv + vec2(waveY, waveX), center, radius, swirlAngle * 0.5);
    vec2 uv2 = swirl(uv - vec2(waveX, waveY), center, radius, -swirlAngle);
    vec2 uv3 = swirl(uv + vec2(waveY * 2.0, -waveX * 2.0), center, radius, swirlAngle * 1.5);
    vec2 uv4 = swirl(uv, center, radius, swirlAngle * 2.0);

    // Sample from each texture with the distorted coordinates
    vec4 base = texture(samp, uv0);
    vec4 one = texture(samp1, uv1);
    vec4 two = texture(samp2, uv2);
    vec4 three = texture(samp3, uv3);
    vec4 four = texture(samp4, uv4);

    // Shift each texture’s hue by different amounts
    // to create a rainbow-like blending
    vec3 color0 = hueShift(base.rgb, 0.00);
    vec3 color1 = hueShift(one.rgb, 0.20);
    vec3 color2 = hueShift(two.rgb, 0.40);
    vec3 color3 = hueShift(three.rgb, 0.60);
    vec3 color4 = hueShift(four.rgb, 0.80);

    // Combine them. You can adjust blending weights, saturate, etc. as desired.
    vec3 combined = color0 + color1 + color2 + color3 + color4;
    combined /= 5.0;

    // Final output color
    color = vec4(combined, 1.0);
}
