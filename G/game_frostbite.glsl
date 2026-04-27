#version 330 core
// Cool snowy / frostbite tint with sparkle highlights.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float h21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c *= vec3(0.85, 0.95, 1.10);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float sparkle = step(0.995, h21(gl_FragCoord.xy + floor(time_f * 8.0))) * smoothstep(0.6, 1.0, lum);
    c += sparkle * vec3(0.6, 0.8, 1.0);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
