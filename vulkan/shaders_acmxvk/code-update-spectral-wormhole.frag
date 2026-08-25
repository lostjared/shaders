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

// Deep log-polar tunnel with braided spectrum rails and prismatic motion blur.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 3) uniform sampler1D spectrum;


const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.0, .34, .68)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .23).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p) + .008, an = atan(p.y, p.x);
    float z = log(r) * 1.25 + iTime * (.5 + b);
    float twist = an + z * (.8 + m * 1.4) + sin(z * 2.) * .2;
    vec2 uv = fract(vec2(twist / T * 3., z * .22));
    float ca = .006 + .025 * t;
    vec3 c = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                  texture(samp, uv - vec2(ca, 0)).b);
    float rail = 0.;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        rail += pow(.5 + .5 * cos(twist * (6. + fi * 2.) + z * (2. - fi * .25) + fi), 18.) / 4.;
    }
    float ring = pow(.5 + .5 * cos(z * 12. - iTime * 2.), 16.);
    c *= .52 + .62 * P(z * .06 + twist / T);
    c += P(twist / T + z * .08 - iTime * .05) * (rail * (.8 + 2. * a) + ring * (.2 + b));
    c *= smoothstep(.025, .16, r);
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
