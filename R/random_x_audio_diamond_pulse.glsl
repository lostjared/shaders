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
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 ap = abs(p);

    // Diamond distance
    float diamond = ap.x + ap.y;

    // Bass pulses diamond rings
    float ringFreq = 8.0 + amp_low * 20.0;
    float rings = sin(diamond * ringFreq - time_f * (2.0 + amp_low * 5.0));
    rings = smoothstep(0.0, 0.3, rings);

    // Mids rotate the diamond pattern
    float ca = time_f * (0.3 + amp_mid * 1.5);
    float cc = cos(ca), ss = sin(ca);
    vec2 rp = vec2(cc * p.x - ss * p.y, ss * p.x + cc * p.y);
    float diamond2 = abs(rp.x) + abs(rp.y);

    // Sample texture with diamond distortion
    float warp = rings * (0.03 + amp_peak * 0.05);
    vec2 uv = tc + normalize(p + 0.001) * warp;
    uv = clamp(uv, 0.0, 1.0);

    vec4 tex = texture(samp, uv);

    // Treble adds diamond edge glow
    float edge = fract(diamond * 4.0 + time_f * 0.5);
    edge = smoothstep(0.45, 0.5, edge) - smoothstep(0.5, 0.55, edge);
    vec3 glow = vec3(0.8, 0.3, 1.0) * edge * amp_high * 2.0;
    tex.rgb += glow;

    // Peak brightness flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    // Smooth amp warmth
    tex.rgb *= 1.0 + amp_smooth * 0.15;

    color = vec4(clamp(tex.rgb, 0.0, 1.0), 1.0);
}
