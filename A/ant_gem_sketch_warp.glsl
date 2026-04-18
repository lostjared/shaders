#version 330 core
// ant_gem_sketch_warp
// Pencil-sketch style normal-warping with kaleidoscope and neon edge detection

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;

    // Bass wave warp (from pencil_sketch)
    float wave = sin(uv.y * 8.0 + iTime * 2.0) * bass * 0.1;
    uv.x += wave;

    // Mid vortex swirl
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    float swirl = mid * PI * exp(-dist * 2.0);
    centered = rot(swirl) * centered;
    uv = centered + 0.5;

    // Kaleidoscope over the warped image
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float segments = 6.0 + floor(hiMid * 8.0);
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float step_val = 2.0 * PI / segments;
    angle = mod(angle, step_val);
    angle = abs(angle - step_val * 0.5);
    p = vec2(cos(angle), sin(angle)) * radius;
    p.x /= aspect;
    vec2 kaleUV = p + 0.5;

    // Edge detection via luminance gradient (sketch style)
    float delta = 0.003;
    float lum  = dot(texture(samp, kaleUV).rgb, vec3(0.299, 0.587, 0.114));
    float lumR = dot(texture(samp, kaleUV + vec2(delta, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float lumU = dot(texture(samp, kaleUV + vec2(0.0, delta)).rgb, vec3(0.299, 0.587, 0.114));
    float edge = length(vec2(lumR - lum, lumU - lum)) * 40.0;

    // Chromatic aberration driven by air
    float chroma = (air + treble) * 0.04;
    vec3 col;
    col.r = texture(samp, kaleUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, kaleUV).g;
    col.b = texture(samp, kaleUV - vec2(chroma, 0.0)).b;

    // Neon edge overlay: edges glow with spectrum-reactive colors
    vec3 edgeColor = 0.5 + 0.5 * cos(6.28318 * (edge * 0.5 + iTime * 0.2 + bass + vec3(0.0, 0.33, 0.67)));
    col = mix(col, edgeColor, clamp(edge * (0.3 + treble * 0.5), 0.0, 0.7));

    // Treble high-freq jitter
    if (treble > 0.35) {
        float noise = fract(sin(dot(kaleUV.yx, vec2(12.9898, 78.233))) * 43758.5453);
        col.r += noise * treble * 0.06;
        col.b -= noise * treble * 0.04;
    }

    // Brightness and contrast
    col *= 0.8 + amp_peak * 1.2;
    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.93, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
