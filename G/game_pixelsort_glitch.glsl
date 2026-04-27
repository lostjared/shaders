#version 330 core
// Vertical pixel-sort style glitch: bright bands smear downward in time.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    float colId = floor(tc.x * iResolution.x / 3.0);
    float trig = hash(colId + floor(time_f * 1.5));
    vec2 uv = tc;
    if (trig > 0.85) {
        float drag = fract(tc.y + time_f * 0.6) * 0.25;
        uv.y = clamp(tc.y - drag, 0.0, 1.0);
    }
    vec3 c = texture(samp, uv).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c += vec3(0.3, 0.0, 0.4) * (trig > 0.85 ? lum : 0.0) * 0.4;
    color = vec4(c, 1.0);
}
