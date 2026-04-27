#version 330 core
// Soft painterly look using a small Kuwahara-style box average.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec4 boxAvg(vec2 origin, vec2 px) {
    vec3 sum = vec3(0.0);
    vec3 sumSq = vec3(0.0);
    for (int x = 0; x < 3; ++x) {
        for (int y = 0; y < 3; ++y) {
            vec3 s = texture(samp, origin + vec2(float(x), float(y)) * px).rgb;
            sum += s;
            sumSq += s * s;
        }
    }
    vec3 mean = sum / 9.0;
    vec3 var = abs(sumSq / 9.0 - mean * mean);
    return vec4(mean, var.r + var.g + var.b);
}

void main(void) {
    vec2 px = 1.5 / iResolution;
    vec4 q0 = boxAvg(tc + vec2(-2.0, -2.0) * px, px);
    vec4 q1 = boxAvg(tc + vec2( 0.0, -2.0) * px, px);
    vec4 q2 = boxAvg(tc + vec2(-2.0,  0.0) * px, px);
    vec4 q3 = boxAvg(tc + vec2( 0.0,  0.0) * px, px);
    vec4 best = q0;
    if (q1.a < best.a) best = q1;
    if (q2.a < best.a) best = q2;
    if (q3.a < best.a) best = q3;
    color = vec4(best.rgb, 1.0);
}
