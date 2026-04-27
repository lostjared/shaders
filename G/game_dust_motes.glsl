#version 330 core
// Drifting bright dust specks layered over the image. Adds atmosphere.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 uv = tc * vec2(iResolution.x / iResolution.y, 1.0) * 70.0;
    uv.y += time_f * 0.6;
    vec2 cell = floor(uv);
    vec2 f = fract(uv);
    float r = hash21(cell);
    vec2 center = vec2(hash21(cell + 17.0), hash21(cell + 43.0));
    float d = length(f - center);
    float spark = smoothstep(0.06, 0.0, d) * step(0.985, r);
    c += vec3(spark) * 0.55;
    color = vec4(c, 1.0);
}
