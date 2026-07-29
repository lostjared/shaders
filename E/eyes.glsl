#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec4 sampleRipple(vec2 uv) {
    float speedR = 5.0, amplitudeR = 0.03, wavelengthR = 10.0;
    float speedG = 6.5, amplitudeG = 0.025, wavelengthG = 12.0;
    float speedB = 4.0, amplitudeB = 0.035, wavelengthB = 8.0;

    float rR = sin(uv.x * wavelengthR + time_f * speedR) * amplitudeR;
    rR += sin(uv.y * wavelengthR * 0.8 + time_f * speedR * 1.2) * amplitudeR;
    vec2 uvR = uv + vec2(rR, rR);

    float rG = sin(uv.x * wavelengthG * 1.5 + time_f * speedG) * amplitudeG;
    rG += sin(uv.y * wavelengthG * 0.3 + time_f * speedG * 0.7) * amplitudeG;
    vec2 uvG = uv + vec2(rG, -rG * 0.5);

    float rB = sin(uv.x * wavelengthB * 0.5 + time_f * speedB) * amplitudeB;
    rB += sin(uv.y * wavelengthB * 1.7 + time_f * speedB * 1.3) * amplitudeB;
    vec2 uvB = uv + vec2(rB * 0.3, rB);

    vec4 c = texture(samp, uv);
    c.r = texture(samp, uvR).r;
    c.g = texture(samp, uvG).g;
    c.b = texture(samp, uvB).b;
    return c;
}

vec4 lens(vec2 uv, vec2 center, float radius, float k) {
    vec2 d = (uv - center) / radius;
    float r = length(d);
    if (r > 1.0) return vec4(0.0);
    float r2 = r * r;
    float s = 1.0 - k * r2;
    vec2 suv = center + d * s * radius;
    float v = 1.0 - smoothstep(0.82, 1.0, r);
    vec4 c = sampleRipple(suv);
    c.rgb *= v;
    c.a = v;
    return c;
}

void main() {
    const vec2 centers[8] = vec2[](
        vec2(0.35, 0.45),
        vec2(0.65, 0.45),
        vec2(0.25, 0.35),
        vec2(0.50, 0.30),
        vec2(0.75, 0.35),
        vec2(0.25, 0.65),
        vec2(0.50, 0.70),
        vec2(0.75, 0.65)
    );
    const float radii[8] = float[](
        0.18, 0.18, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12
    );
    const float k = 0.35;

    vec3 acc = vec3(0.0);
    float w = 0.0;
    for (int i = 0; i < 8; ++i) {
        vec4 c = lens(tc, centers[i], radii[i], k);
        acc += c.rgb;
        w += c.a;
    }
    if (w > 0.0) acc /= w;
    else acc = sampleRipple(tc).rgb;

    color = vec4(acc, 1.0);
}
