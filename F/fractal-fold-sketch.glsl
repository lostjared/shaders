#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float time_f;
uniform float amp;  
uniform float uamp; 
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.28318530718 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

vec2 fractalFold(vec2 uv, float zoom, float t, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 4; i++) { // Increase the number of folds for more complex patterns
        p = abs((p - c) * (zoom + 0.10 * sin(t * (0.35 + amp_low * 0.2) + float(i)))) - 0.5 + c;
        if (i % 2 == 0) { // Alternate between rotation and scaling for more chaos
            p = rotateUV(p, t * 0.12 + float(i) * 0.07, c, aspect);
        } else {
            float scaleFactor = 1.0 + sin(t * 0.15 + float(i)) * 0.3; // Adding some scaling variation
            p *= scaleFactor;
        }
    }
    return p;
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = tc;
    float A = clamp(amp, 0.0, 1.0);
    float U = clamp(uamp, 0.0, 1.0);
    vec2 m = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 normPos = (uv - m) * vec2(aspect, 1.0);
    float dist = length(normPos);
    float phase = sin(dist * 8.0 - time_f * 2.0);
    float rippleStrength = 0.02 + ((0.05 + amp_rms * 0.04) * A); 
    vec2 rippledUV = uv + (normPos * phase * rippleStrength);
    float seg = 4.0 + (2.0 + amp_mid * 2.0) * sin(time_f * 0.1);
    vec2 kUV = reflectUV(rippledUV, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);
    float foldZoom = 1.05 + (0.1 + amp_low * 0.4) * sin(time_f * 0.2);
    kUV = fractalFold(kUV, foldZoom, time_f, m, aspect);
    vec2 mapUV = (kUV - m) * vec2(aspect, 1.0);
    mapUV *= 0.8; 
    float rot = time_f * 0.1;
    float s = sin(rot); 
    float c = cos(rot);
    mapUV = mat2(c, -s, s, c) * mapUV;
    float dispersion = (0.01 + amp_high * 0.02) + (U * 0.05);
    vec2 dispOffset = normalize(mapUV) * dispersion * length(mapUV);
    vec2 centerBase = mapUV + m;
    vec2 uvR = centerBase - dispOffset;
    vec2 uvG = centerBase;
    vec2 uvB = centerBase + dispOffset;
    vec2 texR = abs(mod(uvR - 1.0, 2.0) - 1.0);
    vec2 texG = abs(mod(uvG - 1.0, 2.0) - 1.0);
    vec2 texB = abs(mod(uvB - 1.0, 2.0) - 1.0);
    float r = texture(samp, texR).r;
    float g = texture(samp, texG).g;
    float b = texture(samp, texB).b;
    
    // Pencil Sketch Effect
    float lightness = (r + g + b) / 3.0;
    vec3 pencilSketchColor = vec3(lightness);
    vec3 finalCol = pencilSketchColor * 0.8; // Adjust the factor to control the intensity of the sketch effect
    

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    finalCol *= 1.0 + _ab * 0.6;
    finalCol = mix(finalCol, finalCol * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(finalCol, 1.0);
}