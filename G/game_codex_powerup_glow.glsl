#version 330 core
// Powerup glow: bright radial bloom with rotating color cycle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 p = tc - 0.5;
    vec3 c = texture(samp, tc).rgb;
    float glow = pow(max(0.0, 1.0 - length(p) * 1.8), 2.0);
    vec3 tint = 0.55 + 0.45 * cos(vec3(0.0, 2.1, 4.2) + time_f * 2.0);
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec3 bloom = texture(samp, tc + vec2(px.x * 3.0, 0)).rgb + texture(samp, tc - vec2(px.x * 3.0, 0)).rgb;
    bloom += texture(samp, tc + vec2(0, px.y * 3.0)).rgb + texture(samp, tc - vec2(0, px.y * 3.0)).rgb;
    c = c * 0.8 + bloom * 0.08 + tint * glow * 0.45;
    color = vec4(c, 1.0);
}
