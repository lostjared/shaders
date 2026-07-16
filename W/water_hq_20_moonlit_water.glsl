#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(41.7, 289.1))) * 45758.5453);
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float bands = sin(tc.y * 72.0 + sin(tc.x * 13.0 + time_f * 0.4) * 3.0 - time_f * 2.0);
    float small = sin(tc.y * 131.0 - tc.x * 29.0 + time_f * 2.7);
    vec2 uv = safeUV(tc + vec2(bands * 0.009 + small * 0.002, small * 0.0015));
    vec4 src = texture(samp, uv);
    float path = exp(-pow((tc.x - 0.5) / (0.055 + tc.y * 0.22), 2.0));
    float broken = pow(max(bands * 0.72 + small * 0.28, 0.0), 10.0);
    float grain = 0.75 + 0.25 * hash21(floor(tc * vec2(180.0, 120.0)));
    float moon = path * broken * grain;
    vec3 rgb = src.rgb * vec3(0.65, 0.76, 0.91) + vec3(0.63, 0.72, 0.78) * moon * 0.68;
    color = vec4(rgb, texture(samp, tc).a);
}
