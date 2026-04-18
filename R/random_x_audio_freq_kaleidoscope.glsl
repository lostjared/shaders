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

    // RMS controls segment count (3 to 12)
    float segments = floor(mix(3.0, 12.0, clamp(amp_rms * 3.0, 0.0, 1.0)));
    float segAngle = 6.28318 / segments;
    angle = mod(angle, segAngle);
    angle = abs(angle - segAngle * 0.5);

    // Mids rotate the kaleidoscope
    float rot = time_f * (0.4 + amp_mid * 3.0);
    angle += rot;

    // Bass pulses the zoom
    float zoom = 1.0 + amp_low * 0.4 * sin(time_f * 2.0);
    dist *= zoom;

    vec2 kaleUV = vec2(cos(angle), sin(angle)) * dist;
    kaleUV.x /= aspect;
    kaleUV += 0.5;

    vec4 tex = texture(samp, clamp(kaleUV, 0.0, 1.0));

    // Treble adds subtle hue shift
    float hueShift = amp_high * 0.15;
    tex.r += hueShift;
    tex.b -= hueShift * 0.5;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
