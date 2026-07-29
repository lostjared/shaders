#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f * 0.55;
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 c0 = (tc - 0.5) * vec2(2.7 * aspect, 2.7) + vec2(-0.35 + 0.08 * sin(t), 0.05 * cos(t));
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    c0 -= mouseP * 0.12;
    vec2 z = c0;
    float iter = 0.0;
    float trap = 8.0;
    for (int i = 0; i < 22; ++i) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c0;
        trap = min(trap, abs(z.x * z.y));
        if (dot(z, z) > 9.0) break;
        iter += 1.0;
    }
    float f = iter / 22.0;
    vec2 uv = wrapMirror(tc + normalize(z + 1e-5) * (0.01 + f * 0.06));
    vec2 off = vec2(0.02 * sin(trap * 40.0 + t), 0.0);
    uv += (mouseP - c0) * 0.02 * smoothstep(1.0, 0.0, length(c0 - mouseP));
    vec3 tex = vec3(texture(samp, wrapMirror(uv + off)).r, texture(samp, uv).g, texture(samp, wrapMirror(uv - off)).b);
    vec3 acid = 0.55 + 0.45 * cos(vec3(0.0, 2.0, 4.0) + f * 10.0 + trap * 25.0 - t * 4.0);
    color = vec4(mix(tex, acid, 0.25 + 0.55 * smoothstep(0.0, 0.05, trap)), 1.0);
}
