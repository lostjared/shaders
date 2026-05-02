#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

void main(void) {
    // Convert mouse position to UV space
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    float mouseInfluence = smoothstep(0.2, 0.1, distance(tc, mouseUV));

    // Base rotation effect
    float angle = atan(tc.y - 0.5, tc.x - 0.5);
    float modulatedTime = pingPong(time_f, 5.0);
    angle += modulatedTime;

    vec2 rotatedTC;
    rotatedTC.x = cos(angle) * (tc.x - 0.5) - sin(angle) * (tc.y - 0.5) + 0.5;
    rotatedTC.y = sin(angle) * (tc.x - 0.5) + cos(angle) * (tc.y - 0.5) + 0.5;

    // Glitch effects
    vec2 glitchOffset = vec2(
        sin(time_f * 10.0 + tc.y * 50.0) * 0.02 * mouseInfluence,
        cos(time_f * 8.0 + tc.x * 40.0) * 0.02 * mouseInfluence);

    // RGB channel separation
    float rgbShift = 0.02 * mouseInfluence * sin(time_f * 15.0);
    vec4 shiftedColor = vec4(
        texture(samp, rotatedTC + glitchOffset + vec2(rgbShift, 0.0)).r,
        texture(samp, rotatedTC + glitchOffset).g,
        texture(samp, rotatedTC + glitchOffset - vec2(rgbShift, 0.0)).b,
        1.0);

    // Scanline effect
    float scanLine = mod(gl_FragCoord.y * 0.5, 1.0) < 0.5 ? 0.8 : 1.0;
    scanLine *= 1.0 - (0.3 * mouseInfluence * sin(time_f * 20.0));

    // Final color composition
    color = shiftedColor * scanLine;

    // Add digital noise
    float noise = hash(tc.x + tc.y + time_f) * 0.3 * mouseInfluence;
    color.rgb += noise;

    // Edge distortion
    vec2 warpedCoords = mix(rotatedTC, rotatedTC + glitchOffset, mouseInfluence);
    color = mix(color, texture(samp, warpedCoords), 0.7);

    // Block displacement effect
    float blockSize = 50.0;
    vec2 blockCoord = floor(tc * blockSize) / blockSize;
    float blockGlitch = hash(blockCoord.x + blockCoord.y + floor(time_f * 5.0)) * 0.1 * mouseInfluence;
    color.rg = texture(samp, warpedCoords + vec2(blockGlitch)).rg;
}