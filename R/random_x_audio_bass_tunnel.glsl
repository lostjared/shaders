#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    // Bass drives tunnel zoom speed
    float speed = 2.0 + amp_low * 8.0;
    float tunnel = 1.0 / (dist + 0.1) + time_f * speed;
    float twist = angle / 3.14159 + amp_mid * sin(time_f * 1.5);

    vec2 tunnelUV = fract(vec2(tunnel, twist));

    // Treble adds chromatic split
    float chroma = amp_high * 0.03;
    float r = texture(samp, clamp(tunnelUV + vec2(chroma, 0.0), 0.0, 1.0)).r;
    float g = texture(samp, clamp(tunnelUV, 0.0, 1.0)).g;
    float b = texture(samp, clamp(tunnelUV - vec2(chroma, 0.0), 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Vignette pulses with peaks
    float vignette = smoothstep(1.5, 0.3 + amp_peak * 0.5, dist);
    col *= vignette;

    // Peak brightness flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.25;

    color = vec4(col, 1.0);
}
