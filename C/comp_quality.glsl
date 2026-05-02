#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash12(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }

vec3 tonemap(vec3 x) {
    x = x / (x + vec3(1.0));
    return pow(x, vec3(1.0 / 2.2));
}

vec3 compositeEffect(vec2 uv) {
    vec2 px = 1.0 / iResolution;
    float off = 1.5 * px.x;
    vec3 col;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;

    float n = hash12(uv * iResolution + time_f * 123.7) - 0.5;
    col += n * 0.02;

    float scan = sin((uv.y * iResolution.y) * 1.5) * 0.06;
    col -= scan;

    float bleed = sin(uv.y * iResolution.y * 0.2 + time_f * 5.0) * 0.004;
    col += vec3(bleed * 0.001, 0.0, -bleed * 0.001); // smaller & balanced shift
    return col;
}

void main(void) {
    vec2 uv = tc;
    vec3 col = compositeEffect(uv);

    vec2 px = 1.0 / iResolution;
    vec3 blur =
        compositeEffect(uv + vec2(px.x, px.y)) +
        compositeEffect(uv + vec2(-px.x, px.y)) +
        compositeEffect(uv + vec2(px.x, -px.y)) +
        compositeEffect(uv + vec2(-px.x, -px.y));
    blur *= 0.25;

    float sharpAmt = 0.35;
    col += (col - blur) * sharpAmt;

    vec2 c = vec2(0.5);
    float v = smoothstep(0.95, 0.25, distance(uv, c));
    col *= v;

    col = tonemap(col);
    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
