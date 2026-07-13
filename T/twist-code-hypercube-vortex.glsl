#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 rotate2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

vec2 mirrorRepeat(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

float mirrorRepeat(float p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    vec2 diamond = rotate2(p, 0.78539816339);
    float squareR = max(abs(diamond.x), abs(diamond.y)) + 0.001;
    float a = atan(p.y, p.x);
    float cubeWave = sin(squareR * 72.0 - time_f * 13.0 + a * 8.0);
    a += time_f * 0.9 + 1.15 / squareR + cubeWave * 0.26;
    float shell = mirrorRepeat(-log(squareR) * 0.82 + time_f * 0.65);
    vec2 q = vec2(cos(a), sin(a)) * (squareR + cubeWave * 0.04);
    q = mirrorRepeat(q * (2.0 + shell) + 0.5) - 0.5;
    q = abs(q) * 2.0;
    // Two mirrored angular windings close exactly across atan's -PI/PI cut.
    vec2 uv = mirrorRepeat(q / ar + vec2(shell, a / 3.14159265359));
    vec4 c0 = texture(samp, uv);
    vec4 c1 = texture(samp, mirrorRepeat(1.0 - uv.yx + shell * 0.13));
    float frame = pow(abs(cubeWave), 5.0);
    color = vec4(mix(c0.rgb, c1.bgr, 0.3 + frame * 0.3) * (0.65 + frame * 0.65), c0.a);
}
