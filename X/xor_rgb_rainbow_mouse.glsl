#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec4 blur5(sampler2D image, vec2 uv, vec2 res) {
    float k1[5] = float[](1.0, 4.0, 6.0, 4.0, 1.0);
    vec2 ts = 1.0 / res;
    vec4 s = vec4(0.0);
    float wsum = 0.0;
    for (int j = -2; j <= 2; ++j) {
        for (int i = -2; i <= 2; ++i) {
            float w = k1[i+2] * k1[j+2];
            s += texture(image, uv + vec2(float(i), float(j)) * ts) * w;
            wsum += w;
        }
    }
    return s / wsum;
}

vec2 random2(vec2 st) {
    st = vec2(dot(st, vec2(127.1, 311.7)),
              dot(st, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec2 smoothRandom2(float t) {
    float t0 = floor(t);
    float t1 = t0 + 1.0;
    vec2 r0 = random2(vec2(t0));
    vec2 r1 = random2(vec2(t1));
    float a = fract(t);
    a = a * a * (3.0 - 2.0 * a);
    return mix(r0, r1, a);
}

vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

vec4 xor_RGB(vec4 a, vec4 b) {
    uvec3 ua = uvec3(clamp(floor(a.rgb * 255.0 + 0.5), 0.0, 255.0));
    uvec3 ub = uvec3(clamp(floor(b.rgb * 255.0 + 0.5), 0.0, 255.0));
    uvec3 ux = ua ^ ub;
    return vec4(vec3(ux) / 255.0, 1.0);
}

void main(void) {
    vec2 ar = vec2(iResolution.x / iResolution.y, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    vec4 tcolor = blur5(samp, tc, iResolution);

    float tA = pingPong(time_f, 10.0) + 2.0;
    float tB = pingPong(time_f, 5.0) + 2.0;
    float tw = pingPong(time_f, 15.0) + 1.0;

    vec2 uvn = (tc - m) * ar;
    float wave = sin(uvn.x * 10.0 + tw * 2.0) * 0.1;
    vec2 rnd = smoothRandom2(tw) * 0.5;
    float expand = 0.5 + 0.5 * sin(tw * 2.0);
    vec2 suv = uvn * expand + rnd;
    float ang = atan(suv.y + wave, suv.x) + tw * 2.0;

    vec3 rb = rainbow(ang / 6.2831853);
    vec3 base = tcolor.rgb;
    vec3 mixc = mix(base, rb, 0.5);

    color = xor_RGB(sin(vec4(mixc, 1.0) * tA), tcolor * tB);
}
