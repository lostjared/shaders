#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Audio Uniforms
uniform float amp_low;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

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

    // 1. Audio Mapping for Depth
    // The "base" of our log-polar math determines the tunnel's density.
    // Bass hits will now physically "stretch" the tunnel.
    float bass_kick = texture(spectrum, 0.02).r;
    float dynamic_base = 1.72 + (bass_kick * 2.0);
    float period = log(dynamic_base);

    // 2. 3D Perspective Shift
    // amp_peak pushes the "Z" depth, making the tunnel look longer on loud transients.
    vec2 p = (tc - m) * ar;
    vec3 v = vec3(p, 1.0);

    float ax = 0.25 * sin(time_f * 0.7);
    float ay = 0.25 * cos(time_f * 0.6);
    float az = 0.4 * time_f;
    mat3 R = rotZ(az) * rotY(ay) * rotX(ax);
    vec3 r = R * v;

    // Perspective "warp" increases with overall smoothness
    float persp = 0.6 + (amp_smooth * 0.5);
    float zf = 1.0 / (1.0 + r.z * persp);
    vec2 q = r.xy * zf;

    // 3. Log-Polar Wrapping
    float eps = 1e-6;
    float t = time_f * 0.5;
    float rad = length(q) + eps;
    float ang = atan(q.y, q.x) + t * 0.3;

    // k is our "Z" position in the tunnel
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang), sin(ang)) * rw;

    // 4. Kaleidoscope Segments
    // Let's make the number of mirrors fluctuate with the mids
    float sMid = texture(spectrum, 0.2).r;
    float N = 8.0 + floor(sMid * 4.0);
    float stepA = 6.28318530718 / N;
    float a = atan(qwrap.y, qwrap.x) + time_f * 0.05;
    a = mod(a, stepA);
    a = abs(a - stepA * 0.5);

    vec2 kdir = vec2(cos(a), sin(a));
    vec2 kaleido = kdir * length(qwrap);

    // 5. Final Output
    vec2 uv = fract(kaleido / ar + m);
    vec3 tex = texture(samp, uv).rgb;

    // Add a subtle color shift on bass hits
    tex += vec3(bass_kick * 0.4, 0.0, bass_kick * 0.2);

    color = vec4(tex, 1.0);
}