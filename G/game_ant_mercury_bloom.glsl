#version 330 core
// Mercury bloom — silvery desaturation with soft luminance bloom.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec2 ts = 1.5 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 b  = (texture(samp, tc + vec2(ts.x, 0)).rgb + texture(samp, tc - vec2(ts.x, 0)).rgb
             + texture(samp, tc + vec2(0, ts.y)).rgb + texture(samp, tc - vec2(0, ts.y)).rgb) * 0.25;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 silver = mix(vec3(lum), c, 0.30) * vec3(0.93, 1.00, 1.12);
    silver += max(b - 0.35, 0.0) * 1.10;
    color = vec4(silver, 1.0);
}
