#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;

vec4 xor_RGB(vec4 a, vec4 b) {
    ivec3 ai;
    ivec4 bi = ivec4(clamp(b, 0.0, 1.0) * 255.0 + 0.5);
    for (int i = 0; i < 3; ++i) {
        ai[i] = int(clamp(a[i], 0.0, 1.0) * 255.0 + 0.5);
        ai[i] = ai[i] ^ bi[i];
        ai[i] = ai[i] % 256;
        a[i] = float(ai[i]) / 255.0;
    }
    a.a = 1.0;
    return a;
}

vec4 blur(sampler2D image, vec2 uv, vec2 res) {
    vec2 ts = 1.0 / res;
    float k[100];
    float v[100] = float[](
        0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5,
        1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
        1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
        2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
        2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
        2.5,3.5,4.0,4.5,5.0,5.0,4.5,4.0,3.5,2.5,
        2.0,3.0,3.5,4.0,4.5,4.5,4.0,3.5,3.0,2.0,
        1.5,2.5,3.0,3.5,4.0,4.0,3.5,3.0,2.5,1.5,
        1.0,2.0,2.5,3.0,3.5,3.5,3.0,2.5,2.0,1.0,
        0.5,1.0,1.5,2.0,2.5,2.5,2.0,1.5,1.0,0.5
    );
    for (int i = 0; i < 100; ++i) k[i] = v[i];
    float s = 0.0;
    for (int i = 0; i < 100; ++i) s += k[i];
    vec4 r = vec4(0.0);
    for (int y = -5; y <= 4; ++y) {
        for (int x = -5; x <= 4; ++x) {
            int idx = (y + 5) * 10 + (x + 5);
            r += texture(image, uv + vec2(float(x), float(y)) * ts) * k[idx];
        }
    }
    return r / s;
}

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : (len * 2.0 - m);
}

void main(void) {
    vec3 col = blur(samp, tc, iResolution).rgb;

    float t = mod(time_f, 6.0);
    float mcv = 1.0;

    if (t < 1.0) {
        col.r = mix(0.0, mcv, t);
    } else if (t < 2.0) {
        col.r = mcv;
        col.g = mix(0.0, mcv, t - 1.0);
    } else if (t < 3.0) {
        col.r = mcv;
        col.g = mcv;
        col.b = mix(0.0, mcv, t - 2.0);
    } else if (t < 4.0) {
        col = vec3(mcv);
        col.b = mix(mcv, alpha_b, t - 3.0);
    } else if (t < 5.0) {
        col = vec3(mcv, mcv, alpha_b);
        col.g = mix(mcv, alpha_g, t - 4.0);
    } else {
        col = vec3(mcv, alpha_g, alpha_b);
        col.r = mix(mcv, alpha_r, t - 5.0);
    }

    vec4 cyc = vec4(col, 1.0);
    vec4 xr = xor_RGB(blur(samp, tc, iResolution), cyc);

    float tt = pingPong(time_f, 20.0) + 2.0;
    vec3 s1 = 0.5 + 0.5 * sin(xr.rgb * tt);
    vec3 s2 = 0.5 + 0.5 * sin((xr.rgb * 6.28318) + vec3(0.0, 2.0943951, 4.1887902));

    vec3 allColors = mix(s1, s2, 0.65);
    color = vec4(clamp(allColors, 0.0, 1.0), 1.0);
}
