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
    vec2 center = vec2(0.5);
    vec2 dir = tc - center;

    // Peak triggers zoom strobe - snap between zoom in/out
    float zoomBase = 1.0;
    float zoomStrobe = amp_peak * 0.3 * sin(time_f * 15.0);
    float zoom = zoomBase + zoomStrobe;

    // Bass adds smooth zoom breathing
    zoom += amp_low * 0.15 * sin(time_f * 2.0);

    vec2 uv = center + dir * zoom;
    uv = clamp(uv, 0.0, 1.0);

    // Mids add rotation during zoom
    float angle = amp_mid * 0.3 * sin(time_f * 3.0);
    vec2 rotDir = dir;
    float c = cos(angle), s = sin(angle);
    rotDir = vec2(c * dir.x - s * dir.y, s * dir.x + c * dir.y);
    vec2 uv2 = center + rotDir * zoom;
    uv2 = clamp(uv2, 0.0, 1.0);

    // Blend between normal and rotated zoom
    vec3 col1 = texture(samp, uv).rgb;
    vec3 col2 = texture(samp, uv2).rgb;
    vec3 col = mix(col1, col2, 0.5);

    // Treble adds afterimage trail
    vec2 trailUV = center + dir * (zoom * 0.95);
    trailUV = clamp(trailUV, 0.0, 1.0);
    vec3 trail = texture(samp, trailUV).rgb;
    col = mix(col, trail, amp_high * 0.3);

    // Peak white flash
    col += smoothstep(0.7, 1.0, amp_peak) * 0.3;

    // Smooth global brightness
    col *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
