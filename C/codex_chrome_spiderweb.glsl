#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

vec2 mirrorWrap(vec2 p) {
    return abs(fract(p) * 2.0 - 1.0);
}

void main(void) {
    float t = time_f * 0.5;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.10;
    float r = length(p);
    float a = atan(p.y, p.x);
    float radial = abs(sin(r * 38.0 - t * 5.0));
    float spokes = abs(sin(a * 14.0 + sin(r * 9.0 - t) * 2.0));
    float web = pow(1.0 - min(radial, spokes), 5.0);
    vec2 uv = tc + normalize(p + 0.0001) * web * 0.075;
    uv += vec2(sin(a * 3.0 + t), cos(a * 4.0 - t)) * 0.012;
    uv += (mouseP - p) * 0.025 * smoothstep(0.9, 0.0, length(p - mouseP));
    vec3 c = texture(samp, mirrorWrap(uv)).rgb;
    vec3 edge = vec3(1.0, 0.86, 0.58) * web + vec3(0.2, 0.65, 1.0) * pow(spokes, 10.0) * 0.25;
    c = mix(c, vec3(dot(c, vec3(0.333))), 0.35);
    color = vec4(c * (0.75 + web * 1.4) + edge, 1.0);
}
