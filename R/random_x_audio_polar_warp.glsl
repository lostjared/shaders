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

    // Convert to polar coordinates
    // Mids warp the angle
    angle += amp_mid * sin(dist * 8.0 - time_f * 2.0) * 1.5;

    // Bass warps the radius
    dist += amp_low * 0.15 * sin(angle * 3.0 + time_f * 3.0);
    dist *= 1.0 + amp_low * 0.3 * cos(time_f * 2.0);

    // Map back from polar
    vec2 warped = vec2(cos(angle), sin(angle)) * dist;
    warped.x /= aspect;
    warped += 0.5;

    // Treble adds micro-turbulence
    warped.x += amp_high * 0.005 * sin(warped.y * 80.0 + time_f * 10.0);
    warped.y += amp_high * 0.004 * cos(warped.x * 60.0 + time_f * 8.0);

    warped = clamp(warped, 0.0, 1.0);
    vec4 tex = texture(samp, warped);

    // RMS adds radial color shift
    float hshift = amp_rms * 0.1;
    tex.r += hshift * sin(angle);
    tex.b += hshift * cos(angle);

    // Smooth vignette that opens on smooth amp
    float vign = smoothstep(1.2, 0.3 + amp_smooth * 0.4, dist);
    tex.rgb *= vign;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
