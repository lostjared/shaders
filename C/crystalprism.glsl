#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp;
uniform float uamp;
uniform float blendAmt;

float PI = 3.141592653589793;

float mirror1(float x, float m) {
    float p = mod(x, m * 2.0);
    return p > m ? (2.0 * m - p) : p;
}
vec2 kaleido(vec2 p, float seg) {
    vec2 c = vec2(0.5);
    vec2 d = p - c;
    float a = atan(d.y, d.x);
    float r = length(d);
    float m = PI / max(2.0, seg);
    a = mirror1(a, m);
    return c + vec2(cos(a), sin(a)) * max(r, 1e-6);
}
vec3 softLight(vec3 base, vec3 blend) {
    vec3 d = step(vec3(0.5), blend);
    vec3 a = 2.0 * blend * base + base * base * (1.0 - 2.0 * blend);
    vec3 b = 2.0 * base * (1.0 - blend) + sqrt(base) * (2.0 * blend - 1.0);
    return mix(a, b, d);
}

void main() {
    vec2 uv = tc;
    vec4 otex = texture(samp, uv);
    vec3 orig = otex.rgb;
    float luma = dot(orig, vec3(0.2126, 0.7152, 0.0722));
    float drive = clamp(amp + uamp, 0.0, 2.0);

    float seg = floor(mix(6.0, 12.0, clamp(drive * 0.5, 0.0, 1.0)));
    vec2 k = kaleido(uv, seg);

    float r = length(k - 0.5);
    vec2 dir = normalize(k - 0.5 + vec2(1e-6, 0.0));

    float texWarp = mix(0.4, 1.0, luma);
    float bend = (0.04 + 0.12 * uamp) * texWarp / (r + 0.05);
    vec2 wob = 0.010 * (0.3 + amp) * texWarp * vec2(sin(30.0 * r - 1.6 * time_f), cos(26.0 * r - 1.2 * time_f));
    vec2 base = k + dir * bend + wob;

    float angle = atan(dir.y, dir.x);
    float disp = (0.002 + 0.010 * amp) * texWarp;
    vec2 oR = base + disp * vec2(cos(angle + 0.03), sin(angle + 0.03));
    vec2 oG = base;
    vec2 oB = base + disp * vec2(cos(angle - 0.03), sin(angle - 0.03));

    vec3 warped;
    warped.r = texture(samp, oR).r;
    warped.g = texture(samp, oG).g;
    warped.b = texture(samp, oB).b;

    float wedge = PI / max(2.0, seg);
    float edge = abs(mod(angle + wedge, 2.0 * wedge) - wedge) / wedge;
    float edgeGlow = pow(1.0 - edge, 6.0) * mix(0.08, 0.30, amp);
    warped += edgeGlow;

    float t = clamp(mix(0.35, 0.85, blendAmt) * (0.6 + 0.4 * clamp(drive * 0.5, 0.0, 1.0)), 0.0, 1.0);
    vec3 fused = mix(orig, softLight(orig, warped), t);

    color = vec4(fused, otex.a);
}
