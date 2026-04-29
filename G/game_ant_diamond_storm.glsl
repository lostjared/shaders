#version 330 core
// Diamond storm — sparse animated specular sparkles on highlights.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec2 g = floor(tc * iResolution / 6.0);
    float h = hash(g);
    float spark = step(0.965, h) * smoothstep(0.35, 0.9, lum);
    spark *= 0.5 + 0.5 * sin(time_f * 8.0 + h * 40.0);
    color = vec4(c + vec3(spark) * 1.6, 1.0);
}
