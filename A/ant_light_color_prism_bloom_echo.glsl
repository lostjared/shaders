#version 330 core
// ant_light_color_prism_bloom_echo
// Blooming prism echoes with layered dispersion and petal-shaped light halos

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

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Petal bloom shape
    float petals = 6.0 + floor(bass * 4.0);
    float petalShape = cos(angle * petals + iTime * 0.6);

    // Layered prism echoes
    vec3 result = vec3(0.0);
    float totalWeight = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        float echoScale = 1.0 + i * (0.08 + treble * 0.06);
        float echoRot = i * 0.05 + iTime * 0.02 * (mod(i, 2.0) * 2.0 - 1.0);

        vec2 echoP = rot(echoRot) * p * echoScale;
        echoP.x /= aspect;
        vec2 echoUV = echoP + 0.5;

        // Per-echo chromatic dispersion
        float disp = i * 0.004 * (1.0 + mid);
        vec3 s;
        s.r = texture(samp, echoUV + vec2(disp, 0.0)).r;
        s.g = texture(samp, echoUV).g;
        s.b = texture(samp, echoUV - vec2(disp, 0.0)).b;

        float weight = 1.0 / (1.0 + i * 0.5);
        s *= rainbow(i * 0.12 + r + iTime * 0.2);
        result += s * weight;
        totalWeight += weight;
    }
    result /= totalWeight;

    // Petal halo glow
    float halo = pow(max(petalShape, 0.0), 4.0) * exp(-r * 2.5);
    result += rainbow(angle / TAU + iTime * 0.15) * halo * (1.0 + mid * 2.0 + air * 1.5);

    // Central bloom
    float bloom = exp(-r * (4.0 - bass * 2.5));
    result += rainbow(iTime * 0.3) * bloom * (1.0 + amp_peak * 3.0);

    result *= 0.85 + amp_smooth * 0.35;
    result = mix(result, vec3(1.0) - result, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
