#version 330 core
// ant_light_color_single_spiral
// Large continuous spiral with flowing light and exact distance math

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
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);

    float r = length(p);
    float angle = atan(p.y, p.x);

    // Archimedean Spiral parameters
    // 'spacing' controls how tight the spiral arms are wound
    float spacing = 0.08 + bass * 0.02;

    // O(1) Mathematical exact distance replacing the 60-iteration loop.
    // We calculate exactly which wrap of the spiral we are closest to.
    float n = round((r / spacing) - (angle / TAU));
    float closestT = angle + n * TAU;

    // Prevent the spiral from winding backward into the center infinitely
    closestT = max(closestT, 0.0);

    // The radius of the spiral at this exact angle
    float targetR = spacing * (closestT / TAU);

    // Distance to the curve (radial approximation is very clean for spirals)
    float minDist = abs(r - targetR);

    // Tube glow around curve
    float tube = 0.005 / (minDist * minDist + 0.001);
    tube = min(tube, 5.0);

    // Flowing light along path
    float flow = sin(closestT * 3.0 - iTime * 5.0) * 0.5 + 0.5;
    flow = pow(flow, 3.0);

    // Texture sample - keeping your original warp logic
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

    // Center origin glow
    float center = exp(-r * (8.0 - bass * 3.0));
    col += rainbow(iTime * 0.25) * center * (1.5 + amp_peak * 3.0);

    // Outer vignette to smoothly fade the spiral before it hits the screen edge
    float vignette = smoothstep(1.2, 0.4, r);
    col *= vignette;

    col *= 0.85 + amp_smooth * 0.3;
    col = mix(col, vec3(1.0) - col, smoothstep(0.92, 1.0, amp_peak));

    color = vec4(col, 1.0);
}