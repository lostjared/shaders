#version 330 core
// Crispness boost via 5-tap unsharp mask. Great for upscaled retro content.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 n  = texture(samp, tc + vec2(0.0,  px.y)).rgb;
    vec3 s  = texture(samp, tc + vec2(0.0, -px.y)).rgb;
    vec3 e  = texture(samp, tc + vec2( px.x, 0.0)).rgb;
    vec3 w  = texture(samp, tc + vec2(-px.x, 0.0)).rgb;
    vec3 sharp = c * 5.0 - (n + s + e + w);
    vec3 outc = mix(c, sharp, 0.35);
    color = vec4(clamp(outc, 0.0, 1.0), 1.0);
}
