#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

out vec4 color;
in vec2 tc;

// Controls
const float iAmplitude = 1.0; // Controls how much "fractal" mixes in
const float iFrequency = 1.0;
const float iBrightness = 1.0;
const float iContrast = 1.0;
const float iSaturation = 1.0;
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

void main() {
    vec2 uv = tc;

    // 1. Setup Center & Zoom
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Create a centered UV system for calculations
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y; // Fix aspect for math

    // Zoom Logic
    float zoom = 1.0 + iZoom;
    p /= zoom;

    float t = time_f * (0.1 + iFrequency * 0.1);

    // 2. FRACTAL COORDINATE CALCULATION
    // Instead of folding the image immediately, we calculate a "distortion vector"
    vec2 fractalUV = p;
    float accum = 0.0;
    float iter = 3.0;

    for (float i = 0.0; i < iter; i++) {
        fractalUV = abs(fractalUV);
        fractalUV -= 0.1 * iAmplitude; // Smaller offset preserves image integrity
        fractalUV *= rot(t * 0.5 + iRotation + i);
        fractalUV *= 1.2; // Gentler scaling
        accum += length(fractalUV);
    }

    // 3. TEXTURE SAMPLING

    // Sample A: The "Anchor" (The mostly original image)
    // We apply slight rotation/zoom based on settings, but no folding.
    vec2 anchorUV = (p * rot(iRotation * 0.5)) + center;
    vec3 colBase = mxTexture(samp, anchorUV).rgb;

    // Sample B: The "Fractal" (The distorted copy)
    // We use the 'fractalUV' we calculated above
    vec2 fracSampUV = fractalUV + center;
    vec3 colFrac = mxTexture(samp, fracSampUV).rgb;

    // 4. MIXING & POP

    // Create a mask based on the fractal structure
    // High values in 'accum' mean we are deep in the fractal structure
    float mask = smoothstep(0.2, 1.0, sin(accum * 5.0 - t * 2.0));

    // Mix the Base and the Fractal
    // The base image is dominant (0.7), fractal adds detail (0.3)
    vec3 finalCol = mix(colBase, colFrac, 0.3 * iAmplitude);

    // Add the "Pop"
    // We add color to the edges of the fractal structure
    vec3 popColor = palette(accum + t);
    float edge = pow(mask, 4.0); // Sharpen the mask
    finalCol += popColor * edge * 0.5 * iContrast;

    // 5. POST PROCESS

    // Saturation
    float gray = dot(finalCol, vec3(0.299, 0.587, 0.114));
    finalCol = mix(vec3(gray), finalCol, iSaturation);

    // Brightness/Contrast
    finalCol = (finalCol - 0.5) * iContrast + 0.5;
    finalCol *= iBrightness;

    color = vec4(finalCol, 1.0);
}