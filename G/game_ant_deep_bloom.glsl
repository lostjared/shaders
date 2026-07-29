#version 330 core
// Deep bloom — soft glow on bright pixels (5-tap sample).
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 ts = 1.5 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 b  = texture(samp, tc + vec2( ts.x, 0.0)).rgb
            + texture(samp, tc + vec2(-ts.x, 0.0)).rgb
            + texture(samp, tc + vec2(0.0,  ts.y)).rgb
            + texture(samp, tc + vec2(0.0, -ts.y)).rgb;
    b *= 0.25;
    vec3 hi = max(b - 0.40, 0.0);
    vec3 outc = c + hi * 1.30;
    color = vec4(outc, 1.0);
}
