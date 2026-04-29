#version 330 core
// Metal chrome — cool desaturated chrome look with rim brighten.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(vec3(lum), c, 0.30) * vec3(0.93, 0.99, 1.14);
    vec2 p = tc - 0.5;
    float rim = smoothstep(0.20, 0.65, length(p));
    chrome += vec3(0.20, 0.25, 0.35) * rim;
    color = vec4(chrome, 1.0);
}
