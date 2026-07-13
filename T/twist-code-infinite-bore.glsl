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

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(p) + 0.001;
    float a = atan(p.y, p.x);
    float angular = a / TAU;
    float depth = -log(r) * 1.65 + time_f * 1.8;
    // Even angular winding counts close exactly across atan's -PI/PI cut.
    float corkscrew = angular * 4.0 + depth * 0.38;
    float rib = sin(depth * 11.0 + a * 8.0) * 0.08;

    vec2 uv = mirrorRepeat(vec2(corkscrew + rib,
                                depth + sin(a * 12.0 - time_f * 4.0) * 0.12));
    vec2 uv2 = mirrorRepeat(vec2(angular * 6.0 - depth * 0.28 - rib + 0.25,
                                 depth * 1.07 - angular * 2.0));
    vec4 aTex = texture(samp, uv);
    vec4 bTex = texture(samp, uv2);
    float ribs = 0.5 + 0.5 * sin(depth * 18.0 + a * 10.0);
    vec3 rgb = mix(aTex.rgb, bTex.bgr, 0.25 + ribs * 0.35);
    rgb *= 0.65 + ribs * 0.65;
    color = vec4(rgb, aTex.a);
}
