#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// Simple hash for pseudo-random crack generation
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Voronoi for crack-like cells
float voronoi(vec2 uv) {
    vec2 g = floor(uv);
    vec2 f = fract(uv);
    float res = 8.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 lattice = vec2(x, y);
            vec2 p = hash(g + lattice) * vec2(0.5 + 0.5 * sin(time_f * 0.2));
            vec2 diff = lattice + p - f;
            float d = length(diff);
            res = min(res, d);
        }
    }
    return res;
}

void main(void) {
    vec2 uv = tc * iResolution.xy / min(iResolution.x, iResolution.y);

    // Crack mask that spreads with time
    float cracks = smoothstep(0.05, 0.15, voronoi(uv * (2.0 + 0.5 * sin(time_f * 0.1))));

    // Distortion based on crack intensity
    vec2 offset = vec2(cos(uv.y * 20.0 + time_f * 0.5), sin(uv.x * 20.0 - time_f * 0.5)) * (1.0 - cracks) * 0.02;

    // Sample texture with refracted coords
    vec4 texCol = texture(samp, tc + offset);

    // Blend cracks as dark fracture lines
    vec3 crackColor = mix(vec3(0.0), texCol.rgb, cracks);

    color = vec4(crackColor, 1.0);
}
