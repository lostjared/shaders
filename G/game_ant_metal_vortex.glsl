#version 330 core
// Metal vortex — soft swirling tint near center, no positional warp.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float swirl = 0.5 + 0.5 * sin(a * 4.0 - r * 12.0 + time_f * 1.0);
    float mask = smoothstep(0.55, 0.0, r);
    vec3 tint = mix(vec3(0.45, 0.30, 0.95), vec3(0.95, 0.30, 0.60), swirl);
    color = vec4(c + tint * mask * 0.45, 1.0);
}
