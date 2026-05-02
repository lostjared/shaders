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

    // Bass drives logarithmic spiral zoom
    float zoomSpeed = 1.0 + amp_low * 5.0;
    float spiralAngle = angle + log(dist + 0.01) * (3.0 + amp_mid * 4.0) - time_f * zoomSpeed;

    // RMS adds radial breathing
    float breathe = 1.0 + amp_rms * 0.4 * sin(time_f * 2.5);
    dist *= breathe;

    vec2 spiralUV = vec2(
        fract(spiralAngle / 6.28318 + 0.5),
        fract(log(dist + 0.01) * 2.0 + time_f * 0.5));

    vec4 tex = texture(samp, spiralUV);

    // Treble adds concentric ring emphasis
    float ring = sin(dist * (30.0 + amp_high * 40.0) - time_f * 8.0);
    ring = smoothstep(0.8, 1.0, ring) * amp_high * 0.4;
    tex.rgb += ring;

    // Center vignette inverts with peaks
    float vign = smoothstep(1.5, 0.2, dist);
    vign = mix(vign, 1.0, amp_peak * 0.5);
    tex.rgb *= vign;

    // Peak flash
    tex.rgb += smoothstep(0.7, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
