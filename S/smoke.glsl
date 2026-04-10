#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float time = time_f * 0.1;
    vec2 noiseOffset = vec2(noise(uv + time), noise(uv - time));
    noiseOffset = (noiseOffset - 0.5) * 0.2;
    vec2 nuv = uv + noiseOffset;
    vec4 texColor = texture(samp, nuv);
    vec4 smokeColor = mix(texColor, vec4(0.6, 0.6, 0.6, 1.0), 0.2);
    color = smokeColor;
}
