#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.2, 0.45, 0.7) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    vec2 z = p;
    float vine = 0.0;
    for (int i = 0; i < 5; ++i) {
        z = abs(z * 1.42) - vec2(0.34, 0.46);
        z += (noise(z * 3.0 + time_f * 0.3) - 0.5) * 0.08;
        vine += smoothstep(0.04, 0.0, abs(sin(z.x * 9.0) * sin(z.y * 9.0))) * 0.18;
    }
    z += (mouseP - p) * 0.03 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec2 uv = abs(fract(tc + z * 0.035) * 2.0 - 1.0);
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(vine * 0.22 + length(z) * 0.12 + time_f * 0.07) * vec3(0.55, 1.35, 0.92);
    color = vec4(mix(tex * 0.55, grad, 0.78) + grad * vine * 0.5, 1.0);
}
