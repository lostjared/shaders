#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f * 0.65;
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.09;
    float r = length(p) + 1e-4;
    float a = atan(p.y, p.x);
    float fold = abs(fract((log(r) * 1.8 - t) / log(1.72)) - 0.5) * 2.0;
    a += sin(fold * 16.0 + t * 5.0) * 0.35;
    float rr = exp(fold * log(1.72));
    vec2 uv = wrapMirror(vec2(cos(a), sin(a)) * rr / vec2(aspect, 1.0) + 0.5);
    float glitch = step(0.86, sin(floor(tc.y * 80.0) + t * 11.0) * 0.5 + 0.5);
    uv.x += glitch * sin(t + r * 30.0) * 0.09;
    uv += (mouseP - p) * 0.02 * smoothstep(1.25, 0.0, length(p - mouseP));
    vec3 c = texture(samp, uv).rgb;
    vec3 ring = 0.5 + 0.5 * cos(vec3(0.0, 2.2, 4.4) + fold * 8.0 + a * 2.0);
    color = vec4(mix(c, c * ring + ring * 0.2, 0.6), 1.0);
}
