#version 330 core
// Magic / arcane purple aura grade.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 arcane = mix(c, vec3(lum) * vec3(0.65, 0.35, 1.00), 0.40);
    vec2 v = tc - 0.5;
    float halo = smoothstep(0.55, 0.10, dot(v, v));
    arcane += vec3(0.18, 0.06, 0.30) * halo * 0.35;
    color = vec4(clamp(arcane, 0.0, 1.0), 1.0);
}
