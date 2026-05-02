#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float seed;

float h1(float n) { return fract(sin(n * 91.345 + 37.12) * 43758.5453123); }
vec2 h2(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
vec2 rot(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float a = clamp(amp, 0.0, 1.0);
    float ua = clamp(uamp, 0.0, 1.0);
    float t = time_f;

    vec2 center = vec2(0.5, 0.5);
    vec2 baseUV = tc;
    vec2 offset = baseUV - center;
    float maxRadius = length(vec2(0.5, 0.5));
    float radius = length(offset);
    float normalizedRadius = radius / maxRadius;

    float distortion = (0.25 + 0.45 * ua + 0.3 * a);
    float distortedRadius = normalizedRadius + distortion * normalizedRadius * normalizedRadius;
    distortedRadius = clamp(distortedRadius, 0.0, 1.0);
    distortedRadius *= maxRadius;
    vec2 distortedCoords = center + distortedRadius * (radius > 0.0 ? offset / radius : vec2(0.0));

    float spinSpeed = 0.6 + 1.8 * (0.3 + 0.7 * a);
    float modulatedTime = pingPong(t * spinSpeed, 5.0);
    float angle = atan(distortedCoords.y - center.y, distortedCoords.x - center.x) + modulatedTime;

    vec2 rotatedTC;
    rotatedTC.x = cos(angle) * (distortedCoords.x - center.x) - sin(angle) * (distortedCoords.y - center.y) + center.x;
    rotatedTC.y = sin(angle) * (distortedCoords.x - center.x) + cos(angle) * (distortedCoords.y - center.y) + center.y;

    float warpAmp = 0.02 + 0.06 * ua + 0.04 * a;
    vec2 warpedCoords;
    warpedCoords.x = pingPong(rotatedTC.x + t * 0.12 * (1.0 + warpAmp * 5.0), 1.0);
    warpedCoords.y = pingPong(rotatedTC.y + t * 0.12 * (1.0 + warpAmp * 5.0), 1.0);

    vec2 uv = warpedCoords;

    float speedR = 5.0, ampR = 0.03, waveR = 10.0;
    float speedG = 6.5, ampG = 0.025, waveG = 12.0;
    float speedB = 4.0, ampB = 0.035, waveB = 8.0;

    float rR = sin(uv.x * waveR + t * speedR) * ampR + sin(uv.y * waveR * 0.8 + t * speedR * 1.2) * ampR;
    float rG = sin(uv.x * waveG * 1.5 + t * speedG) * ampG + sin(uv.y * waveG * 0.3 + t * speedG * 0.7) * ampG;
    float rB = sin(uv.x * waveB * 0.5 + t * speedB) * ampB + sin(uv.y * waveB * 1.7 + t * speedB * 1.3) * ampB;

    vec2 tcR = uv + vec2(rR, rR);
    vec2 tcG = uv + vec2(rG, -0.5 * rG);
    vec2 tcB = uv + vec2(0.3 * rB, rB);

    vec3 pats[4] = vec3[](vec3(1, 0, 1), vec3(0, 1, 0), vec3(1, 0, 0), vec3(0, 0, 1));
    float pspd = 4.0;
    int pidx = int(mod(floor(t * pspd + seed * 4.0), 4.0));
    vec3 mir = pats[pidx];

    vec2 m = iMouse.z > 0.5 ? (iMouse.xy / iResolution) : fract(vec2(0.37 + 0.11 * sin(t * 0.63 + seed), 0.42 + 0.13 * cos(t * 0.57 + seed * 2.0)));
    vec2 dR = tcR - m, dG = tcG - m, dB = tcB - m;

    float fallR = smoothstep(0.55, 0.0, length(dR));
    float fallG = smoothstep(0.55, 0.0, length(dG));
    float fallB = smoothstep(0.55, 0.0, length(dB));

    float sw = (0.12 + 0.38 * ua + 0.25 * a);
    vec2 tangR = rot(normalize(dR + 1e-4), 1.5707963);
    vec2 tangG = rot(normalize(dG + 1e-4), 1.5707963);
    vec2 tangB = rot(normalize(dB + 1e-4), 1.5707963);

    vec2 airR = tangR * sw * fallR * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 40.0 + t * 3.0 + seed));
    vec2 airG = tangG * sw * fallG * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 38.0 + t * 3.3 + seed * 1.7));
    vec2 airB = tangB * sw * fallB * (0.06 + 0.22 * a) * (0.6 + 0.4 * cos(uv.y * 42.0 + t * 2.9 + seed * 0.9));

    vec2 jit = (h2(uv * vec2(233.3, 341.9) + t + seed) - 0.5) * (0.0006 + 0.004 * ua);
    tcR += airR + jit;
    tcG += airG + jit;
    tcB += airB + jit;

    vec2 fR = vec2(mir.r > 0.5 ? 1.0 - tcR.x : tcR.x, tcR.y);
    vec2 fG = vec2(mir.g > 0.5 ? 1.0 - tcG.x : tcG.x, tcG.y);
    vec2 fB = vec2(mir.b > 0.5 ? 1.0 - tcB.x : tcB.x, tcB.y);

    float ca = 0.0015 + 0.004 * a;
    vec4 C = texture(samp, uv);
    C.r = texture(samp, fR + vec2(ca, 0)).r;
    C.g = texture(samp, fG).g;
    C.b = texture(samp, fB + vec2(-ca, 0)).b;

    float pulse = 0.004 * (0.5 + 0.5 * sin(t * 3.7 + seed));
    C.rgb += pulse * ua;

    color = vec4(C.rgb, 1.0);
}
