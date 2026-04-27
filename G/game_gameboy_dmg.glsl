#version 330 core
// Original Game Boy DMG 4-tone green palette quantization.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 p0 = vec3(0.06, 0.22, 0.06);
    vec3 p1 = vec3(0.19, 0.38, 0.19);
    vec3 p2 = vec3(0.55, 0.67, 0.06);
    vec3 p3 = vec3(0.61, 0.74, 0.06);
    vec3 quant;
    if (lum < 0.25)      quant = p0;
    else if (lum < 0.5)  quant = p1;
    else if (lum < 0.75) quant = p2;
    else                 quant = p3;
    color = vec4(quant, 1.0);
}
