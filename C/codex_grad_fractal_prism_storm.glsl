#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(0.94, 0.17, 0.46) + t));
}

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    vec2 z = p * 2.4;
    float flash = 0.0;
    for (int i = 0; i < 7; ++i) {
        z = abs(z) / max(dot(z, z), 0.3) - vec2(0.64, 0.41);
        z = rot(0.45 + float(i) * 0.14 + time_f * 0.03) * z;
        flash += smoothstep(0.025, 0.0, abs(z.x - z.y)) * 0.25;
    }
    vec2 dir = normalize(z + 1e-5);
    vec2 uv = abs(fract(tc + z * 0.02) * 2.0 - 1.0);
    uv += (mouseP - p) * 0.03 * smoothstep(1.25, 0.0, length(p - mouseP));
    vec3 tex;
    tex.r = texture(samp, abs(fract(uv + dir * 0.035) * 2.0 - 1.0)).r;
    tex.g = texture(samp, uv).g;
    tex.b = texture(samp, abs(fract(uv - dir * 0.035) * 2.0 - 1.0)).b;
    vec3 grad = palette(length(z) * 0.18 + flash * 0.08 - time_f * 0.1);
    color = vec4(mix(tex, grad, 0.73) + grad * flash * 0.45, 1.0);
}
