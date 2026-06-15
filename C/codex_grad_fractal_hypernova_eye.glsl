#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.03, 0.39, 0.76) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.10;
    float r = length(p) + 1e-4;
    float a = atan(p.y, p.x);
    vec2 dir = vec2(cos(a), sin(a));
    float iris = sin(a * 18.0 + log(r) * 4.0 - time_f * 2.2);
    vec2 z = vec2(cos(a + iris * 0.16), sin(a + iris * 0.16)) * (0.28 / r);
    float flare = 0.0;
    for (int i = 0; i < 5; ++i) {
        z = abs(fract(z) * 2.0 - 1.0);
        flare += pow(abs(sin((z.x + z.y) * 6.0 + time_f)), 12.0) * 0.12;
        z *= 1.28;
    }
    z += (mouseP - p) * 0.04 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec2 uv = abs(fract(z / vec2(aspect, 1.0) + 0.5) * 2.0 - 1.0);
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(dot(dir, vec2(0.12, 0.08)) + r + flare - time_f * 0.06);
    float core = pow(max(0.0, 1.0 - r * 2.7), 3.0);
    color = vec4(mix(tex, grad, 0.75) + grad * (flare + core) * 0.85, 1.0);
}
