#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.62, 0.34, 0.08) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.09;
    float r = length(p) + 0.0001;
    float a = atan(p.y, p.x);
    vec2 dir = vec2(cos(a), sin(a));
    float fold = fract((log(r) * 1.7 - time_f * 0.45) / log(1.68));
    a += sin(fold * 14.0 + time_f * 1.7) * 0.42;
    vec2 q = dir * exp(fold * log(1.68));
    for (int i = 0; i < 4; ++i) {
        q = abs(q * 1.45) - vec2(0.55, 0.38);
    }
    vec2 uv = abs(fract(q / vec2(aspect, 1.0) + 0.5) * 2.0 - 1.0);
    uv += (mouseP - p) * 0.03 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 tex = texture(samp, uv).rgb;
    float gate = pow(abs(sin(fold * 18.0 + time_f * 2.0)), 7.0);
    vec3 grad = palette(fold + dot(dir, vec2(0.11, 0.07)) + length(q) * 0.1);
    color = vec4(mix(tex * 0.55, grad, 0.78) + grad * gate * 0.7, 1.0);
}
