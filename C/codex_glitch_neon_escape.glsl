#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f * 0.4;
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(2.2 * aspect, 2.2);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    vec2 cst = vec2(-0.72 + 0.08 * sin(t), 0.29 + 0.05 * cos(t * 1.3));
    float it = 0.0;
    for (int i = 0; i < 28; ++i) {
        p = vec2(p.x * p.x - p.y * p.y, 2.0 * p.x * p.y) + cst;
        p += 0.035 * sin(p.yx * 5.0 + t);
        if (dot(p, p) > 8.0) break;
        it += 1.0;
    }
    float n = it / 28.0;
    vec2 uv = wrapMirror(tc + p * 0.012 + vec2(sin(n * 20.0 + t) * 0.03, 0.0));
    uv += (mouseP - p) * 0.02 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 tex = texture(samp, uv).rgb;
    vec3 neon = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + n * 14.0 + t * 5.0);
    float contour = pow(abs(sin(n * 40.0)), 8.0);
    color = vec4(mix(tex, neon, 0.35 + contour * 0.4) + neon * contour * 0.3, 1.0);
}
