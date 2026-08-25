#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;





float h1(float n){return fract(sin(n)*43758.5453123);}
vec2 h2(float n){return fract(sin(vec2(n, n+1.0))*vec2(43758.5453,22578.1459));}

void main(void) {
    vec2 uv = tc;
    float rate = 0.8;
    float t = time_f*rate;
    float t0 = floor(t);
    float a = fract(t);
    vec2 p0 = vec2(0.1) + h2(t0)*0.8;
    vec2 p1 = vec2(0.1) + h2(t0+1.0)*0.8;
    float w = a*a*(3.0-2.0*a);
    vec2 m_auto = mix(p0, p1, w);
    vec2 m = (iMouse.z>0.5 || iMouse.w>0.5) ? (iMouse.xy/iResolution) : m_auto;

    vec2 d = uv - m;
    float dist = length(d);
    float a1 = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);
    float r = mix(0.06, 0.35, a1) * 1.5;
    float s = smoothstep(r, 0.0, dist);
    float k = 0.6 + 0.4 * ua;
    float swirl = (0.8 * ua + 0.2 * a1) * s * (r - dist) * 8.0;
    float ang = atan(d.y, d.x) + swirl;
    vec2 drot = vec2(cos(ang), sin(ang)) * dist;
    float lens = 1.0 - k * s * (1.0 - dist / r);
    vec2 warped = m + drot * lens;
    float wob = sin(time_f * 3.0 + dist * 20.0) * 0.005 * ua * s;
    vec2 n = normalize(drot + vec2(1e-6));
    warped += n * wob;

    vec4 warpedCol = texture(samp, clamp(warped, vec2(0.0), vec2(1.0)));
    color = warpedCol;
}
