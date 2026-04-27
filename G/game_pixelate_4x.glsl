#version 330 core
// Soft 4x downsample mosaic for chunky-pixel retro look.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 4.0 / iResolution;
    vec2 snap = (floor(tc / px) + 0.5) * px;
    vec3 c = texture(samp, snap).rgb;
    color = vec4(c, 1.0);
}
