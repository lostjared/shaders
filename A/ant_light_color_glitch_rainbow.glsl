#version 330 core
// ant_light_color_glitch_rainbow
// RGB channel glitch with rainbow band tearing and bass-reactive displacement

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;

    // Glitch band tearing
    float bandY = floor(uv.y * 30.0);
    float glitchSeed = floor(iTime * 8.0);
    float glitchAmount = step(0.7 - bass * 0.3, hash(bandY + glitchSeed));
    float tearOffset = (hash(bandY + glitchSeed + 1.0) - 0.5) * 0.15 * glitchAmount;
    tearOffset *= 1.0 + bass * 2.0;

    // Per-channel displacement
    float rOff = tearOffset + treble * 0.01 * sin(iTime * 20.0 + uv.y * 50.0);
    float gOff = tearOffset * 0.5;
    float bOff = tearOffset - treble * 0.01 * sin(iTime * 20.0 + uv.y * 50.0);

    vec3 col;
    col.r = texture(samp, vec2(uv.x + rOff, uv.y)).r;
    col.g = texture(samp, vec2(uv.x + gOff, uv.y)).g;
    col.b = texture(samp, vec2(uv.x + bOff, uv.y)).b;

    // Rainbow band overlay on glitched areas
    vec3 bandColor = rainbow(bandY * 0.1 + iTime * 0.5);
    col = mix(col, col * bandColor * 2.0, glitchAmount * (0.3 + mid * 0.4));

    // Scanline flicker
    float scanline = sin(uv.y * iResolution.y * 1.5 + iTime * 30.0) * 0.5 + 0.5;
    scanline = pow(scanline, 10.0);
    col += rainbow(uv.y + iTime * 0.3) * scanline * glitchAmount * (0.3 + air * 0.5);

    // Block corruption
    vec2 block = floor(uv * vec2(20.0, 15.0));
    float corrupt = step(0.92, hash(dot(block, vec2(1.0, 37.0)) + glitchSeed));
    col = mix(col, rainbow(hash(dot(block, vec2(7.0, 13.0))) + iTime), corrupt * bass);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
