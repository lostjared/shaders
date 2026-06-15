#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.0, 289.0))) * 43758.5453); }
vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.09, 0.21) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    vec2 z = p;
    float line = 0.0;
    for (int i = 0; i < 6; ++i) {
        z = abs(z * (1.28 + 0.04 * sin(time_f + float(i)))) - vec2(0.44, 0.36);
        line += smoothstep(0.03, 0.0, abs(sin(z.x * 8.0) + sin(z.y * 8.0)) * 0.5);
    }
    float block = hash(floor(tc * vec2(32.0, 20.0)) + floor(time_f * 4.0));
    vec2 uv = abs(fract(tc + z * 0.025 + vec2(block * line * 0.015, 0.0)) * 2.0 - 1.0);
    uv += (mouseP - p) * 0.02 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(length(z) * 0.2 + line * 0.12 - time_f * 0.08) * vec3(1.45, 0.85, 0.38);
    color = vec4(mix(tex * 0.45, grad, 0.8) + grad * line * 0.18, 1.0);
}
