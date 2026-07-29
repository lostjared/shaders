#version 330 core
// ant_light_color_flicker_gem
// Gem facet flicker with rapid color cycling and bass-driven facet rotation

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 gem(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.2, 0.5)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Bass-driven rotation
    p = rot(iTime * 0.4 + bass * 3.0) * p;
    p *= 1.0 - bass * 0.25;

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Gem facets
    float facets = 8.0 + floor(mid * 12.0);
    float stepA = TAU / facets;
    float a = mod(angle, stepA);
    a = abs(a - stepA * 0.5);

    // Facet flicker: rapid brightness modulation
    float facetIdx = floor(angle / stepA);
    float flicker = sin(iTime * 15.0 + facetIdx * 2.5) * 0.5 + 0.5;
    flicker = mix(1.0, flicker, treble);

    // Inner fractal depth
    vec2 fp = vec2(cos(a), sin(a)) * r;
    for (int i = 0; i < 3; i++) {
        fp = abs(fp) - 0.25;
        fp = rot(iTime * 0.15 + float(i) * 0.6) * fp;
    }

    fp.x /= aspect;
    vec2 sampUV = fp + 0.5;

    float chroma = (treble + air) * 0.04 * flicker;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Gem color cycling
    vec3 gemColor = gem(facetIdx / facets + iTime * 0.5 + bass);
    col *= mix(vec3(1.0), gemColor * 1.5, 0.3 + mid * 0.4);

    // Flicker brightness
    col *= 0.6 + flicker * 0.8;

    // Facet edge sparkle
    float edgeDist = abs(a);
    float sparkle = smoothstep(0.02, 0.0, edgeDist * r);
    col += gem(iTime * 0.3 + facetIdx * 0.1) * sparkle * (2.0 + air * 3.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
