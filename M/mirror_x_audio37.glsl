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

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    float dist = length(uv - 0.5);
    float shatter = floor(atan(uv.y - 0.5, uv.x - 0.5) * (3.0 + 3.0 * aLow) / 3.14159);
    float shatterAngle = shatter * 0.5 + t * 0.3;
    float cs = cos(shatterAngle), sn = sin(shatterAngle);
    vec2 p = uv - 0.5;
    uv = vec2(p.x * cs - p.y * sn, p.x * sn + p.y * cs) + 0.5;
    uv += (uv - 0.5) * 0.1 * aMid * sin(t * 3.0 + shatter);
    uv = fract(uv);
    vec4 tex = texture(samp, uv);
    float edge = abs(fract(shatter * 0.5) - 0.5) * 2.0;
    edge = smoothstep(0.9, 1.0, edge) * aHigh * 0.3;
    tex.rgb += edge * vec3(1.0, 0.6, 0.2);
    tex.rgb *= 1.0 + amp_peak * 0.5;
    color = tex;
}
