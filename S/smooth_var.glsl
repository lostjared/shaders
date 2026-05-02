#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

void main(void) {
    vec2 texel = 1.0 / iResolution;
    float spread = 1.5;
    vec2 o = texel * spread;

    vec4 c0 = texture(samp, tc);
    vec4 cN = texture(samp, tc + vec2(0.0, o.y));
    vec4 cS = texture(samp, tc + vec2(0.0, -o.y));
    vec4 cE = texture(samp, tc + vec2(o.x, 0.0));
    vec4 cW = texture(samp, tc + vec2(-o.x, 0.0));
    vec4 cNE = texture(samp, tc + vec2(o.x, o.y));
    vec4 cNW = texture(samp, tc + vec2(-o.x, o.y));
    vec4 cSE = texture(samp, tc + vec2(o.x, -o.y));
    vec4 cSW = texture(samp, tc + vec2(-o.x, -o.y));

    vec4 mean = (c0 + cN + cS + cE + cW + cNE + cNW + cSE + cSW) / 9.0;

    float variance =
        dot(abs(c0 - mean).rgb, vec3(0.333)) +
        dot(abs(cN - mean).rgb, vec3(0.333)) +
        dot(abs(cS - mean).rgb, vec3(0.333)) +
        dot(abs(cE - mean).rgb, vec3(0.333)) +
        dot(abs(cW - mean).rgb, vec3(0.333)) +
        dot(abs(cNE - mean).rgb, vec3(0.333)) +
        dot(abs(cNW - mean).rgb, vec3(0.333)) +
        dot(abs(cSE - mean).rgb, vec3(0.333)) +
        dot(abs(cSW - mean).rgb, vec3(0.333));

    variance /= 9.0;

    float strength = smoothstep(0.05, 0.15, variance) * clamp(amp + uamp, 0.0, 1.0);

    vec4 tent = (c0 * 4.0 +
                 (cN + cS + cE + cW) * 2.0 +
                 (cNE + cNW + cSE + cSW)) /
                16.0;

    color = mix(c0, tent, strength);
}
