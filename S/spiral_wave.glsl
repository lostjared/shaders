#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;

float h1(float n){return fract(sin(n)*43758.5453123);}
vec2 h2(float n){return fract(sin(vec2(n, n+1.0))*vec2(43758.5453,22578.1459));}

void main(void){
    vec2 uv = tc;
    float aspect = iResolution.x / iResolution.y;

    float t = time_f * 0.85;
    float t0 = floor(t);
    float a = fract(t);
    float w = a * a * (3.0 - 2.0 * a);
    vec2 p0 = vec2(0.15) + h2(t0) * 0.7;
    vec2 p1 = vec2(0.15) + h2(t0 + 1.0) * 0.7;
    vec2 autoP = mix(p0, p1, w);

    vec2 m = iMouse.z > 0.5 ? (iMouse.xy / iResolution) : autoP;

    vec2 p = (uv - m) * vec2(aspect, 1.0);
    float d = length(p);
    float fall = smoothstep(0.6, 0.0, d);

    float k = amp * 0.25;
    float bend = k * fall;
    vec2 perp = normalize(vec2(-p.y, p.x));
    if (!all(greaterThan(abs(p), vec2(0.0)))) perp = vec2(0.0);
    vec2 bendOff = perp * bend * (0.25 + 0.75 * sin(3.0 * d + time_f * 2.0));

    float stretch = uamp * 0.7 * fall;
    vec2 stretchOff = p * stretch * (0.6 + 0.4 * cos(4.0 * d - time_f * 1.6));

    float spiral = 0.9 * fall;
    float ang = atan(p.y, p.x);
    float rot = spiral * (0.8 + 0.2 * sin(time_f * 0.7)) * sin(time_f * 1.2 + 3.0 * d);
    float r = length(p);
    vec2 spin = vec2(cos(ang + rot), sin(ang + rot)) * r - p;

    vec2 off = (bendOff + stretchOff + spin) / vec2(aspect, 1.0);

    float wave = sin((uv.x + uv.y) * 18.0 + time_f * 12.0) * 0.003 * fall;
    vec2 wobble = vec2(0.0, wave);

    vec2 tuv = uv + off + wobble;

    color = texture(samp, tuv);
}
