#version 330 core
// mercury_plasma_helix
// Counter-rotating mercury helices refract plasma-colored FFT echoes.
#define FX_MODE 3

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_rms;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float slider1;
uniform float slider2;
uniform float slider3;
uniform float slider4;

const float TAU = 6.28318530718;
const int MODE = FX_MODE;

mat2 rotate2D(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

// Feather only near mirror turnarounds. This keeps the useful repeat behavior
// while removing the hard derivative flip that can appear as a vertical seam.
vec2 seamlessUV(vec2 uv) {
    vec2 mirrored = mirrorUV(uv);
    vec2 cosineFold = 0.5 - 0.5 * cos(3.14159265359 * uv);
    vec2 edgeDistance = min(mirrored, 1.0 - mirrored);
    vec2 feather = 1.0 - smoothstep(vec2(0.015), vec2(0.085), edgeDistance);
    return mix(mirrored, cosineFold, feather);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise21(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x),
               mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + 1.0), f.x), f.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float weight = 0.5;
    for (int i = 0; i < 4; ++i) {
        sum += noise21(p) * weight;
        p = rotate2D(0.71) * p * 2.03 + 1.37;
        weight *= 0.5;
    }
    return sum;
}

vec2 hexCell(vec2 p) {
    vec2 scale = vec2(1.0, 1.7320508);
    vec2 a = mod(p, scale) - scale * 0.5;
    vec2 b = mod(p - scale * 0.5, scale) - scale * 0.5;
    return dot(a, a) < dot(b, b) ? a : b;
}

vec2 kaleido(vec2 p, float sides) {
    float radius = length(p);
    float sector = TAU / sides;
    float angle = abs(mod(atan(p.y, p.x) + sector * 0.5, sector) - sector * 0.5);
    return vec2(cos(angle), sin(angle)) * radius;
}

vec3 palette(float x) {
    float modeHue = float(MODE) * 0.071;
    int paletteFamily = MODE % 5;
    if (paletteFamily == 0) {
        return 0.52 + 0.5 * cos(TAU * (x + modeHue + vec3(0.02, 0.34, 0.68)));
    }
    if (paletteFamily == 1) {
        return vec3(0.48, 0.22, 0.64) +
               vec3(0.52, 0.3, 0.62) *
                   cos(TAU * (x * vec3(1.0, 0.78, 1.34) + vec3(0.42, 0.18, 0.82)));
    }
    if (paletteFamily == 2) {
        return vec3(0.48, 0.34, 0.18) +
               vec3(0.52, 0.42, 0.3) *
                   cos(TAU * (x * vec3(0.82, 1.14, 1.5) + vec3(0.03, 0.13, 0.58)));
    }
    if (paletteFamily == 3) {
        return vec3(0.22, 0.48, 0.56) +
               vec3(0.28, 0.52, 0.48) *
                   cos(TAU * (x * vec3(1.25, 0.9, 1.08) + vec3(0.58, 0.08, 0.25)));
    }
    return vec3(0.5) + vec3(0.5) * cos(TAU * (x * vec3(1.0, 1.41, 1.73) + vec3(0.0, 0.21, 0.47)));
}

vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

vec4 sampleCache(int index, vec2 uv) {
    if (index == 0)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (index == 1)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (index == 2)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (index == 3)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (index == 4)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (index == 5)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (index == 6)
        return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float sampleHistory(int index, float frequency) {
    if (index == 0)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (index == 1)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (index == 2)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (index == 3)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (index == 4)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (index == 5)
        return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

float effectField(vec2 p, vec2 origin, float bass, float mid, float treble) {
    vec2 q = p - origin;
    float radius = length(q) + 0.001;
    float angle = atan(q.y, q.x);
    float t = time_f;
    float field = 0.0;

    if (MODE == 0) {
        vec2 moonA = vec2(cos(t * 0.43), sin(t * 0.61)) * 0.22;
        vec2 moonB = vec2(cos(t * 0.31 + 2.1), sin(t * 0.47 + 2.1)) * 0.31;
        field = sin(length(q - moonA) * (26.0 + bass * 16.0) - t * 6.0) * 0.13;
        field += sin(length(q - moonB) * (21.0 + mid * 14.0) - t * 4.6) * 0.12;
        field += cos(angle * 5.0 - radius * 13.0 + t * 2.0) * 0.08;
    } else if (MODE == 1) {
        vec2 grid = abs(fract((q + fbm(q * 3.0) * 0.04) * 9.0) - 0.5);
        float circuit = exp(-min(grid.x, grid.y) * (32.0 + treble * 20.0));
        field = circuit * 0.27 + sin(radius * 25.0 - t * 5.0) * 0.11;
        field += sin((q.x - q.y) * 16.0 + t * 2.0) * 0.06;
    } else if (MODE == 2) {
        vec2 cell = hexCell((q + vec2(t * 0.025, 0.0)) * 8.0);
        float plate = pow(max(1.0 - length(cell) * 1.45, 0.0), 4.0);
        field = plate * (0.22 + 0.1 * cos(atan(cell.y, cell.x) * 6.0));
        field += sin(radius * (28.0 + bass * 15.0) - t * 6.0) * 0.12;
    } else if (MODE == 3) {
        float helix = sin(angle * (4.0 + floor(treble * 5.0)) - radius * 19.0 - t * 5.0);
        float counter = cos(angle * 3.0 + radius * 14.0 - t * 3.0);
        field = helix * 0.16 + counter * 0.1 + fbm(q * 5.0 - t * 0.15) * 0.13;
    } else if (MODE == 4) {
        vec2 maze = abs(fract((rotate2D(0.25) * q) * 8.0) - 0.5);
        float walls = 1.0 - smoothstep(0.04, 0.13, min(maze.x, maze.y));
        field = walls * 0.24 + sin(radius * 23.0 - t * 5.0) * 0.11;
        field += cos(angle * 8.0 + floor(radius * 10.0) * 1.7) * 0.05;
    } else if (MODE == 5) {
        float well = sin(log(radius + 0.04) * (13.0 + bass * 5.0) - angle * 4.0 + t * 4.0);
        field = well * 0.2 + exp(-radius * 5.0) * 0.28;
        field += sin(length(q - vec2(0.2, 0.0)) * 26.0 - t * 6.0) * 0.08;
    } else if (MODE == 6) {
        float petals = cos(angle * (7.0 + floor(treble * 4.0)) - radius * 12.0);
        float bloom = pow(max(petals, 0.0), 4.0) * exp(-radius * 1.8);
        field = bloom * 0.3 + sin(radius * (25.0 + bass * 18.0) - t * 5.5) * 0.12;
    } else if (MODE == 7) {
        float meshA = sin(q.x * 19.0 + sin(q.y * 7.0 - t) * 4.0);
        float meshB = sin(q.y * 17.0 + cos(q.x * 8.0 + t) * 4.0);
        field = pow(1.0 - abs(meshA * meshB), 5.0) * 0.25;
        field += sin(radius * 30.0 - t * (7.0 + bass * 3.0)) * 0.11;
    } else if (MODE == 8) {
        vec2 h = q;
        h.x *= 1.0 + 1.5 * abs(q.y);
        float glass = sin(length(h) * 28.0 - t * 5.0);
        float waist = exp(-abs(q.x) * (8.0 + mid * 5.0)) * cos(q.y * 18.0 - t * 3.0);
        field = glass * 0.13 + waist * 0.22 + fbm(q * 4.0) * 0.08;
    } else if (MODE == 9) {
        float arches = cos(sqrt(q.x * q.x + 0.004) * 16.0 - q.y * 5.0);
        float sonar = sin(radius * (27.0 + bass * 17.0) - t * 7.0);
        field = arches * 0.16 + sonar * 0.13 + pow(max(cos(angle * 6.0), 0.0), 5.0) * 0.17;
    } else if (MODE == 10) {
        float spikes = pow(abs(sin(angle * 9.0 - radius * 21.0 + t * 2.0)), 8.0);
        field = spikes * exp(-radius * 1.4) * 0.3;
        field += sin(radius * (24.0 + bass * 20.0) - t * 6.0) * 0.12;
        field += (fbm(q * 6.0 + t * 0.08) - 0.5) * 0.15;
    } else if (MODE == 11) {
        vec2 k = kaleido(q, 8.0 + floor(treble * 5.0));
        field = sin(length(k - vec2(0.18, 0.0)) * 28.0 - t * 5.0) * 0.13;
        field += cos(atan(k.y, k.x) * 5.0 - length(k) * 18.0) * 0.17;
    } else if (MODE == 12) {
        float canopy = sin(q.x * 11.0 + sin(q.y * 8.0 + t) * 3.0);
        canopy *= cos(q.y * 13.0 - cos(q.x * 6.0 - t) * 3.0);
        field = canopy * 0.16 + sin(radius * 29.0 - t * 7.0) * 0.12;
        field += exp(-radius * 2.5) * 0.18;
    } else if (MODE == 13) {
        float shell = sin(log(radius + 0.08) * 14.0 - angle * 6.0 + t * 3.5);
        float ribs = cos(angle * 12.0 + radius * 6.0);
        field = shell * 0.18 + ribs * exp(-radius * 1.8) * 0.13;
        field += sin(radius * (22.0 + bass * 18.0) - t * 5.0) * 0.09;
    } else if (MODE == 14) {
        float ribbons = sin(q.x * 15.0 + sin(q.y * 6.0 - t * 0.8) * 5.0);
        ribbons += cos(q.y * 14.0 + sin(q.x * 7.0 + t) * 4.0);
        field = ribbons * 0.105 + sin(radius * 24.0 - t * 5.0) * 0.1;
    } else if (MODE == 15) {
        vec2 cell = hexCell(q * (7.0 + treble * 3.0));
        float geode = pow(max(1.0 - length(cell) * 1.5, 0.0), 6.0);
        float vortex = sin(angle * 5.0 - radius * 18.0 - t * 4.0);
        field = geode * 0.29 + vortex * 0.13 + sin(radius * 29.0 - t * 6.0) * 0.07;
    } else if (MODE == 16) {
        vec2 cell = hexCell((q + vec2(sin(t * 0.2), cos(t * 0.17)) * 0.03) * 10.0);
        float honey = smoothstep(0.5, 0.18, length(cell));
        field = honey * 0.25 + sin(radius * (25.0 + bass * 15.0) - t * 5.0) * 0.12;
        field += cos(atan(cell.y, cell.x) * 6.0) * honey * 0.07;
    } else if (MODE == 17) {
        float torus = sin((radius - 0.28) * (34.0 + bass * 15.0) - t * 6.0);
        float rain = sin(q.y * 27.0 + sin(q.x * 9.0 - t) * 5.0 + t * 4.0);
        field = torus * exp(-abs(radius - 0.28) * 3.0) * 0.2 + rain * 0.1;
    } else if (MODE == 18) {
        float web = sin(angle * 10.0 + sin(radius * 14.0 - t * 2.0) * 2.0);
        float rings = sin(radius * (26.0 + bass * 17.0) - t * 6.0);
        field = pow(abs(web), 5.0) * 0.22 + rings * 0.12;
        field += fbm(q * 5.0 - t * 0.1) * 0.1;
    } else if (MODE == 19) {
        float bell = exp(-abs(q.y + 0.06) * 3.0) * cos(q.x * 15.0);
        float tentacles = sin(q.y * 19.0 + sin(q.x * 11.0 + t) * 4.0 - t * 3.0);
        field = bell * 0.22 + tentacles * smoothstep(0.3, -0.4, q.y) * 0.12;
        field += sin(radius * 23.0 - t * 5.0) * 0.08;
    } else if (MODE == 20) {
        float fault = tanh(sin(q.x * 8.0 + fbm(q * 4.0) * 5.0 + t) * 4.0);
        float aurora = sin(q.y * 15.0 + sin(q.x * 5.0 - t) * 4.0);
        field = fault * 0.13 + aurora * 0.13 + sin(radius * 27.0 - t * 6.0) * 0.08;
    } else if (MODE == 21) {
        float forge = sin(q.x * 17.0 + cos(q.y * 8.0 + t) * 5.0);
        float cross = cos(q.y * 19.0 + sin(q.x * 6.0 - t) * 3.0);
        field = abs(forge + cross) * 0.12 + sin(radius * 25.0 - t * 5.5) * 0.11;
    } else if (MODE == 22) {
        float lotus = pow(max(cos(angle * 9.0 - radius * 13.0 + t * 2.0), 0.0), 5.0);
        float ripple = sin(radius * (28.0 + bass * 18.0) - t * 7.0);
        field = lotus * exp(-radius * 1.7) * 0.31 + ripple * 0.12;
    } else if (MODE == 23) {
        float handA = exp(-abs(sin(angle - t * 0.4)) * radius * 24.0);
        float handB = exp(-abs(sin(angle + t * 0.23)) * radius * 32.0);
        float clock = sin(radius * 32.0 - floor(t * 3.0) * 0.7);
        field = (handA + handB) * 0.18 + clock * 0.12;
    } else {
        float nova = sin(radius * (35.0 + bass * 20.0) - t * 9.0);
        float rays = pow(abs(cos(angle * (10.0 + floor(treble * 6.0)) + t)), 10.0);
        float cathedral = cos(sqrt(q.x * q.x + 0.003) * 15.0 - q.y * 5.0);
        field = nova * 0.13 + rays * exp(-radius * 2.2) * 0.26 + cathedral * 0.1;
    }

    vec2 sourceA = vec2(sin(t * 0.3), cos(t * 0.4)) * vec2(0.2, 0.15);
    vec2 sourceB = vec2(-sin(t * 0.5), sin(t * 0.3)) * vec2(0.15, 0.2);
    vec2 sourceC = vec2(cos(t * 0.2), -cos(t * 0.6)) * 0.1;
    float density = mix(0.7, 1.55, max(slider2, 0.1));
    float rippleA = sin(length(q - sourceA) * (20.0 + bass * 15.0) * density - t * 5.0);
    float rippleB = sin(length(q - sourceB) * (18.0 + mid * 12.0) * density - t * 4.0);
    float rippleC = sin(length(q - sourceC) * (22.0 + treble * 10.0) * density - t * 6.0);
    float interference = (rippleA + rippleB + rippleC) / 3.0;

    float arms = 3.0 + floor(treble * 4.0 + max(slider1, 0.1) * 5.0);
    float twist = 15.0 - bass * 8.0;
    float spiralPhase = angle * arms - radius * twist - t * (4.0 + amp_smooth * 8.0);
    float spiral = pow(max(sin(spiralPhase), 0.0), 4.0) * exp(-radius * (2.0 - mid));

    return field + interference * 0.12 + spiral * 0.22 +
           (fbm(q * 3.2 + vec2(0.0, -t * 0.12)) - 0.5) * 0.06;
}

vec2 feedbackTransform(vec2 uv, vec2 center, float generation, float bass, float mid, float treble,
                       vec2 normalFlow) {
    vec2 q = uv - center;
    int family = MODE % 5;
    float zoom = pow(max(0.975 - bass * 0.085, 0.25), generation);
    float angle = (0.018 + treble * 0.105) * generation;

    if (family == 0) {
        q = rotate2D(angle) * q * zoom;
        q += normalFlow * generation * (0.008 + mid * 0.012);
    } else if (family == 1) {
        q = kaleido(rotate2D(angle * 0.55) * q, 5.0 + float(MODE % 7)) * zoom;
    } else if (family == 2) {
        q.x += sin(q.y * 14.0 + generation + time_f) * (0.006 + mid * 0.015) * generation;
        q.y += cos(q.x * 12.0 - generation + time_f) * (0.005 + treble * 0.01) * generation;
        q *= zoom;
    } else if (family == 3) {
        q = rotate2D(-angle) * q;
        q.x *= 1.0 + generation * (0.012 + mid * 0.018);
        q.y *= zoom;
    } else {
        float radius = length(q);
        q = rotate2D(angle + sin(radius * 16.0 - time_f) * 0.035 * generation) * q * zoom;
        q += normalize(q + vec2(0.001)) * bass * 0.012 * generation;
    }

    // Return an unfolded coordinate. Folding again after manual zoom caused
    // double-reflection creases in several of the original variants.
    return q + center;
}

float modeOverlay(vec2 p, float height, float audio) {
    float radius = length(p);
    float angle = atan(p.y, p.x);
    int family = MODE % 5;
    if (family == 0)
        return pow(max(sin(radius * 34.0 - time_f * 8.0), 0.0), 10.0);
    if (family == 1)
        return pow(max(cos(angle * (6.0 + float(MODE % 8)) - radius * 17.0), 0.0), 7.0);
    if (family == 2)
        return pow(1.0 - abs(sin((p.x + p.y) * 22.0 + time_f * 3.0)), 9.0);
    if (family == 3)
        return pow(max(sin(height * 31.0 + angle * 3.0 - time_f * 4.0), 0.0), 8.0);
    return pow(max(cos(log(radius + 0.04) * 15.0 - angle * 5.0 + time_f * 3.0), 0.0), 9.0) *
           (0.45 + audio);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 mouseUV = iMouse.xy / resolution;

    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;
    float audioGate = clamp(amp_rms + amp_peak + amp_low + amp_mid + amp_high, 0.0, 1.0);

    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 origin = iMouse.z > 0.0 ? (mouseUV - 0.5) * vec2(aspect, 1.0) : vec2(0.0);
    float pixel = 2.0 / max(max(resolution.x, resolution.y), 360.0);
    float radius = length(p - origin);
    float historyShell = clamp(radius * 7.0, 0.0, 7.0);
    int shellIndex = int(historyShell);
    float shellFFT = sampleHistory(min(shellIndex, 6), clamp(radius * 0.65, 0.0, 1.0));

    float height = effectField(p, origin, bass, mid, treble);
    vec2 gradient = vec2(effectField(p + vec2(pixel, 0.0), origin, bass, mid, treble) - height,
                         effectField(p + vec2(0.0, pixel), origin, bass, mid, treble) - height) /
                    pixel;
    vec3 normal = normalize(vec3(-gradient * (0.21 + amp_high * 0.06), 1.0));

    float waveDrive = sin(height * (18.0 + max(slider2, 0.1) * 22.0) -
                          time_f * (3.0 + audioGate * 5.0) + shellFFT * 8.0);
    vec2 radial = normalize(p - origin + vec2(0.001));
    vec2 liveDistortion = normal.xy * (0.027 + amp_low * 0.05) +
                          radial * waveDrive * (0.008 + shellFFT * 0.025 * max(slider4, 0.1));
    vec2 flowUV = seamlessUV(tc + liveDistortion);
    float dispersion =
        (0.005 + treble * 0.019 + abs(waveDrive) * 0.008) * mix(0.2, 2.4, max(slider3, 0.1));
    vec3 live =
        vec3(texture(samp, seamlessUV(flowUV + normal.xy * dispersion)).r, texture(samp, flowUV).g,
             texture(samp, seamlessUV(flowUV - normal.xy * dispersion)).b);

    vec3 viewDir = normalize(vec3(-p * 0.12, 1.8));
    vec3 lightA = normalize(vec3(-0.55, 0.7, 0.82));
    vec3 lightB = normalize(vec3(0.72, -0.18, 0.68));
    float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 5.0);
    float roughnessProfile = float(MODE % 7) / 6.0;
    float specA =
        pow(max(dot(normal, normalize(viewDir + lightA)), 0.0), mix(145.0, 34.0, roughnessProfile));
    float specB =
        pow(max(dot(normal, normalize(viewDir + lightB)), 0.0), mix(82.0, 20.0, roughnessProfile));
    float luminance = dot(live, vec3(0.299, 0.587, 0.114));

    float mouseIntensity = length(mouseUV - vec2(0.5)) * 2.0;
    float timeHue = iMouse.z > 0.0 ? mouseIntensity * time_f * 0.32 : 0.0;
    float manualHue = iMouse.w > 0.0 ? (mouseUV.x - 0.5) * 2.4 : 0.0;
    vec3 acidMetal = palette(height * 1.8 + bass + time_f * 0.055 + timeHue + manualHue);
    float modeIntensity = 1.15 + 0.25 * sin(float(MODE) * 2.17);
    float alloyMix = 0.38 + 0.1 * float(MODE % 4);
    vec3 current = mix(live, acidMetal * (0.3 + luminance), alloyMix) * modeIntensity;
    current *= 0.14 + 0.62 * max(dot(normal, lightA), 0.0);
    current += palette(normal.x * 0.23 - normal.y * 0.17 + time_f * 0.035) *
               (fresnel * 0.75 + specA * 2.3 + specB * 1.4);

    vec3 accumulated = current;
    float totalWeight = 1.0;
    vec2 feedbackCenter =
        iMouse.z > 0.0 ? mouseUV + liveDistortion * 0.15 : vec2(0.5) + liveDistortion * 1.5;
    float manualZoom = iMouse.w > 0.0 ? (0.5 - mouseUV.y) * 0.16 : 0.0;
    vec3 userHue = vec3(sin(timeHue), cos(timeHue * 0.8), sin(timeHue * 1.2));

    for (int i = 0; i < 8; ++i) {
        float generation = float(i + 1);
        float oldBass = sampleHistory(i, 0.03);
        float oldMid = sampleHistory(i, 0.22);
        float oldTreble = sampleHistory(i, 0.58);
        vec2 historyUV = feedbackTransform(tc, feedbackCenter, generation, oldBass, oldMid,
                                           oldTreble, normal.xy);
        historyUV =
            feedbackCenter + (historyUV - feedbackCenter) *
                                 pow(max(1.0 + manualZoom - oldBass * 0.03, 0.05), generation);
        vec3 history = sampleCache(i, seamlessUV(historyUV)).rgb;
        float driftDirection = (MODE % 2 == 0) ? 1.0 : -1.0;
        float shift = generation * (0.045 + 0.012 * float(MODE % 4));
        history.r *= 1.0 + driftDirection * shift + oldMid * 0.32 + userHue.r * generation * 0.1;
        history.g *=
            1.0 - driftDirection * shift * 0.78 - oldBass * 0.18 + userHue.g * generation * 0.1;
        history.b *=
            1.0 + driftDirection * shift * 0.5 + oldTreble * 0.38 + userHue.b * generation * 0.1;
        history *= palette(height * 0.13 + generation * 0.052 + manualHue);
        float historyDecay = 0.7 + 0.025 * float(MODE % 5);
        float weight = pow(historyDecay, generation);
        accumulated += history * weight;
        totalWeight += weight;
    }

    accumulated /= totalWeight;
    float crest = pow(max(sin(height * 24.0 - time_f * 2.5), 0.0), 8.0);
    accumulated += palette(height + time_f * 0.11 + timeHue) * crest * (0.55 + air * 2.0);
    float vividRing = smoothstep(0.1, 0.95, waveDrive) * (0.2 + shellFFT + audioGate);
    vec3 ringColor = palette(radius * 2.0 + historyShell * 0.08 + shellFFT * 0.4 + manualHue);
    accumulated = 1.0 - (1.0 - accumulated) * (1.0 - clamp(ringColor * vividRing, 0.0, 1.0));
    accumulated += ringColor * vividRing * 0.55;
    float signature = modeOverlay(p - origin, height, audioGate);
    vec3 signatureColor =
        palette(height * 0.7 + radius * 0.35 - time_f * 0.08 + float(MODE) * 0.031);
    accumulated += signatureColor * signature * (0.28 + amp_high * 0.75 + float(MODE % 3) * 0.12);
    if (MODE % 3 == 1)
        accumulated = mix(accumulated, accumulated.brg, signature * 0.22);
    if (MODE % 3 == 2)
        accumulated = mix(accumulated, accumulated.gbr, signature * 0.2);
    accumulated = mix(accumulated, vec3(1.0) - accumulated, smoothstep(0.91, 1.0, amp_peak));
    accumulated = (accumulated - 0.5) * (1.22 + amp_smooth * 0.3) + 0.5;

    color = vec4(aces(max(accumulated, 0.0)), texture(samp, flowUV).a);
}
