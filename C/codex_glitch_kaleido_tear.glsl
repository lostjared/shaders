#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453123); }
vec2 wrapMirror(vec2 p) { return abs(fract(p) * 2.0 - 1.0); }

void main(void) {
    float t = time_f;
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = tc - 0.5;
    p.x *= aspect;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= aspect;
    p -= mouseP * 0.08;
    float r = length(p);
    float a = atan(p.y, p.x);
    float seg = 9.0 + 3.0 * sin(t * 0.31);
    float stepA = 6.2831853 / seg;
    a = abs(mod(a + t * 0.25, stepA) - stepA * 0.5);
    vec2 q = vec2(cos(a), sin(a)) * r;
    for (int i = 0; i < 4; ++i) {
        q = abs(q * (1.36 + 0.08 * sin(t + float(i)))) - 0.38;
        q = mat2(0.86, -0.51, 0.51, 0.86) * q;
    }
    float band = floor(tc.y * 96.0);
    q.x += (hash(band + floor(t * 13.0)) - 0.5) * 0.25;
    vec2 uv = wrapMirror(q / vec2(aspect, 1.0) + 0.5);
    uv += (mouseP - p) * 0.03 * smoothstep(1.35, 0.0, length(p - mouseP));
    vec3 c = texture(samp, uv).rgb;
    float line = step(0.92, hash(floor(tc.y * 180.0) + floor(t * 18.0)));
    c = mix(c, vec3(c.b, c.r, c.g), line * 0.75);
    c += (0.5 + 0.5 * cos(vec3(0.3, 2.7, 5.1) + r * 20.0 - t)) * line * 0.25;
    color = vec4(c, 1.0);
}
