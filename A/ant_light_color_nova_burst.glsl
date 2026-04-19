#version 330 core
// ant_light_color_nova_burst
// Exploding nova rings with prismatic color separation and bass-driven shockwaves

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

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Bass shockwave rings expanding outward
    float shockwave = sin(r * 30.0 - iTime * 8.0 - bass * 15.0) * 0.5 + 0.5;
    shockwave = pow(shockwave, 4.0 + treble * 8.0);

    // Nova explosion: radial burst with chromatic split
    float burst = exp(-r * (2.0 - bass * 1.5));
    vec2 burstUV = uv * (1.0 + burst * bass * 0.5);
    
    // FIX: Rotate/swirl the space based on 'r' (radius) rather than 'angle'.
    // This creates a continuous, unbroken vortex twist. 
    // I swapped `angle * 0.1` for `r * 1.5` to maintain a cool spatial distortion.
    burstUV = rot(r * 1.5 + iTime * 0.3 + mid) * burstUV;

    vec2 sampUV = burstUV * 0.5 + 0.5;
    float chroma = (treble + air) * 0.05 + shockwave * 0.02;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, chroma * 0.5)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, chroma * 0.5)).b;

    // Prismatic ring overlay
    vec3 ringColor = rainbow(r * 3.0 - iTime * 0.5 + bass);
    col += ringColor * shockwave * (0.5 + mid * 0.8);

    // Core glow
    col += rainbow(iTime * 0.2) * burst * (1.5 + amp_peak * 3.0);

    // Radial light spokes (This was mathematically safe because of the floor() function!)
    float spokes = abs(sin(angle * (6.0 + floor(treble * 6.0)) + iTime));
    spokes = pow(spokes, 8.0) * burst;
    col += rainbow(angle / TAU + iTime * 0.3) * spokes * (1.0 + air * 2.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}