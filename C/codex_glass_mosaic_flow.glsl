#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(17.17, 91.71))) * 43758.5453);
}

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

void main(void) {
    float t = time_f * 0.6;
    vec2 grid = vec2(18.0, 14.0);
    vec2 g = floor(tc * grid);
    vec2 f = fract(tc * grid) - 0.5;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseCell = floor(mouseUV * grid);
    float mouseFalloff = smoothstep(2.0, 0.0, distance(g, mouseCell));
    float h = hash(g);
    vec2 drift = vec2(sin(t + h * 6.283185), cos(t * 0.8 + h * 5.0));
    vec2 center = (g + 0.5 + drift * 0.22) / grid;
    center += (mouseUV - center) * mouseFalloff * 0.28;
    float bevel = 1.0 - smoothstep(0.34, 0.5, max(abs(f.x), abs(f.y)));
    vec2 refractUv = tc + (center - tc) * (0.25 + 0.4 * bevel);
    refractUv += normalize(f + 0.001) * 0.018 * sin(h * 8.0 + t * 3.0);
    vec3 c = texture(samp, mirrorWrap(refractUv)).rgb;
    vec3 shine = vec3(0.8, 0.95, 1.0) * pow(bevel, 6.0) * (0.35 + h * 0.45);
    color = vec4(c * (0.72 + bevel * 0.45) + shine, 1.0);
}
