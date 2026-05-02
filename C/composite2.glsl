#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 compositeEffect(vec2 uv) {
    vec2 c = vec2(0.5);
    vec2 d = uv - c;
    float r2 = dot(d, d);
    vec2 uvd = c + d * (1.0 + 0.15 * r2 + 0.15 * r2 * r2);
    float wob = (hash(vec2(time_f * 0.73, uv.y * 13.7)) - 0.5) * 0.003;
    uvd.x += wob;
    uvd = clamp(uvd, 0.001, 0.999);

    float ca = 0.002 + 0.002 * sin(time_f * 0.37);
    vec2 shift = d * ca;
    float bleed = sin(uvd.y * iResolution.y * 0.2 + time_f * 5.0) * 0.003;

    float off = 0.01;
    vec3 col;
    col.r = texture(samp, uvd + vec2(off + bleed, 0.0) + shift).r;
    col.g = texture(samp, uvd).g;
    col.b = texture(samp, uvd - vec2(off + bleed, 0.0) - shift).b;

    float grain = hash(uvd * iResolution.xy + time_f * 41.0) * 2.0 - 1.0;
    col += grain * 0.03;

    float scan = sin(uvd.y * iResolution.y * 3.14159) * 0.06;
    col -= scan;

    float l = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(l), col, 0.92);

    float vig = 1.0 - smoothstep(0.25, 0.8, length(d));
    col *= vig;

    col = pow(max(col, 0.0), vec3(1.0 / 1.7));
    return clamp(col, 0.0, 1.0);
}

void main(void) {
    vec3 col = compositeEffect(tc);
    color = vec4(col, 1.0);
}
