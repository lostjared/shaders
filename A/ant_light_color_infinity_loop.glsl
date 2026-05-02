#version 330 core
// ant_light_color_infinity_loop
// Lemniscate infinity with flowing light along path and spectrum-driven twist

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Lemniscate of Bernoulli: (x^2+y^2)^2 = a^2(x^2-y^2)
    float a = 0.35 + bass * 0.1;

    // Distance to lemniscate (approximate via parametric)
    float minDist = 10.0;
    float closestT = 0.0;
    for (float i = 0.0; i < 60.0; i++) {
        float t = i / 60.0 * TAU;
        float ct = cos(t);
        float st = sin(t);
        float r2 = a * a * cos(2.0 * t);
        if (r2 > 0.0) {
            float r = sqrt(r2);
            vec2 lp = vec2(r * ct, r * st);
            float d = length(p - lp);
            if (d < minDist) {
                minDist = d;
                closestT = t;
            }
        }
    }

    // Tube glow around curve
    float tube = 0.005 / (minDist * minDist + 0.001);
    tube = min(tube, 5.0);

    // Flowing light along path
    float flow = sin(closestT * 3.0 - iTime * 5.0) * 0.5 + 0.5;
    flow = pow(flow, 3.0);

    // Texture sample
    vec2 sampUV = tc + p * minDist * 0.02;
    float chroma = treble * 0.03 + tube * 0.005;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Rainbow tube glow
    col += rainbow(closestT / TAU + iTime * 0.15) * tube * (0.2 + mid * 0.3);

    // Flowing bright spots
    col += rainbow(closestT / TAU - iTime * 0.3) * tube * flow * (1.0 + air * 2.0);

    // Center crossing glow
    float center = exp(-length(p) * (5.0 - bass * 3.0));
    col += rainbow(iTime * 0.25) * center * (1.5 + amp_peak * 3.0);

    // Outer symmetry glow
    float symGlow = exp(-abs(p.y) * 10.0) * exp(-abs(abs(p.x) - a * 0.5) * 5.0);
    col += rainbow(p.x + iTime * 0.2) * symGlow * bass * 0.3;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
