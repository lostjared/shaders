#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI = 3.14159265;

void main(void) {
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    float t = time_f * (0.5 + amp_smooth * 2.0);

    // Plasma layers - each frequency band drives a layer
    float p1 = sin(uv.x * (5.0 + amp_low * 12.0) + t * 2.0);
    float p2 = sin(uv.y * (5.0 + amp_mid * 10.0) + t * 1.5);
    float p3 = sin((uv.x + uv.y) * (4.0 + amp_high * 8.0) + t * 3.0);
    float p4 = cos(length(uv) * (8.0 + amp_rms * 15.0) - t * 2.5);
    float p5 = sin(atan(uv.y, uv.x) * 3.0 + t + amp_low * 5.0);

    float plasma = (p1 + p2 + p3 + p4 + p5) * 0.2;

    vec3 col;
    col.r = cos(plasma * PI + t * 0.3 + amp_low * 2.0) * 0.5 + 0.5;
    col.g = sin(plasma * PI + t * 0.4 + amp_mid) * 0.5 + 0.5;
    col.b = sin(plasma * PI * 1.5 + t * 0.5 + amp_high * 1.5) * 0.5 + 0.5;

    // Blend with texture - smooth amp controls blend ratio
    vec3 tex = texture(samp, tc).rgb;
    float blend = 0.4 + amp_rms * 0.3;
    col = mix(tex, col, blend);

    // Peak storm flash
    col += smoothstep(0.5, 1.0, amp_peak) * 0.35;

    // Bass tints red, treble tints blue
    col.r += amp_low * 0.08;
    col.b += amp_high * 0.08;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
