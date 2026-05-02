#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float uamp; // Audio amplitude (0.0 to 1.0)

void main(void) {
    vec2 uv = tc * 2.0 - 1.0;                       // Transform texture coordinates to [-1, 1]
    float len = length(uv);                         // Distance from the center
    float bubble = smoothstep(0.7, 1.0, 1.0 - len); // Bubble shape effect

    // Beat effect: the bubble size and distortion intensity are modulated by uamp
    float beat = 1.0 + 0.2 * sin(uamp * 100.0);                // Beat modulation frequency scaled by uamp
    vec2 distort = uv * (1.0 + 0.15 * sin(len * 20.0 * beat)); // Distortion based on the beat

    vec4 texColor = texture(samp, distort * 0.5 + 0.5);             // Sample the texture with distortion
    color = mix(texColor, vec4(1.0, 1.0, 1.0, 1.0), bubble * uamp); // Blend texture and bubble
}
