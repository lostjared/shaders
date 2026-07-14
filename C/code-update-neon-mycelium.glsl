#version 330 core
// Branching electric filament field with reactive bioluminescent pulses.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
float h(vec2 p) {
    return fract(sin(dot(p, vec2(41.7, 289.3))) * 43758.54);
}
float fil(vec2 p) {
    float f = 0.;
    for (int i = 0; i < 5; i++) {
        p = abs(p) * 1.55 - vec2(.42, .31);
        p += .12 * sin(p.yx * 3. + float(i) + iTime * .35);
        float d = abs(sin(p.x * 4.2) + sin(p.y * 5.1));
        f += exp(-18. * d) / pow(1.45, float(i));
    }
    return f;
}
vec3 pal(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.46, .12, .78)));
}
void main() {
    float b = texture(spectrum, .04).r, m = texture(spectrum, .25).r, t = texture(spectrum, .64).r,
          a = texture(spectrum, .9).r;
    float asp = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(asp, 1);
    p += .06 * vec2(sin(p.y * 8. + iTime), cos(p.x * 7. - iTime * .8)) * m;
    float f = fil(p * (1.25 + b * .25));
    vec2 uv = tc + vec2(sin(p.y * 19. + iTime), cos(p.x * 17. - iTime)) * f * .014;
    vec3 c = texture(samp, uv).rgb * (.48 + .52 * pal(length(p) + iTime * .03));
    float node = step(.985, h(floor((p + 2.) * 28.))) *
                 (.5 + .5 * sin(iTime * 4. + h(floor(p * 28.)) * 20.));
    c += pal(f * .4 + iTime * .08) * f * (1. + 2. * t) +
         pal(length(p) - iTime * .1) * node * (.5 + 2. * a);
    c += pal(iTime * .06) * pow(f, 3.) * (.35 + b);
    c *= .86 + .35 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.22), 1);
}
