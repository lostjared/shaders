#version 330 core
// Metal pulse — global rhythmic brightness pulse, gentle.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float pulse = 1.0 + 0.22 * sin(time_f * 1.6);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float hi = smoothstep(0.4, 0.95, lum);
    color = vec4(c * pulse + vec3(0.95, 0.95, 1.0) * hi * 0.40 * pulse, 1.0);
}
