#version 330 core
// ant_gem_molten_web
// Spiderweb log-polar geometry with glass refraction normals and molten lava palette

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 lava(float t) {
    vec3 a = vec3(0.5, 0.2, 0.1);
    vec3 b = vec3(0.5, 0.3, 0.2);
    vec3 c = vec3(1.0, 0.8, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.2);
    return a + b * cos(TAU * (c * t + d));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.20).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.78).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    // Log-polar tunnel (from spiderweb)
    float rad = length(p) + 1e-6;
    float ang = atan(p.y, p.x);
    float base = 1.72 + bass * 1.5;
    float period = log(base);
    float t = iTime * 0.4;
    float k = fract((log(rad) - t) / period);
    float rw = exp(k * period);
    vec2 qwrap = vec2(cos(ang + t * 0.2), sin(ang + t * 0.2)) * rw;

    // Spiderweb spokes
    float N = 6.0 + floor(mid * 10.0);
    float stepA = TAU / N;
    float a = atan(qwrap.y, qwrap.x);
    a = mod(a, stepA);
    a = abs(a - stepA * 0.5);
    vec2 kaleido = vec2(cos(a), sin(a)) * length(qwrap);

    // Glass refraction normals from texture
    vec2 baseUV = fract(kaleido / vec2(aspect, 1.0) + 0.5);
    float delta = 0.008;
    float h = dot(texture(samp, baseUV).rgb, vec3(0.33));
    float h1 = dot(texture(samp, baseUV + vec2(delta, 0.0)).rgb, vec3(0.33));
    float h2 = dot(texture(samp, baseUV + vec2(0.0, delta)).rgb, vec3(0.33));
    vec2 normal = vec2(h1 - h, h2 - h);

    // Refract through the glass normals
    vec2 refractUV = baseUV + normal * (0.06 + treble * 0.08);

    // Chromatic split along refraction
    float split = (air + treble) * 0.03;
    vec3 col;
    col.r = texture(samp, refractUV + normal * split).r;
    col.g = texture(samp, refractUV).g;
    col.b = texture(samp, refractUV - normal * split).b;

    // Web filament glow
    float radial_silk = smoothstep(0.04, 0.0, abs(a - stepA * 0.25));
    float ring_silk = smoothstep(0.06, 0.0, abs(fract(log(rad) * 2.0 + bass) - 0.5));
    float web = max(radial_silk, ring_silk);

    // Lava palette on web lines
    vec3 webGlow = lava(iTime * 0.2 + rad + bass) * web * (2.0 + treble * 3.0);
    col += webGlow * mid;

    // Specular highlights on glass
    float spec = pow(max(0.0, 1.0 - length(normal * 18.0)), 8.0);
    col += vec3(1.0, 0.9, 0.7) * spec * 0.35;

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
