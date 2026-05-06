#version 330 core
// ant_light_color_galaxy_swirl
// Galaxy arm structure with star density field and nebula color clouds

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 galaxy(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.1, 0.3, 0.6)));
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
    p = rot(iTime * 0.05) * p;

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Spiral arm formula
    float arms = 2.0;
    float armTightness = 3.0 + bass * 2.0;
    float spiral = sin(angle * arms - log(r + 0.01) * armTightness + iTime * 0.5);
    float armDensity = pow(max(spiral, 0.0), 2.0);

    // Star field
    float starNoise = noise(p * 50.0);
    float stars = step(0.96, starNoise);
    float starBright = pow(starNoise, 20.0) * 3.0;

    // Nebula cloud
    float nebulaN = noise(p * 4.0 + iTime * 0.1);
    nebulaN += noise(p * 8.0 - iTime * 0.15) * 0.5;

    // Texture through galaxy warp
    vec2 galUV = vec2(cos(angle + armDensity * 0.3), sin(angle + armDensity * 0.3)) * r * 0.5 + 0.5;
    float chroma = treble * 0.03;
    vec3 col;
    col.r = texture(samp, galUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, galUV).g;
    col.b = texture(samp, galUV - vec2(chroma, 0.0)).b;

    // Galaxy arm color overlay
    col = mix(col, col * galaxy(armDensity + nebulaN + iTime * 0.05) * 2.0, armDensity * (0.3 + mid * 0.4));

    // Nebula color clouds
    col += galaxy(nebulaN + iTime * 0.1) * nebulaN * armDensity * (0.2 + air * 0.5);

    // Stars
    col += galaxy(starNoise * 3.0 + iTime) * (stars + starBright) * (0.5 + treble);

    // Galactic core
    float core = exp(-r * (5.0 - bass * 3.0));
    col += galaxy(iTime * 0.2) * core * (2.0 + amp_peak * 4.0);

    col *= smoothstep(1.5, 0.3, r);
    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
