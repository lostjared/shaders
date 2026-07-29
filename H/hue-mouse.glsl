#version 330 core
in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

const int SEGMENTS = 6;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec4 adjustHue(vec4 c, float a) {
    float U = cos(a);
    float W = sin(a);
    mat3 R = mat3(
        0.299,  0.587,  0.114,
        0.299,  0.587,  0.114,
        0.299,  0.587,  0.114
    ) + mat3(
        0.701, -0.587, -0.114,
       -0.299,  0.413, -0.114,
       -0.300, -0.588,  0.886
    ) * U
      + mat3(
         0.168,  0.330, -0.497,
        -0.328,  0.035,  0.292,
         1.250, -1.050, -0.203
    ) * W;
    return vec4(R * c.rgb, c.a);
}

void main() {
    vec2 m = (iMouse.z > 0.5 || iMouse.w > 0.5) ? iMouse.xy / iResolution : vec2(0.5);
    vec2 uvn = (tc - m) * iResolution / min(iResolution.x, iResolution.y);
    float r = length(uvn);
    float ang = atan(uvn.y, uvn.x);
    float seg = 6.28318530718 / float(SEGMENTS);
    float swirlBase = 2.5;
    float swirlTime = time_f * 0.5;
    float swirlMouse = mix(0.0, 3.0, smoothstep(0.0, 0.6, r));
    ang += (swirlBase + swirlMouse) * sin(swirlTime + r * 4.0);
    ang = mod(ang, seg);
    ang = abs(ang - seg * 0.5);
    vec2 kUV = vec2(cos(ang), sin(ang)) * r;
    float rip = sin(r * 12.0 - pingPong(time_f, 10.0) * 10.0) * exp(-r * 4.0);
    kUV += rip * 0.01;
    vec2 scale = vec2(1.0) / (iResolution / min(iResolution.x, iResolution.y));
    vec2 st = kUV * scale + m;

    float off = 0.003 * sin(time_f * 0.5);
    vec4 c = texture(samp, st);
    c += texture(samp, st + vec2(off, 0.0));
    c += texture(samp, st + vec2(-off, off));
    c += texture(samp, st + vec2(off * 0.5, -off));
    c *= 0.25;

    float hueShift = time_f * 2.0 + rip * 2.0;
    vec4 hc = adjustHue(c, hueShift);

    vec3 rgb = hc.rgb;
    float avg = (rgb.r + rgb.g + rgb.b) / 3.0;
    rgb = mix(vec3(avg), rgb, 1.5);
    rgb *= 1.1;

    vec4 outc = vec4(rgb, 1.0);
    outc = mix(clamp(outc, 0.0, 1.0), texture(samp, tc), 0.5);
    outc = sin(outc * pingPong(time_f, 10.0) + 2.0);
    outc.a = 1.0;
    color = outc;
}
