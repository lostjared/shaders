#version 330 core
// ant_spectrum_crystal_echo
// Crystalline refraction grid with echo reflections and prismatic rainbow bands

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.38).r;
    float treble = texture(spectrum, 0.60).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    // Crystal lattice: hexagonal mirror fold
    vec2 p = uv;
    p *= rot(iTime * 0.05);
    float hexScale = 3.0 + bass * 2.0;
    p *= hexScale;

    // Hex fold
    vec2 hexUV = p;
    hexUV.x += hexUV.y * 0.577;
    vec2 hexID = floor(hexUV);
    hexUV = fract(hexUV) - 0.5;
    hexUV = abs(hexUV);

    // Crystal facet refraction
    vec2 normal = normalize(hexUV + 0.001);
    float refractStr = 0.05 + mid * 0.08;
    vec2 refracted = tc + normal * refractStr;

    // Mirror wrap
    vec2 texUV = mirror(refracted);

    // Chromatic crystal split
    float spread = 0.008 + treble * 0.03;
    vec3 result;
    result.r = texture(samp, mirror(texUV + normal * spread)).r;
    result.g = texture(samp, texUV).g;
    result.b = texture(samp, mirror(texUV - normal * spread)).b;

    // Echo reflections: bounced samples
    for (float e = 1.0; e < 5.0; e++) {
        vec2 bounce = normal * e * 0.02 * (1.0 + hiMid);
        vec3 echoCol = texture(samp, mirror(texUV + bounce)).rgb;
        echoCol *= rainbow(e * 0.2 + length(hexID) * 0.3 + iTime * 0.2);
        result += echoCol * (0.2 / e);
    }

    // Rainbow crystal facet tint
    float facetAngle = atan(hexUV.y, hexUV.x);
    vec3 facetColor = rainbow(facetAngle / PI + length(hexID) * 0.15 + iTime * 0.3);
    result = mix(result, result * facetColor * 1.4, 0.3 + bass * 0.2);

    // Facet edge highlight
    float edge = smoothstep(0.0, 0.06, min(0.5 - abs(hexUV.x), 0.5 - abs(hexUV.y)));
    result = mix(result + rainbow(iTime * 0.5) * 0.4, result, edge);

    // Color shift
    result = mix(result, result.gbr, air * 0.4);

    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(result, 1.0);
}
