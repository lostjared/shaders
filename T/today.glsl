#version 330 core

in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

void main(void) {
    vec2 uv = tc - 0.5;

    float radius = length(uv);
    float angle = atan(uv.y, uv.x);

    float audioEffect = uamp * 10.5; // Control warp intensity with audio values
    float wave = sin(radius * 10.0 + time_f * 2.0) * audioEffect;

    angle += wave;

    vec2 tunnelUV = vec2(cos(angle), sin(angle)) * radius + 0.5;

    tunnelUV = fract(tunnelUV); // Wrap texture coordinates

    color = texture(samp, tunnelUV);
}
