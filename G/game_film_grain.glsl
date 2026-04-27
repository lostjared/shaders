#version 330 core
// Animated film grain overlay. Subtle, preserves detail.
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
    float n = hash21(gl_FragCoord.xy + fract(time_f) * 1000.0);
    float grain = (n - 0.5) * 0.10;
    c += grain;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
