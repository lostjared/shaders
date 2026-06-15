#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float t = time_f * 0.5;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.12;
    float r = length(p);
    float swirl = 2.5 * exp(-r * 1.8) * sin(t + r * 8.0);
    vec2 q = rot(swirl) * p;
    q += vec2(sin(q.y * 12.0 + t * 2.0), cos(q.x * 11.0 - t * 1.7)) * 0.025;
    q += (mouseP - p) * 0.04 * smoothstep(0.95, 0.0, length(p - mouseP));
    vec2 uv = mirrorWrap(q + 0.5);
    vec3 c = texture(samp, uv).rgb;
    float curtain = sin((q.x + q.y) * 18.0 + sin(q.x * 7.0 + t) * 3.0 - t * 2.0);
    curtain = smoothstep(0.1, 1.0, curtain * 0.5 + 0.5);
    vec3 aurora = 0.5 + 0.5 * cos(vec3(1.4, 3.2, 5.1) + q.y * 8.0 + t);
    c = mix(c, c * aurora + aurora * 0.25, curtain * 0.65);
    c *= 1.0 - smoothstep(0.55, 0.9, r) * 0.45;
    color = vec4(c, 1.0);
}
