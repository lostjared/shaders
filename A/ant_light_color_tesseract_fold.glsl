#version 330 core
// ant_light_color_tesseract_fold
// 4D tesseract projection fold with rotating hyperplanes and color axis

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 hyper(float t) {
    return 0.5 + 0.5 * cos(TAU * (t * 1.5 + vec3(0.0, 0.25, 0.5)));
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

    // Simulate 4D fold: iterate fold+rotate in fake w-axis
    vec2 z = p * (2.0 + bass);
    float w = sin(iTime * 0.3 + length(p) * 2.0); // 4th dimension projection

    vec3 glow = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        // Fold absolute
        z = abs(z) - vec2(0.6 - mid * 0.1, 0.6 - treble * 0.1);

        // Rotate in xy and fake xw
        z = rot(iTime * 0.1 + float(i) * 0.5 + w * 0.3) * z;

        // Scale
        z *= 1.1;

        // Accumulate glow from orbit trap
        float d = min(abs(z.x), abs(z.y));
        float g = 0.005 / (d + 0.005);
        g = min(g, 2.0);
        glow += hyper(float(i) * 0.12 + d + iTime * 0.05) * g;
    }

    // Texture through fold warp
    vec2 sampUV = fract(z * 0.02 + tc);
    float chroma = treble * 0.04;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Blend fractal glow
    col += glow * (0.1 + air * 0.2);

    // Hyperplane intersection highlights
    float edge = max(smoothstep(0.02, 0.0, abs(z.x)), smoothstep(0.02, 0.0, abs(z.y)));
    col += hyper(iTime * 0.2 + w) * edge * (1.0 + bass * 2.0);

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
