#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform vec4 iMouse;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec2 p = tc - 0.5;
    vec2 mouseUV = (iMouse.z > 0.0) ? (iMouse.xy / max(iResolution, vec2(1.0))) : vec2(0.5);
    vec2 mouseP = mouseUV * 2.0 - 1.0;
    p -= mouseP * 0.08;
    float t = time_f;
    float pulse = 0.5 + 0.5 * sin(t * 1.7 + length(p) * 20.0);
    vec2 dir = normalize(p + vec2(0.0001));
    vec3 c = texture(samp, tc).rgb * 0.55;
    vec3 bloom = vec3(0.0);
    for (int i = 1; i <= 8; ++i) {
        float f = float(i);
        vec2 o = dir * px * f * (5.0 + pulse * 14.0);
        bloom += texture(samp, clamp(tc + o, 0.0, 1.0)).rgb / f;
        bloom += texture(samp, clamp(tc - o, 0.0, 1.0)).rgb / f;
    }
    bloom *= 0.16;
    vec3 tint = 0.6 + 0.4 * cos(vec3(0.0, 2.0, 4.0) + t + pulse * 3.0);
    float halo = pow(max(0.0, 1.0 - length(p) * 1.7), 2.2);
    c += bloom * tint * 1.7 + tint * halo * 0.18;
    c += texture(samp, clamp(tc + (mouseP - p) * 0.02, 0.0, 1.0)).rgb * smoothstep(1.25, 0.0, length(p - mouseP)) * 0.18;
    c = mix(c, 1.0 - c, smoothstep(0.92, 1.0, pulse) * 0.18);
    color = vec4(c, 1.0);
}
