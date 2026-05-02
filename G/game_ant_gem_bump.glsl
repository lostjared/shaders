#version 330 core
// Gem bump — fake bump-map highlight using luminance gradient.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 ts = 1.0 / iResolution;
    float l = dot(texture(samp, tc).rgb, vec3(0.299, 0.587, 0.114));
    float lx = dot(texture(samp, tc + vec2(ts.x, 0)).rgb, vec3(0.299, 0.587, 0.114));
    float ly = dot(texture(samp, tc + vec2(0, ts.y)).rgb, vec3(0.299, 0.587, 0.114));
    vec3 n = normalize(vec3(l - lx, l - ly, 0.5));
    vec3 ld = normalize(vec3(sin(time_f * 0.4), cos(time_f * 0.4), 0.6));
    float diff = max(dot(n, ld), 0.0);
    vec3 c = texture(samp, tc).rgb;
    color = vec4(c * (0.65 + 0.85 * diff), 1.0);
}
