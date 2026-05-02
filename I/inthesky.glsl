#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;

float pp(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

vec2 rot(vec2 uv, float a, vec2 c, float asp) {
    float s = sin(a), co = cos(a);
    vec2 p = uv - c;
    p.x *= asp;
    p = mat2(co, -s, s, co) * p;
    p.x /= asp;
    return p + c;
}

vec2 reflectUV(vec2 uv, float seg, vec2 c, float asp) {
    vec2 p = uv - c;
    p.x *= asp;
    float ang = atan(p.y, p.x);
    float r = length(p);
    float stepA = 6.28318530718 / seg;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 q = vec2(cos(ang), sin(ang)) * r;
    q.x /= asp;
    return q + c;
}

vec2 fractalZoom(vec2 uv, float zoom, float t, vec2 c, float asp) {
    vec2 p = uv;
    for (int i = 0; i < 5; i++) {
        p = abs((p - c) * zoom) - 0.5 + c;
        p = rot(p, t * 0.1, c, asp);
    }
    return p;
}

void main() {
    float asp = iResolution.x / iResolution.y;
    vec2 m0 = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 center = vec2(0.5) + (m0 - vec2(0.5)) * (1.0 + amp * 0.5 * sin(time_f));
    vec2 uv = tc;
    uv += (uv - center) * 0.05 * amp * sin(time_f * 1.3);

    vec4 originalTexture = texture(samp, uv);

    float seg = 6.0 + floor(amp * 2.0 * sin(time_f * 0.7));
    vec2 kUV = reflectUV(uv, seg, center, asp);
    float zoom = 1.5 + 0.5 * sin(time_f * 0.5) + 0.2 * amp * sin(time_f * 1.7);
    kUV = fractalZoom(kUV, zoom, time_f, center, asp);
    kUV = rot(kUV, time_f * 0.2 * (1.0 + 0.6 * amp), center, asp);

    vec4 kaleidoColor = texture(samp, clamp(kUV, 0.0, 1.0));
    float blendFactor = 0.6;
    vec4 blendedColor = mix(kaleidoColor, originalTexture, blendFactor);

    blendedColor.rgb *= 0.5 + 0.5 * sin(vec3(kUV.x, kUV.y, kUV.x) + time_f * (1.0 + 0.5 * amp));

    vec4 t0 = texture(samp, uv);
    vec4 c0 = sin(blendedColor * pp(time_f * (1.0 + 0.3 * amp), 10.0));
    vec4 c1 = c0 * t0 * (0.8 + 0.15 * amp);
    color = sin(c1 * pp(time_f * (1.0 + 0.2 * amp), 15.0));
    color.a = 1.0;
}
