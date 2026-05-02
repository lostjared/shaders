#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void main(void) {
    vec2 texel = 1.0 / iResolution;

    vec4 c0 = texture(samp, tc);

    vec2 o1 = texel * 1.0;
    vec2 o2 = texel * 1.5;

    vec2 k[9] = vec2[](
        vec2(0.0, 0.0),
        vec2(1.0, 0.0), vec2(-1.0, 0.0),
        vec2(0.0, 1.0), vec2(0.0, -1.0),
        vec2(1.0, 1.0), vec2(-1.0, 1.0),
        vec2(1.0, -1.0), vec2(-1.0, -1.0));

    float sigma_s = 1.0;
    float sigma_r = 0.15;

    float wsum = 0.0;
    vec3 acc = vec3(0.0);

    for (int i = 0; i < 9; i++) {
        vec2 dp = k[i] * o1;
        vec4 c = texture(samp, tc + dp);
        float dsq = dot(dp / (texel * 1.0), dp / (texel * 1.0));
        float wr = exp(-pow(max(0.0, luma(c.rgb) - luma(c0.rgb)), 2.0) / (2.0 * sigma_r * sigma_r));
        float ws = exp(-dsq / (2.0 * sigma_s * sigma_s));
        float w = wr * ws;
        acc += c.rgb * w;
        wsum += w;
    }

    vec3 bilateral = acc / max(wsum, 1e-6);

    vec4 cN = texture(samp, tc + vec2(0.0, o1.y));
    vec4 cS = texture(samp, tc + vec2(0.0, -o1.y));
    vec4 cE = texture(samp, tc + vec2(o1.x, 0.0));
    vec4 cW = texture(samp, tc + vec2(-o1.x, 0.0));

    float edge = abs(luma(cE.rgb) - luma(cW.rgb)) + abs(luma(cN.rgb) - luma(cS.rgb));

    vec4 wide =
        (texture(samp, tc + vec2(0.0, 0.0)) * 4.0 +
         (texture(samp, tc + vec2(o2.x, 0.0)) + texture(samp, tc + vec2(-o2.x, 0.0)) +
          texture(samp, tc + vec2(0.0, o2.y)) + texture(samp, tc + vec2(0.0, -o2.y))) *
             2.0 +
         (texture(samp, tc + vec2(o2.x, o2.y)) + texture(samp, tc + vec2(-o2.x, o2.y)) +
          texture(samp, tc + vec2(o2.x, -o2.y)) + texture(samp, tc + vec2(-o2.x, -o2.y)))) /
        16.0;

    float localVar =
        (abs(luma(c0.rgb) - luma(wide.rgb)) +
         abs(luma(cN.rgb) - luma(wide.rgb)) +
         abs(luma(cS.rgb) - luma(wide.rgb)) +
         abs(luma(cE.rgb) - luma(wide.rgb)) +
         abs(luma(cW.rgb) - luma(wide.rgb))) /
        5.0;

    float baseStrength = smoothstep(0.02, 0.12, localVar);
    float edgeProtect = 1.0 - smoothstep(0.05, 0.20, edge);
    float userGain = clamp(amp + uamp, 0.0, 1.0);
    float strength = clamp(baseStrength * edgeProtect * userGain, 0.0, 1.0);

    float t = 0.5 + 0.5 * sin(time_f * 0.6);
    vec3 melted = mix(bilateral, wide.rgb, t);

    vec3 outRGB = mix(c0.rgb, melted, strength);
    color = vec4(outRGB, 1.0);
}
