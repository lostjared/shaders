#version 330 core
// Cel-shaded anime look: posterized luminance + soft edge darkening.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, tc).rgb;

    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float steps = 5.0;
    float bin = floor(lum * steps) / steps + 0.5 / steps;
    vec3 quant = c * (bin / max(lum, 0.001));

    float gx = dot(texture(samp, tc + vec2(px.x, 0.0)).rgb - texture(samp, tc - vec2(px.x, 0.0)).rgb, vec3(0.333));
    float gy = dot(texture(samp, tc + vec2(0.0, px.y)).rgb - texture(samp, tc - vec2(0.0, px.y)).rgb, vec3(0.333));
    float edge = 1.0 - smoothstep(0.05, 0.18, sqrt(gx * gx + gy * gy));
    color = vec4(quant * edge, 1.0);
}
