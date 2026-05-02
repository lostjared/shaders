#version 330 core
// ant_light_color_electric_web
// Electric spider web with pulsing nodes, arc lightning, and spectrum color

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    p = rot(iTime * 0.15) * p;

    float rad = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    // Web radials
    float N = 10.0 + floor(bass * 8.0);
    float stepA = TAU / N;
    float a = mod(ang + iTime * 0.05, stepA);
    a = abs(a - stepA * 0.5);
    float radialLine = smoothstep(0.03, 0.0, a * rad);

    // Web rings (logarithmic)
    float ringSpacing = 0.15 + mid * 0.1;
    float ring = smoothstep(0.04, 0.0, abs(fract(log(rad) / ringSpacing + iTime * 0.3) - 0.5));

    float web = max(radialLine, ring);

    // Texture sample through kaleidoscope
    vec2 kUV = vec2(cos(a), sin(a)) * rad;
    kUV.x /= aspect;
    vec2 sampUV = kUV + 0.5;

    vec3 col = texture(samp, sampUV).rgb;

    // Electric glow on web lines
    vec3 elecColor = rainbow(ang / TAU + rad * 2.0 + iTime * 0.3);
    col += elecColor * web * (2.0 + treble * 3.0);

    // Arc lightning flicker on nodes
    float node = radialLine * ring;
    float flicker = sin(iTime * 30.0 + rad * 50.0) * 0.5 + 0.5;
    col += rainbow(iTime * 0.5 + rad) * node * flicker * (3.0 + air * 5.0);

    // Bass pulse on center
    float center = exp(-rad * (4.0 - bass * 3.0));
    col += rainbow(iTime * 0.2) * center * (1.0 + amp_peak * 2.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
