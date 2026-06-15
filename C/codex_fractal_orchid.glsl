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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float t = time_f * 0.42;
    vec2 p = (tc - 0.5) * 2.0;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    mouseP.x *= iResolution.x / max(iResolution.y, 1.0);
    p -= mouseP * 0.08;
    vec2 z = p;
    float trap = 10.0;
    for (int i = 0; i < 9; ++i) {
        z = abs(z) / max(dot(z, z), 0.18) - vec2(0.72 + 0.08 * sin(t), 0.48);
        z *= rot(0.35 + sin(t + float(i)) * 0.18);
        trap = min(trap, abs(z.x) + abs(z.y));
    }
    vec2 uv = mirrorWrap(tc + z * 0.025);
    uv += (mouseP - p) * 0.02 * exp(-length(p - mouseP) * 2.5);
    vec3 src = texture(samp, uv).rgb;
    float petals = exp(-trap * 3.2);
    vec3 orchid = 0.5 + 0.5 * cos(vec3(0.7, 2.0, 4.8) + petals * 5.0 + t * 2.0);
    vec3 c = mix(src * 0.65, src * orchid + orchid * 0.35, petals);
    color = vec4(c, 1.0);
}
