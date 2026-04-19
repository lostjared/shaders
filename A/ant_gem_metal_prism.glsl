#version 330 core
// ant_gem_metal_prism
// Prismatic metal refractions with light split and spectrum-driven dispersion

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Triangular prism: 3-fold symmetry
    float seg = 3.0;
    float stepVal = 2.0 * PI / seg;
    float foldAngle = mod(angle + PI, stepVal);
    foldAngle = abs(foldAngle - stepVal * 0.5);
    vec2 prismUV = vec2(cos(foldAngle), sin(foldAngle)) * r;

    // Dispersion: each color channel at different refraction angle
    float dispersion = 0.03 + bass * 0.04 + treble * 0.03;
    vec2 redUV = vec2(cos(foldAngle + dispersion), sin(foldAngle + dispersion)) * r;
    vec2 blueUV = vec2(cos(foldAngle - dispersion), sin(foldAngle - dispersion)) * r;

    // Map to texture coordinates
    vec2 prismTC = prismUV / vec2(aspect, 1.0) + 0.5;
    vec2 redTC = redUV / vec2(aspect, 1.0) + 0.5;
    vec2 blueTC = blueUV / vec2(aspect, 1.0) + 0.5;

    // Rotation drift
    float rotSpeed = time_f * 0.4 + mid * 1.5;
    prismTC = rot(rotSpeed) * (prismTC - 0.5) + 0.5;
    redTC = rot(rotSpeed) * (redTC - 0.5) + 0.5;
    blueTC = rot(rotSpeed) * (blueTC - 0.5) + 0.5;

    vec3 baseTex;
    baseTex.r = texture(samp, redTC).r;
    baseTex.g = texture(samp, prismTC).g;
    baseTex.b = texture(samp, blueTC).b;

    // Rainbow dispersion bands along prism edge
    float edgeDist = abs(prismUV.y);
    float dispBand = sin(edgeDist * (30.0 + mid * 20.0) - time_f * 3.0);
    vec3 rainbow = metalSpectrum(edgeDist * 3.0 + time_f * 0.2 + dispBand * 0.2);
    float bandMask = smoothstep(0.1, 0.3, edgeDist) * (1.0 - smoothstep(0.5, 0.7, edgeDist));

    vec3 finalColor = mix(baseTex, baseTex * rainbow, bandMask * (0.4 + hiMid * 0.4));

    // Internal reflections: bright caustic lines
    float caustic = abs(sin(prismUV.x * 20.0 + prismUV.y * 15.0 - time_f * 2.0));
    caustic = pow(caustic, 8.0) * (1.0 + treble * 2.0);
    finalColor += metalSpectrum(prismUV.x + time_f * 0.15) * caustic * 0.5;

    // Central glow
    float center = exp(-r * (5.0 - amp_smooth * 3.0));
    finalColor += vec3(1.0, 0.98, 0.95) * center * (1.5 + amp_peak * 2.0);

    // Air shimmer
    finalColor += metalSpectrum(angle + time_f * 0.3) * air * 0.08;

    color = vec4(finalColor, 1.0);
}
