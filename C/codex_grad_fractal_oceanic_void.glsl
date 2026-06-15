#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.48, 0.66, 0.9) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    vec2 z = p;
    float foam = 0.0;
    for (int i = 0; i < 6; ++i) {
        z = abs(z) / max(dot(z, z), 0.16) - vec2(0.58 + 0.05 * sin(time_f), 0.7);
        z += 0.035 * sin(z.yx * 6.0 + time_f + float(i));
        foam += exp(-12.0 * abs(length(z) - 0.72)) * 0.12;
    }
    vec2 uv = abs(fract(tc + z * 0.015 + vec2(sin(z.y * 5.0) * 0.02, 0.0)) * 2.0 - 1.0);
    uv += (mouseP - p) * 0.02 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 tex = texture(samp, uv).rgb;
    vec3 grad = palette(foam + length(p) * 0.25 + time_f * 0.035) * vec3(0.45, 1.1, 1.45);
    color = vec4(mix(tex * 0.5, grad, 0.76) + grad * foam * 0.6, 1.0);
}
