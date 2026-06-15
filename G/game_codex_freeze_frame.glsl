#version 330 core
// Freeze frame: icy desaturation, frost veins, and cold vignette.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 p = tc - 0.5;
    float vein = pow(abs(sin((p.x + p.y) * 45.0 + sin(p.x * 20.0) * 3.0)), 18.0);
    float edge = smoothstep(0.08, 0.42, dot(p, p));
    vec3 ice = mix(vec3(lum), vec3(0.55, 0.85, 1.0), 0.45);
    c = mix(c, ice, 0.65);
    c += vec3(0.5, 0.85, 1.0) * (vein * 0.35 + edge * 0.25);
    color = vec4(c, 1.0);
}
