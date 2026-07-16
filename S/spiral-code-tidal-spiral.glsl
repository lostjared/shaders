#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float tideA = sin(radius * 42.0 - angle * 5.0 - time_f * 2.0);
    float tideB = sin(radius * 27.0 + angle * 3.0 + time_f * 1.3);
    float falloff = 1.0 - smoothstep(0.05, 0.85, radius);
    vec2 q = rotation(log(radius + 0.06) * 1.8 - time_f * 0.12) * p;
    q += normalize(q + vec2(0.0001)) * (tideA * 0.012 + tideB * 0.006) * falloff;

    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;
    float foam = pow(max(tideA * 0.68 + tideB * 0.32, 0.0), 14.0) * falloff;
    vec3 result = source * vec3(0.84, 0.96, 1.03);
    result = mix(result, vec3(0.72, 0.91, 0.95), foam * 0.35);
    color = vec4(result, texture(samp, tc).a);
}
