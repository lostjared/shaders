#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;

vec3 getRainbowColor(float position) {
    float r = sin(position + 0.0) * 0.5 + 0.5;
    float g = sin(position + 2.0) * 0.5 + 0.5;
    float b = sin(position + 4.0) * 0.5 + 0.5;
    return vec3(r, g, b);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float a = clamp(amp, 0.0, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    float time_t = pingPong(time_f, 10.0) + 2.0;

    float waveAmp = mix(0.02, 0.12, a);
    float wave = sin((tc.y - m.y) * 10.0 + time_f * (1.0 + a * 3.0)) * waveAmp;
    vec2 new_tc = vec2(tc.x + wave, tc.y);
    new_tc = clamp(new_tc, vec2(0.0), vec2(1.0));
    vec4 texColor = texture(samp, new_tc);

    vec2 p = tc - m;
    float c = cos(time_f);
    float s = sin(time_f);
    vec2 pr = vec2(p.x * c - p.y * s, p.x * s + p.y * c);

    float rainbowPos = length(pr) * 10.0 + time_f * 5.0;
    vec3 rainbowColor = getRainbowColor(sin(rainbowPos * time_t));

    float mixAmt = 0.25 + 0.5 * a;
    vec3 mixed = mix(texColor.rgb, rainbowColor, mixAmt);
    vec4 outc = vec4(mixed, texColor.a);
    color = sin(outc * time_t);
    color.a = 1.0;
}
