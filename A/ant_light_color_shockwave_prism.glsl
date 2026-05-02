#version 330 core
// ant_light_color_shockwave_prism
// Expanding shockwave rings with prismatic separation and debris scatter

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Multiple shockwave rings expanding
    float shock = 0.0;
    for (float i = 0.0; i < 4.0; i++) {
        float ringTime = fract(iTime * 0.3 + i * 0.25);
        float ringR = ringTime * 1.5;
        float ringWidth = 0.03 + bass * 0.03;
        float ring = smoothstep(ringWidth, 0.0, abs(r - ringR));
        ring *= 1.0 - ringTime; // fade as it expands
        shock += ring;
    }

    // Prismatic separation based on shockwave
    float disp = shock * 0.05 + treble * 0.02;
    vec3 col;
    col.r = texture(samp, tc + vec2(disp, disp * 0.5)).r;
    col.g = texture(samp, tc).g;
    col.b = texture(samp, tc - vec2(disp, disp * 0.5)).b;

    // Shockwave color
    col += rainbow(r * 3.0 - iTime + bass) * shock * (1.5 + mid * 2.0);

    // Debris scatter particles
    float debrisField = 0.0;
    vec3 debrisColor = vec3(0.0);
    for (float i = 0.0; i < 10.0; i++) {
        float birthTime = floor(iTime * 2.0 + i * 0.3);
        float age = fract(iTime * 2.0 + i * 0.3);
        float debrisAngle = hash(vec2(i, birthTime)) * TAU;
        float debrisR = age * (0.5 + hash(vec2(i + 1.0, birthTime)) * 1.0);
        vec2 debrisPos = vec2(cos(debrisAngle), sin(debrisAngle)) * debrisR;

        float d = length(uv - debrisPos);
        float glow = 0.001 / (d * d + 0.0003) * (1.0 - age);
        debrisColor += rainbow(i * 0.1 + birthTime * 0.3) * glow;
    }
    col += debrisColor * (0.05 + bass * 0.15);

    // Impact flash
    float flash = exp(-r * 5.0) * pow(max(shock, 0.0), 2.0);
    col += vec3(1.0, 0.95, 0.9) * flash * (1.0 + amp_peak * 3.0);

    col *= 0.85 + amp_smooth * 0.35;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}
