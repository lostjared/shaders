#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    vec2 dir = p / max(r, 0.001);
    float pulse = sin(r * 54.0 - time_f * 2.8);
    float envelope = exp(-r * 2.7) * smoothstep(0.0, 0.055, r);
    vec2 uv = safeUV(tc + dir * pulse * envelope * 0.016);
    vec4 src = texture(samp, uv);
    float ring = pow(max(pulse, 0.0), 9.0) * envelope;
    float lens = 1.0 - smoothstep(0.0, 0.52, r);
    vec3 rgb = mix(src.rgb, src.rgb * vec3(0.86, 0.98, 1.08), lens * 0.18);
    rgb += vec3(0.10, 0.22, 0.27) * ring * 0.30;
    color = vec4(rgb, texture(samp, tc).a);
}
