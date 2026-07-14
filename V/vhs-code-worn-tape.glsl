#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.35));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 18.0);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float unstableLine = pow(hash21(vec2(line, frame)), 13.0);
    float wave = sin(uv.y * 85.0 + time_f * 2.4) * 0.003;
    uv.x += wave + (hash21(vec2(line, frame + 3.0)) - 0.5) * unstableLine * 0.12;
    uv.y += (hash21(vec2(frame, 4.0)) - 0.5) * 0.006;
    uv = clamp(uv, 0.001, 0.999);

    float split = 0.003 + unstableLine * 0.009;
    vec3 image;
    image.r = texture(samp, uv + vec2(split, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(split, 0.0)).b;

    float grain = hash21(gl_FragCoord.xy + frame * 29.0) - 0.5;
    float scratch = step(0.992, hash21(vec2(floor(gl_FragCoord.x * 0.25), frame * 0.1)));
    float flicker = 0.86 + hash21(vec2(frame, 2.0)) * 0.14;
    image *= flicker;
    image += grain * 0.11 + scratch * (0.2 + grain * 0.3);
    image = mix(vec3(dot(image, vec3(0.299, 0.587, 0.114))), image, 0.78);
    image *= vec3(1.04, 0.96, 0.85);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
