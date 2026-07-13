#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float front = fract(time_f * 0.42);
    float shock = exp(-abs(fract(r * 1.35 - front + 0.5) - 0.5) * 26.0);
    float spiral = sin(r * 58.0 - a * 13.0 - time_f * 14.0);
    a += 1.35 / r + shock * 1.4 + time_f * 0.72;
    r += spiral * (0.025 + shock * 0.065);
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec2 radial = vec2(cos(a), sin(a)) / ar;
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, fract(uv + radial * shock * 0.055));
    vec3 rgb = mix(c0.rgb, c1.bgr, shock * 0.58);
    rgb += vec3(0.12, 0.35, 0.8) * shock * 0.5;
    color = vec4(rgb, c0.a);
}
