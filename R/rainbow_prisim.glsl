#version 330
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main(void) {
    float A = clamp(amp, 0.0, 1.0);
    float U = clamp(uamp, 0.0, 1.0);
    float time_z = pingPong(time_f, 4.0) + 0.5;

    vec2 uv = tc;
    vec2 center = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 normPos = (uv - center) * vec2(iResolution.x / iResolution.y, 1.0);

    float dist = length(normPos);
    float phase = sin(dist * 10.0 - time_f * 4.0);
    float phaseGain = mix(0.6, 1.4, A);
    vec2 tcAdjusted = uv + (normPos * 0.305 * phase * phaseGain);

    float dispersionScale = 0.02 * (0.5 + U);
    vec2 dispersionOffset = normPos * dist * dispersionScale;

    vec2 tcAdjustedR = tcAdjusted - dispersionOffset;
    vec2 tcAdjustedG = tcAdjusted;
    vec2 tcAdjustedB = tcAdjusted + dispersionOffset;

    float r = texture(samp, tcAdjustedR).r;
    float g = texture(samp, tcAdjustedG).g;
    float b = texture(samp, tcAdjustedB).b;
    vec3 texColor = vec3(r, g, b);

    float angle = atan(normPos.y, normPos.x) + time_f;
    float hue = mod(angle / (2.0 * 3.14159265), 1.0);
    vec3 rainbowColor = hsv2rgb(vec3(hue, 1.0, 1.0));
    vec3 modColor = mix(texColor, texColor * rainbowColor, 0.4 + 0.6 * A);

    float time_t = pingPong(time_f, 8.0) + 2.0 + time_z * 0.1 * (0.5 + U);
    color = vec4(sin(modColor * time_t), 1.0);
}
