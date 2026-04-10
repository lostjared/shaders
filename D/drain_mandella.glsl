#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;

void main(void) {
    float loopDuration = 25.0;
    float t = mod(time_f, loopDuration);
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.0);

    vec2 nc = (tc * 2.0 - 1.0) * aspect;
    nc.x = abs(nc.x);
    float d = length(nc);
    float a = atan(nc.y, nc.x);
    float spiralSpeed = 5.0;
    float inward = t / loopDuration;
    a += (1.0 - smoothstep(0.0, 8.0, d)) * t * spiralSpeed;
    d *= 1.0 - inward;
    vec2 spiral = vec2(cos(a), sin(a)) * tan(d);
    vec2 uv0 = (spiral / aspect + 1.0) * 0.5;

    vec2 p = (uv0 * 2.0 - 1.0) * aspect;
    float r = length(p);
    float ang = atan(p.y, p.x);

    float N = 10.0;
    float tau = 6.28318530718;
    float sector = tau / N;
    ang = mod(ang + 0.5 * sector, sector);
    ang = abs(ang - 0.5 * sector);

    float ringFreq = 6.0;
    float ring = fract(r * ringFreq + 0.15 * sin(time_f * 0.5));
    float ringMirror = abs(ring - 0.5) * 2.0;

    float swirl = 0.25 * sin(time_f * 0.3);
    ang += swirl * r;

    float zoom = 0.85 + 0.1 * sin(time_f * 0.27);
    vec2 m = vec2(cos(ang), sin(ang)) * (r * zoom * (0.85 + 0.15 * ringMirror));

    vec2 uv = (m / aspect + 1.0) * 0.5;

    vec2 px = 1.0 / iResolution;
    vec3 c = texture(samp, uv).rgb;
    c += texture(samp, uv + vec2(px.x, 0)).rgb;
    c += texture(samp, uv + vec2(-px.x, 0)).rgb;
    c += texture(samp, uv + vec2(0, px.y)).rgb;
    c += texture(samp, uv + vec2(0, -px.y)).rgb;
    c *= 0.2;

    float glow = smoothstep(0.95, 0.2, r) * (0.6 + 0.4 * ringMirror);
    vec3 base = c * (0.7 + 0.3 * glow);

    float hue = fract(ang / tau + 0.5 + 0.03 * time_f);
    float rC = clamp(abs(hue * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    float gC = clamp(2.0 - abs(hue * 6.0 - 2.0), 0.0, 1.0);
    float bC = clamp(2.0 - abs(hue * 6.0 - 4.0), 0.0, 1.0);
    vec3 rainbow = vec3(rC, gC, bC);

    float rbAmt = 0.35 * smoothstep(0.15, 0.85, ringMirror);
    vec3 outCol = mix(base, base * rainbow, rbAmt);

    float vign = smoothstep(1.2, 0.4, length((tc - 0.5) * aspect));
    outCol *= vign;

    color = vec4(outCol, 1.0);
}
