#version 330 core
// Matrix-style green rain code overlay on top of the source.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 src = texture(samp, tc).rgb;
    float lum = dot(src, vec3(0.299, 0.587, 0.114));

    float colW = 12.0;
    float rowH = 14.0;
    float colId = floor(tc.x * iResolution.x / colW);
    float speed = 0.4 + hash(vec2(colId, 1.0)) * 1.6;
    float yPos = fract(tc.y + time_f * speed * 0.15 + hash(vec2(colId, 7.0)));
    float row = floor(yPos * iResolution.y / rowH);
    float ch = hash(vec2(colId, row + floor(time_f * 8.0)));
    float head = smoothstep(0.0, 0.05, yPos) * smoothstep(0.20, 0.0, yPos);
    float tail = smoothstep(0.6, 0.0, yPos);
    float gly = step(0.5, ch);
    float bright = max(head * 1.4, tail * 0.6) * gly;
    vec3 green = vec3(0.1, 1.0, 0.25) * bright;
    color = vec4(src * 0.45 + green, 1.0);
}
