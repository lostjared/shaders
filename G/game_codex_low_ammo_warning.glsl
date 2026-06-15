#version 330 core
// Low ammo warning: amber HUD stripes with rhythmic edge pulse.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float pulse = 0.5 + 0.5 * sin(time_f * 5.5);
    float stripe = step(0.55, fract((tc.x + tc.y) * 18.0 - time_f * 1.8));
    float frame = max(smoothstep(0.16, 0.0, tc.x), smoothstep(0.84, 1.0, tc.x));
    frame = max(frame, max(smoothstep(0.13, 0.0, tc.y), smoothstep(0.87, 1.0, tc.y)));
    vec3 amber = vec3(1.0, 0.62, 0.08);
    c = mix(c, amber, frame * stripe * pulse * 0.55);
    color = vec4(c, 1.0);
}
