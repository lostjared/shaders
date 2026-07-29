#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// --- CONTROLS ---
const float iAmplitude  = 1.0;
const float iFrequency  = 1.0;
const float iBrightness = 1.0; 
const float iContrast   = 1.1; 
const float iSaturation = 1.3;
const float iZoom       = 1.0;
const float iRotation   = 0.0;
const float PI          = 3.14159;

// --- SHADER 1: RAINBOW FUNCTION ---
vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

// --- SHADER 2: HELPER FUNCTIONS ---

vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 uv = wrapUV(tc);
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);
    return texture(tex, sampleUV);
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

// --- FLUID NOISE GENERATORS ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; i++) { 
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(2.0); 
        a *= 0.5;
    }
    return v;
}

// --- THE COMBINED LOGIC ---

vec3 sampleMergedLiquid(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    
    // Center the coordinate system for the Spiral calculation
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.1);
    p /= zoom;

    // --- FLUID SIMULATION (Domain Warping) ---
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + 0.05*t);
    q.y = fbm(p + vec2(5.2, 1.3) + 0.05*t);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0*q + vec2(t * 0.2)); 
    r.y = fbm(p + 4.0*q + vec2(t * 0.1, 2.8));

    // 'r' is the fluid vector field. We use it to distort everything.
    vec2 distortion = r * 0.3 * strength * iAmplitude;
    
    // --- INTEGRATING SHADER 1 (The Spiral) ---
    
    // We apply the fluid distortion to the coordinates used for the spiral angle.
    // This makes the spiral look like it is made of liquid.
    vec2 spiralCoords = p + distortion; 
    
    // Calculate the polar angle (atan) like in Shader 1
    // We add 't' to rotate it, and 'length' to twist it (spiral shape)
    float angle = atan(spiralCoords.y, spiralCoords.x);
    float spiralTwist = angle + length(spiralCoords) * 3.0 - t * 0.5;
    
    // Generate the Rainbow Gradient from Shader 1
    vec3 spiralColor = rainbow(spiralTwist / (2.0 * PI));
    
    // --- TEXTURE MAPPING ---
    
    // Warp the UVs for the texture lookup
    vec2 fluidUV = uv + distortion;
    vec3 texCol = mxTexture(samp, fluidUV).rgb;
    
    // --- BLENDING ---
    
    // Blend the texture with the rainbow spiral
    // We use the fluid density (length(r)) to make the blend look organic
    float blendFactor = 0.6 + 0.2 * sin(length(r) * 5.0 + t);
    
    // Hard Light blending approximation for vibrant colors
    vec3 finalCol = mix(texCol, spiralColor, 0.5); // Base mix
    
    // Add a glow overlay based on the spiral color
    finalCol += spiralColor * 0.2 * strength;

    return finalCol;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv); // Safety wrap
    
    float t = time_f * (0.2 + iFrequency * 0.1);
    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float strength = 1.0 + (ampControl * 0.5);
    
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // --- CHROMATIC ABERRATION (From Shader 2) ---
    // We split the RGB channels and offset them based on fluid intensity
    vec2 offset = vec2(0.005 * strength, 0.0);
    
    vec3 col;
    col.r = sampleMergedLiquid(uv + offset, t, strength, center, iResolution).r;
    col.g = sampleMergedLiquid(uv,          t, strength, center, iResolution).g;
    col.b = sampleMergedLiquid(uv - offset, t, strength, center, iResolution).b;

    // --- POST PROCESSING ---
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    
    // Vignette
    vec2 vUV = uv * (1.0 - uv.yx); 
    float vig = vUV.x * vUV.y * 15.0; 
    vig = pow(vig, 0.2); 
    col *= vig;
    
    color.rgb = sin(col * time_f);
			 color.a = 1.0;
}