#version 330
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 normPos = ((gl_FragCoord.xy - iMouse.xy) / iResolution.xy) * 2.0 - 1.0;
    float distScr = length(normPos);
    float phase = sin(distScr * 10.0 - time_f * 4.0);

    float ar = iResolution.x / iResolution.y;

    vec2 p = tc - m;
    p.x *= ar;

    float r = length(p);
    float a = atan(p.y, p.x) + 6.0 * r + time_f * 0.6;
    p = r * vec2(cos(a), sin(a));

    float zoom = 0.95 + 0.25 * sin(time_f * 0.9);
    p /= zoom;

    p.x /= ar;
    vec2 coord = m + p;

    coord += normPos * 0.025 * phase;

    color = texture(samp, fract(coord));
}
