#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float PI = 3.1415926535897932384626433832795;
float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec3 rainbow(vec2 uv, float offset) {
    float rainbowFactor = sin(offset + uv.x * 10.0) * 0.5 + 0.5;
    return vec3(
        sin(rainbowFactor * 3.0 + 0.0),
        sin(rainbowFactor * 3.0 + 2.0),
        sin(rainbowFactor * 3.0 + 4.0));
}

void main(void) {
    vec4 texColor = texture(samp, tc);

    float phase = mod(time_f, 6.0);
    float t = fract(time_f / 2.0);
    vec2 uv = tc;
    vec3 rainbowColor;

    float angle = mix(0.0, 6.28318, t);

    angle = angle * time_f * PI;

    uv += vec2(sin(angle + length(uv) * 10.0), cos(angle + length(uv) * 10.0)) * 0.1;

    rainbowColor = rainbow(uv, pingPong(sin(time_f), 25.0));
    color = vec4(texColor.rgb + rainbowColor * 0.5, texColor.a);

    color = mix(color, 0.5 + vec4(rainbowColor, 1.0) * 0.5, 0.5);
}
