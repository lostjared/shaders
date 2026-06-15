#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.78, 0.95, 0.18) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    float a = atan(p.y, p.x);
    float r = length(p);
    float seg = 10.0;
    a = abs(mod(a + time_f * 0.18, 6.28318 / seg) - 3.14159 / seg);
    vec2 z = vec2(cos(a), sin(a)) * r * 2.2;
    float shard = 0.0;
    for (int i = 0; i < 5; ++i) {
        z = abs(z * 1.32) - vec2(0.46, 0.31);
        shard += smoothstep(0.035, 0.0, abs(z.x + z.y));
    }
    z += (mouseP - p) * 0.03 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec2 uv = abs(fract(tc + z * 0.045) * 2.0 - 1.0);
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(r * 0.8 + shard * 0.14 - time_f * 0.06);
    color = vec4(mix(tex, grad, 0.66) + grad * shard * 0.22, 1.0);
}
