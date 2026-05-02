#version 330 core
// ant_light_color_liquid_prism
// Liquid surface refraction through a rotating prism with spectrum dispersion

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Liquid surface waves
    float wave1 = noise(uv * 6.0 + iTime * vec2(0.7, 0.3));
    float wave2 = noise(uv * 10.0 - iTime * vec2(0.4, 0.8));
    vec2 liquid = uv + vec2(wave1, wave2) * 0.05 * (1.0 + bass);

    // Prism rotation
    float prismAngle = iTime * 0.3 + mid;
    float angle = atan(liquid.y, liquid.x) + prismAngle;
    float r = length(liquid);

    // Triangular prism faces (3 faces)
    float face = mod(angle + 1.047, 2.094) - 1.047;
    face = abs(face);

    // Dispersion: different refraction per color channel
    float dispBase = 0.02 + treble * 0.08;
    vec2 uvR = liquid + vec2(cos(angle), sin(angle)) * dispBase;
    vec2 uvG = liquid;
    vec2 uvB = liquid - vec2(cos(angle), sin(angle)) * dispBase;

    vec3 col;
    col.r = texture(samp, uvR * 0.5 + 0.5).r;
    col.g = texture(samp, uvG * 0.5 + 0.5).g;
    col.b = texture(samp, uvB * 0.5 + 0.5).b;

    // Liquid caustic light patterns
    float caustic = pow(wave1 * wave2, 2.0) * 4.0;
    col += rainbow(wave1 + iTime * 0.2) * caustic * (0.3 + air * 0.8);

    // Prism face edge highlight
    float edgeGlow = smoothstep(0.02, 0.0, abs(face));
    col += rainbow(angle / TAU + iTime * 0.15) * edgeGlow * (1.0 + mid * 2.0);

    // Spectrum wash
    col *= rainbow(r * 2.0 - iTime * 0.2 + bass);
    col = mix(texture(samp, tc).rgb, col, 0.7);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
