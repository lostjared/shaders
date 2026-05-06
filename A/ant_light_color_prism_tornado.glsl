#version 330 core
// ant_light_color_prism_tornado
// Tornado funnel with prismatic light dispersion and bass-driven spin

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
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Tornado funnel: twist increases toward center
    float twist = (5.0 + bass * 12.0) / (r + 0.15);
    angle += twist + iTime * (2.0 + mid * 3.0);

    // Funnel compression
    float funnel = r * (1.0 + 0.5 * sin(angle * 3.0 + iTime));
    vec2 tUV = vec2(cos(angle), sin(angle)) * funnel * 0.5 + 0.5;

    // Prismatic dispersion per channel
    float disp = 0.03 + treble * 0.06;
    vec3 col;
    col.r = texture(samp, tUV + vec2(disp, 0.0)).r;
    col.g = texture(samp, tUV).g;
    col.b = texture(samp, tUV - vec2(disp, 0.0)).b;

    // Spiral arm light bands
    float arms = sin(angle * (5.0 + floor(mid * 4.0)) + log(r + 0.01) * 6.0 - iTime * 4.0);
    arms = pow(max(arms, 0.0), 3.0);
    col += rainbow(angle / TAU + r + iTime * 0.2) * arms * (0.6 + air * 1.5);

    // Core light bloom
    float bloom = exp(-r * (3.0 - bass * 2.0));
    col += vec3(1.0, 0.95, 0.85) * bloom * (1.0 + amp_peak * 4.0);

    // Vignette
    col *= smoothstep(1.8, 0.3, r);
    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
