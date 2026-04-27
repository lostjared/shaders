#version 330 core
// Night vision goggles: green-tinted, gain-lifted, slight grain and vignette.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    lum = pow(clamp(lum * 1.4, 0.0, 1.0), 0.85);
    vec3 nv = vec3(0.05, 1.0, 0.10) * lum;
    float n = (hash21(gl_FragCoord.xy + fract(time_f) * 1000.0) - 0.5) * 0.08;
    nv += n;
    vec2 v = tc - 0.5;
    float vig = smoothstep(0.75, 0.15, dot(v, v));
    color = vec4(clamp(nv * mix(0.5, 1.0, vig), 0.0, 1.0), 1.0);
}
