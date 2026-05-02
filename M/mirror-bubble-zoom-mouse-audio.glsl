#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Audio Uniforms
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

mat3 rotX(float a) {
    float s = sin(a), c = cos(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}
mat3 rotY(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}
mat3 rotZ(float a) {
    float s = sin(a), c = cos(a);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // AUDIO: Peak hits cause a screen-shake displacement
    float shake = amp_peak * amp_peak * 0.02;
    vec2 shakeOff = shake * vec2(sin(time_f * 73.1), cos(time_f * 97.3));

    vec2 cv = 1.0 - abs(1.0 - 2.0 * (tc + shakeOff));
    cv = cv - floor(cv);

    // AUDIO: Bass pulses the zoom — image breathes with the kick
    float bassZoom = 1.0 + amp_low * 0.4 + amp_peak * 0.25;
    vec2 p = ((cv - m) * ar) / bassZoom;
    vec3 v = vec3(p, 1.0);

    // AUDIO: Mids push harder X/Y wobble, highs add jitter, smooth spins Z
    float ax = 0.35 * sin(time_f * 0.7) + amp_mid * 1.2 + amp_high * 0.3 * sin(time_f * 11.0);
    float ay = 0.35 * cos(time_f * 0.6) + amp_mid * 1.2 + amp_high * 0.3 * cos(time_f * 13.0);
    float az = 0.4 * time_f + amp_smooth * 3.0 + amp_low * 1.0;

    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = R * v;

    // AUDIO: Bass + peak slam the perspective tunnel effect
    float persp = 0.6 + amp_low * 1.5 + amp_peak * 1.2;
    float zf = 1.0 / (1.0 + r.z * persp);
    vec2 q = r.xy * zf;

    float eps = 1e-6;
    // AUDIO: Base of the log spiral shifts with mids — warps the repeating structure
    float base = 1.72 + amp_mid * 0.6;
    float period = log(base);

    // AUDIO: Smooth + RMS accelerate the logarithmic spiral aggressively
    float t = time_f * 0.5 + amp_smooth * 4.0 + amp_rms * 2.0;
    float rad = length(q) + eps;
    // AUDIO: Highs ripple the angular component
    float ang = atan(q.y, q.x) + t * 0.3 + amp_high * sin(rad * 12.0 - time_f * 3.0) * 0.8;
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang), sin(ang)) * rw;

    // AUDIO: Bass doubles kaleidoscope segments, peak adds extra fragmentation
    float N = 8.0 + amp_low * 16.0 + amp_peak * 8.0;
    float stepA = 6.28318530718 / N;
    float a = atan(qwrap.y, qwrap.x) + time_f * 0.05;
    a = mod(a, stepA);
    a = abs(a - stepA * 0.5);
    vec2 kdir = vec2(cos(a), sin(a));
    // AUDIO: Mids warp the kaleidoscope radius
    float krad = length(qwrap) * (1.0 + amp_mid * 0.5);
    vec2 kaleido = kdir * krad;

    vec2 uv = kaleido / ar + m;

    // AUDIO: Treble + peak drive heavy chromatic aberration, bass adds slow drift
    vec2 dir = normalize((uv - m) + eps);
    float split = amp_high * 0.12 + amp_peak * 0.08 + amp_rms * 0.04 + amp_low * 0.02;

    // AUDIO: Each channel gets a slightly different angular offset for swirl-split
    float angOff = amp_mid * 0.3;
    vec2 dirR = vec2(cos(angOff) * dir.x - sin(angOff) * dir.y, sin(angOff) * dir.x + cos(angOff) * dir.y);
    vec2 dirB = vec2(cos(-angOff) * dir.x - sin(-angOff) * dir.y, sin(-angOff) * dir.x + cos(-angOff) * dir.y);

    vec2 uvR = fract(uv + dirR * split);
    vec2 uvG = fract(uv);
    vec2 uvB = fract(uv - dirB * split);

    float rCol = texture(samp, uvR).r;
    float gCol = texture(samp, uvG).g;
    float bCol = texture(samp, uvB).b;
    vec3 finalCol = vec3(rCol, gCol, bCol);

    // AUDIO: Hue rotation driven by smooth energy — colors shift over time with music
    float hueShift = amp_smooth * 1.5 + amp_mid * 0.8;
    float cosH = cos(hueShift), sinH = sin(hueShift);
    mat3 hueRot = mat3(
        0.577 + 0.816 * cosH + 0.057 * sinH, 0.577 - 0.577 * cosH - 0.577 * sinH, 0.577 - 0.240 * cosH + 0.520 * sinH,
        0.577 - 0.240 * cosH + 0.520 * sinH, 0.577 + 0.816 * cosH + 0.057 * sinH, 0.577 - 0.577 * cosH - 0.577 * sinH,
        0.577 - 0.577 * cosH - 0.577 * sinH, 0.577 - 0.240 * cosH + 0.520 * sinH, 0.577 + 0.816 * cosH + 0.057 * sinH);
    finalCol = clamp(hueRot * finalCol, 0.0, 1.0);

    // AUDIO: Boost saturation with overall energy
    float grey = dot(finalCol, vec3(0.299, 0.587, 0.114));
    float satBoost = 1.0 + amp_rms * 1.2 + amp_peak * 0.5;
    finalCol = mix(vec3(grey), finalCol, satBoost);

    // AUDIO: Peak + bass brightness pulse with contrast punch
    float bright = 1.0 + amp_peak * 1.0 + amp_low * 0.4;
    finalCol = pow(finalCol * bright, vec3(1.0 + amp_peak * 0.3));

    // AUDIO: Bass-reactive vignette — edges darken on hits
    float vignette = 1.0 - length((tc - 0.5) * 1.4) * (0.3 + amp_low * 0.7);
    finalCol *= clamp(vignette, 0.0, 1.0);

    color = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}