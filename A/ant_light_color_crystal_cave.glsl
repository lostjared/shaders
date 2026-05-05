#version 330 core
// ant_light_color_crystal_cave
// Underground crystal cavern with point light reflections and dripping color stalactites

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

vec3 crystal(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.2, 0.5)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    // Cave wall distortion
    float caveWarp = noise(uv * 3.0 + iTime * 0.1) * 0.08 * (1.0 + bass * 0.5);
    vec2 caveUV = uv + caveWarp;

    // Stalactite drip pattern (vertical streaks)
    float stalactite = noise(vec2(caveUV.x * 15.0, iTime * 0.5));
    stalactite = pow(stalactite, 3.0);
    float drip = smoothstep(0.0, 0.3, stalactite) * smoothstep(0.5, 0.0, caveUV.y + 0.3);

    // Crystal facet geometry
    vec2 cellUV = fract(caveUV * 5.0) - 0.5;
    vec2 cellID = floor(caveUV * 5.0);
    float facet = abs(cellUV.x) + abs(cellUV.y); // diamond
    float facetEdge = smoothstep(0.5, 0.45, facet);

    // Texture through cave warp
    vec2 sampUV = caveUV * 0.5 + 0.5;
    float chroma = treble * 0.03 * facetEdge;
    vec3 col;
    col.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Crystal light reflections
    float reflect = pow(1.0 - facet * 2.0, 3.0) * facetEdge;
    vec3 crystalColor = crystal(hash(cellID) + iTime * 0.1);
    col += crystalColor * reflect * (1.5 + mid * 2.0);

    // Point light from center
    float lightDist = length(uv);
    float pointLight = 1.0 / (1.0 + lightDist * (3.0 - bass * 2.0));
    col *= 0.5 + pointLight * 1.5;

    // Dripping color stalactites
    col += crystal(caveUV.x * 3.0 + iTime * 0.2) * drip * (1.0 + air * 2.0);

    // Sparkle on crystals
    float sparkle = step(0.97, hash(cellID + floor(iTime * 3.0)));
    col += crystal(iTime + hash(cellID)) * sparkle * facetEdge * treble * 4.0;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
