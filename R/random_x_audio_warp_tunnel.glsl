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

    // Bass drives tunnel depth zoom
    float tunnelDepth = 1.0 / (dist + 0.05) + time_f * (1.5 + amp_low * 6.0);

    // Mids twist the tunnel walls
    float twist = angle + time_f * (0.2 + amp_mid * 2.0) + amp_mid * sin(tunnelDepth * 0.5) * 1.5;

    vec2 tunnelUV = fract(vec2(tunnelDepth * 0.2, twist / 6.28318));

    // Treble adds radial wave distortion in the tunnel
    tunnelUV.x += amp_high * 0.02 * sin(tunnelUV.y * 20.0 + time_f * 5.0);

    // Wrap UVs
    tunnelUV = abs(mod(tunnelUV, 2.0) - 1.0);

    vec4 tex = texture(samp, clamp(tunnelUV, 0.0, 1.0));

    // Depth fog - closer = brighter, far = darker
    float fog = smoothstep(1.5, 0.1, dist);
    fog = mix(fog, 1.0, amp_smooth * 0.4);
    tex.rgb *= fog;

    // RMS ring glow
    float ringGlow = smoothstep(0.03, 0.0, abs(dist - 0.2 - amp_rms * 0.3));
    tex.rgb += ringGlow * vec3(0.2, 0.6, 1.0) * 0.5;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
