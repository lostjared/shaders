#version 330 core
// Lava damage: molten heat shimmer and orange overexposure.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    float heat = sin(tc.y * 80.0 + time_f * 9.0) * 0.006;
    heat += sin(tc.x * 35.0 - time_f * 4.0) * 0.004;
    vec3 c = texture(samp, clamp(tc + vec2(heat, heat * 0.4), 0.0, 1.0)).rgb;
    float edge = smoothstep(0.08, 0.35, dot(p, p));
    float pulse = 0.55 + 0.45 * sin(time_f * 3.0);
    vec3 lava = vec3(1.0, 0.32, 0.02);
    c = mix(c, lava + c * 0.35, edge * pulse * 0.55);
    color = vec4(c, 1.0);
}
