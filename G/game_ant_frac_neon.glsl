#version 330 core
// Frac neon — neon-edge highlights via Sobel, low intensity.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 ts = 1.0 / iResolution;
    float gx = lum(texture(samp, tc + vec2(ts.x, 0)).rgb) - lum(texture(samp, tc + vec2(-ts.x, 0)).rgb);
    float gy = lum(texture(samp, tc + vec2(0, ts.y)).rgb) - lum(texture(samp, tc + vec2(0, -ts.y)).rgb);
    float e = clamp(length(vec2(gx, gy)) * 6.0, 0.0, 1.0);
    vec3 neon = mix(vec3(1.0, 0.20, 0.85), vec3(0.20, 0.85, 1.0),
                    0.5 + 0.5 * sin(time_f * 0.8));
    color = vec4(c + neon * e * 1.20, 1.0);
}
