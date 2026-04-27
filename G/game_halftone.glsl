#version 330 core
// Comic book halftone dots overlay - readable, subtle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 cell = mod(gl_FragCoord.xy, 5.0) - 2.5;
    float d = length(cell);
    float dot_ = smoothstep(2.4, 1.6, d * (0.6 + 0.6 * (1.0 - lum)));
    vec3 outc = mix(c, c * 0.65, dot_ * 0.35);
    color = vec4(outc, 1.0);
}
