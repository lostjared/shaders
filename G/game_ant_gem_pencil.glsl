#version 330 core
// Gem pencil — light pencil-sketch hatching overlay, low intensity.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 px = tc * iResolution;
    float h1 = sin((px.x + px.y) * 0.6);
    float h2 = sin((px.x - px.y) * 0.6);
    float hatch = (smoothstep(0.5, 0.0, lum) * smoothstep(0.0, 0.4, h1)
                 + smoothstep(0.7, 0.2, lum) * smoothstep(0.0, 0.4, h2));
    color = vec4(c * (1.0 - hatch * 0.55), 1.0);
}
