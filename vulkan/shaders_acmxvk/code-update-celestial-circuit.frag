#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iTime ext.u0.y

// Radial circuit mandala with pulsing traces, data sparks, and mirrored silicon facets.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 3) uniform sampler1D spectrum;


const float T = 6.28318530718;
float H(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.15, .48, .83)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .58).r,
          a = texture(spectrum, .86).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p), an = atan(p.y, p.x);
    float seg = 12. + floor(b * 8.), w = T / seg, k = abs(mod(an + w * .5, w) - w * .5);
    vec2 q = vec2(k * seg, r * 14.);
    vec2 cell = floor(q);
    float trace = max(pow(.5 + .5 * cos(q.x * T), 32.), pow(.5 + .5 * cos(q.y * T), 32.));
    float gate = step(.35, H(cell));
    trace *= mix(.3, 1., gate);
    vec2 uv = fract(vec2(k / w, r * 2. + sin(k * seg) * .08 * m));
    float ca = .004 + .018 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.48 + .48 * P(r));
    float spark = step(.975, H(cell + 17.)) * (.5 + .5 * sin(iTime * 6. + H(cell) * 20.));
    c += P(r * .7 + an / T - iTime * .06) * (trace * (.35 + 1.5 * a) + spark * (.55 + 2. * t));
    c += P(iTime * .08) * exp(-abs(r - .24 - b * .04) * 70.) * (.5 + b);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
