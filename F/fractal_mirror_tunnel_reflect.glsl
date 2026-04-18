#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_rms;

const float PI = 3.1415926535897932384626433832795;

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float t = time_f;
    float aspect = iResolution.x / iResolution.y;
    vec2 ctr = vec2(0.5);

    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    float tunnelSpeed = t * 0.8 * (1.0 + aLow * 0.5);
    float tunnelR = 0.3 / rD;
    float tunnelAng = ang / PI;

    vec2 tunnelUV = vec2(tunnelR + tunnelSpeed, tunnelAng);
    tunnelUV.x += sin(tunnelAng * 4.0 + t * 2.0) * 0.1 * aMid;
    tunnelUV = 1.0 - abs(1.0 - 2.0 * fract(tunnelUV));

    vec4 tex = texture(samp, tunnelUV);
    float fade = smoothstep(0.0, 0.3, rD);
    tex.rgb *= fade;
    tex.rgb *= 1.0 + aPk * 0.6;
    tex.rgb = mix(tex.rgb, tex.rgb * vec3(1.0 + aLow * 0.3, 1.0, 1.0 + aHigh * 0.25), aPk);
    color = tex;
}
