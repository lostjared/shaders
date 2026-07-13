#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float r = length(p) + 0.0001;
    float a = atan(p.y, p.x);

    float horizon = 0.19 + 0.025 * sin(time_f * 2.2);
    float bend = 2.4 / (r + 0.025) + 8.0 * exp(-r * 3.5);
    float ripple = sin((r - horizon) * 95.0 - time_f * 13.0);
    a += bend + time_f * 0.65 + ripple * 0.12;
    float lensR = abs(r - horizon) + horizon;
    lensR += ripple * 0.035 * smoothstep(0.9, horizon, r);
    vec2 uv = fract(vec2(cos(a), sin(a)) * lensR / ar + 0.5);

    vec2 swirl = vec2(-sin(a), cos(a)) / ar;
    float flare = exp(-abs(r - horizon) * 24.0);
    vec3 tex = vec3(texture(samp, fract(uv + swirl * 0.012)).r,
                    texture(samp, uv).g,
                    texture(samp, fract(uv - swirl * 0.012)).b);
    tex += vec3(1.0, 0.22, 0.04) * flare * 0.65;
    tex *= mix(0.18, 1.15, smoothstep(horizon * 0.35, horizon, r));
    color = vec4(tex, texture(samp, uv).a);
}
