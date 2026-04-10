#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 compositeEffect(vec2 uv) {
    vec2 cuv = uv * 2.0 - 1.0;
    float r2 = dot(cuv, cuv);
    cuv *= 1.0 + 0.25 * r2;
    uv = cuv * 0.5 + 0.5;

    float vJitter = (rand(vec2(time_f * 3.17, 0.0)) - 0.5) * 0.01;
    uv.y = clamp(uv.y + vJitter, 0.0, 1.0);

    uv.x += sin(uv.y * 180.0 + time_f * 4.0) * 0.002;

    float lineDrift = sin(time_f * 0.7) * 0.01;
    uv.y = clamp(uv.y + lineDrift, 0.0, 1.0);

    vec2 uvR = uv + vec2(0.0025, 0.0);
    vec2 uvB = uv - vec2(0.0025, 0.0);

    vec3 srcR = texture(samp, uvR).rgb;
    vec3 srcG = texture(samp, uv).rgb;
    vec3 srcB = texture(samp, uvB).rgb;

    vec3 col;
    col.r = srcR.r;
    col.g = srcG.g;
    col.b = srcB.b;

    vec3 ghost = texture(samp, uv + vec2(0.006, 0.0)).rgb;
    col = mix(col, ghost, 0.15);

    float scanline = 0.7 + 0.3 * sin(uv.y * iResolution.y * 3.14159);
    col *= scanline;

    float fineNoise = rand(uv * iResolution.xy + time_f * 37.0);
    float coarseNoise = rand(vec2(0.0, floor(uv.y * iResolution.y * 0.5) + time_f * 5.0));
    float noise = fineNoise * 0.04 + coarseNoise * 0.06;
    col += noise;

    float band = step(0.97, fract(uv.y * 80.0 + time_f * 0.5));
    col *= 1.0 - band * 0.5;

    float dist = distance(uv, vec2(0.5));
    float vignette = clamp(1.0 - dist * 1.4, 0.0, 1.0);
    col *= vignette;

    col = pow(col, vec3(0.85));

    return col;
}

void main(void) {
    vec2 uv = tc;
    vec3 col = compositeEffect(uv);
    color = vec4(col, 1.0);
}
