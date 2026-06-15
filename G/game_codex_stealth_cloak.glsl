#version 330 core
// Stealth cloak: glassy displacement with desaturated shimmer.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float wave = sin(p.y * 70.0 + time_f * 5.0) * sin(p.x * 43.0 - time_f * 3.0);
    vec2 uv = tc + vec2(wave * 0.012, cos(p.x * 55.0 + time_f * 4.0) * 0.006);
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float veil = smoothstep(0.65, 0.05, dot(p, p));
    c = mix(c, vec3(lum) * vec3(0.65, 0.9, 1.0), veil * 0.55);
    c += vec3(0.15, 0.5, 0.8) * abs(wave) * veil;
    color = vec4(c, 1.0);
}
