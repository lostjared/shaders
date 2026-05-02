#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

out vec4 color;
in vec2 tc;

// Controls
const float iAmplitude = 1.0;
const float iFrequency = 1.0;
const float iBrightness = 1.0;
const float iContrast = 1.2; // Bumped default contrast for "Pop"
const float iSaturation = 1.2;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;

// --- Helper Functions ---

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 uv = wrapUV(tc);
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);
    return textureLod(tex, sampleUV, 0.0);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// --- Fractal Logic ---

vec3 fractalLayer(vec2 uv, vec2 center, float t) {
    vec3 finalCol = vec3(0.0);
    vec2 p = uv - center;

    // Correct aspect ratio for calculations
    p.x *= iResolution.x / iResolution.y;

    // Initial Zoom base
    float zoomFactor = 0.5 + (iZoom * 2.0);
    p /= zoomFactor;

    // Accumulators for the fractal visual
    float d = 100.0;
    vec3 accTexture = vec3(0.0);
    float accLight = 0.0;

    // FRACTAL LOOP
    // We iterate space to create self-similarity
    float iter = 4.0;
    float scale = 1.5 + (iAmplitude * 0.5);

    for (float i = 0.0; i < iter; i++) {
        // 1. Space Folding (The Kaleidoscope effect)
        p = abs(p);
        p -= 0.25 * iAmplitude; // Offset to create gaps in the geometry

        // 2. Rotation (Adds the swirl)
        p *= rot(t * 0.2 + iRotation + i);

        // 3. Scaling (The Fractal Zoom)
        p *= scale;

        // 4. Texture Sampling
        // We sample the texture at this distorted coordinate
        // We add it to our accumulator
        vec2 texUV = p * 0.5 + 0.5; // Map back to 0-1 range

        // Create a wobble for the texture read so it feels organic
        texUV += vec2(sin(t + i), cos(t + i)) * 0.05;

        vec3 tex = mxTexture(samp, texUV).rgb;

        // Weight earlier iterations higher for structure, later for detail
        float weight = 1.0 / (i + 1.0);
        accTexture += tex * weight;

        // 5. Lighting / "Pop" Calculation
        // Calculate distance to origin to create glowing rings/edges
        float dist = length(p);
        d = min(d, dist);
        accLight += exp(-10.0 * abs(dist - 0.5)); // Glowing ring formula
    }

    // Average the texture accumulation
    accTexture /= 1.5; // Normalize brightness

    // Color Palette based on the fractal depth (d) and time
    vec3 pal = palette(length(p) * 0.1 + d + t * 0.2);

    // COMPOSITION
    // Mix the warped texture with the procedural palette
    finalCol = mix(accTexture, pal, 0.4 * iSaturation);

    // Add the glowing "Pop" light
    finalCol += pal * accLight * 0.5 * iContrast;

    // Deep crunch contrast
    finalCol = pow(finalCol, vec3(1.1));

    return finalCol;
}

void main() {
    vec2 uv = tc;

    // Center logic
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    float t = time_f * (0.1 + iFrequency * 0.2);

    // Render
    vec3 col = fractalLayer(uv, center, t);

    // Global Adjustments
    // Saturation
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, iSaturation);

    // Brightness/Contrast
    col = (col - 0.5) * iContrast + 0.5;
    col *= iBrightness;

    // Slight Vignette
    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.15);
    col *= vig;

    color = vec4(col, 1.0);
}