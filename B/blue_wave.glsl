#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

float sat(float x) { return clamp(x, 0.0, 1.0); }

void main(void) {
    vec2 uv = tc;
    vec2 m = (iMouse.z > 0.0 || iMouse.w > 0.0) ? iMouse.xy / iResolution : vec2(0.5);
    float v = 0.4 + amp * 0.2;
    float s = 0.22;
    float width = 0.10;
    float base = mod(time_f * v, s);
    vec2 dir = normalize(uv - m + 1e-6);
    float r = distance(uv, m);

    float waveSum = 0.0;
    for (int k = 0; k < 4; k++) {
        float rc = base + float(k) * s;
        float a = (r - rc) / width;
        waveSum += exp(-a * a);
    }

    vec2 duv = dir * waveSum * (0.015 + 0.015 * uamp);
    vec4 tex = texture(samp, uv + duv);

    float blend = sat(waveSum * (0.45 + 0.55 * uamp));
    vec3 blue = mix(tex.rgb, vec3(0.06, 0.28, 1.0), blend);
    color = vec4(blue, 1.0);
}
