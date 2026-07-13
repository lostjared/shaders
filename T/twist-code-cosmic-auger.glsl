#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

vec2 mirrorRepeat(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

vec2 auger(vec2 uv, float phase) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (uv - 0.5) * ar;
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float teeth = sin(a * 20.0 - log(r) * 31.0 - time_f * 13.0 + phase);
    float bore = 1.45 / r + time_f * 1.35 + teeth * 0.32;
    a += bore;
    r += teeth * 0.052 + sin(r * 88.0 - time_f * 17.0) * 0.026;
    return mirrorRepeat(vec2(cos(a), sin(a)) * r / ar + 0.5);
}

void main(void) {
    vec2 u0 = auger(tc, 0.0);
    vec2 u1 = auger(tc, 0.21);
    vec2 u2 = auger(tc, -0.21);
    vec3 drilled = vec3(texture(samp, u1).r,
                        texture(samp, u0).g,
                        texture(samp, u2).b);
    float r = length(tc - 0.5) + 0.001;
    float ring = pow(0.5 + 0.5 * sin(-log(r) * 28.0 - time_f * 15.0), 3.0);
    vec3 echo = texture(samp, mirrorRepeat(vec2(atan(tc.y - 0.5, tc.x - 0.5) / TAU * 4.0,
                                                       -log(r) + time_f))).bgr;
    vec3 rgb = mix(drilled, echo, 0.18 + ring * 0.32);
    rgb *= 0.62 + ring * 0.85;
    color = vec4(rgb, texture(samp, u0).a);
}
