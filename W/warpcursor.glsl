#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

void main(void) {
    vec2 uv = tc;
    vec2 m = iMouse.xy / iResolution;
    vec2 d = uv - m;
    float dist = length(d);
    float a = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);

    // radius scaled up 3x
    float r = mix(0.06, 0.35, a) * 1.5;

    float s = smoothstep(r, 0.0, dist);
    float k = 0.6 + 0.4 * ua;
    float swirl = (0.8 * ua + 0.2 * a) * s * (r - dist) * 8.0;
    float ang = atan(d.y, d.x) + swirl;
    vec2 drot = vec2(cos(ang), sin(ang)) * dist;
    float lens = 1.0 - k * s * (1.0 - dist / r);
    vec2 warped = m + drot * lens;
    float wob = sin(time_f * 3.0 + dist * 20.0) * 0.005 * ua * s;
    vec2 n = normalize(drot + vec2(1e-6));
    warped += n * wob;

    vec4 orig = texture(samp, uv);
    vec4 warpedCol = texture(samp, clamp(warped, vec2(0.0), vec2(1.0)));
    //color = mix(orig, warpedCol, s);
    color  = warpedCol;
}
