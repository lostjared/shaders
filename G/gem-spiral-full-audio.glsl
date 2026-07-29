#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float alpha;
uniform float amp_peak; // peak absolute sample value in current audio buffer
uniform float amp_rms; // RMS energy of current audio buffer
uniform float amp_smooth; // exponentially smoothed amplitude for gradual transitions
uniform float amp_low; // bass energy (below ~300 Hz)
uniform float amp_mid; // mid-range energy (~300-3000 Hz)
uniform float amp_high; // treble energy (above ~3000 Hz)
uniform float iamp; // estimated dominant frequency in Hz via zero-crossing rate

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    // 1. Correct Aspect Ratio & Centering
    vec2 uv = (tc * 2.0 - 1.0);
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    // AUDIO: Bass pulses zoom the entire field in dramatically
    float zoom = 1.0 - amp_low * 0.65;
    uv *= zoom;

    // 2. Full-Screen Spherical/Fisheye Logic
    float d = length(uv);

    // AUDIO: Bass warps the lens strength causing extreme bulging on beats
    float lensStrength = 1.5 + amp_low * 4.0;
    float z = sqrt(lensStrength * lensStrength + d * d);

    // Create normals for shading (lighting) across the whole screen
    vec3 normal = normalize(vec3(uv, 1.0 / lensStrength));

    // Distort UVs for the spiral
    float fisheyeRadius = atan(d, 1.0);
    vec2 distortedUV = normalize(uv + 1e-6) * fisheyeRadius;

    // 3. Spiral Logic
    // AUDIO: Mids drive animation speed very aggressively
    float t = time_f * (0.8 + amp_mid * 7.0);
    // AUDIO: RMS speeds up the ping-pong oscillation
    float pTime = pingPong(time_f * (0.5 + amp_rms * 5.0), 2.0);

    float r_dist = length(distortedUV);
    float angle = atan(distortedUV.y, distortedUV.x);

    // AUDIO: Bass + peak cause dramatic spiral tightening on every beat/transient
    float spiralTightness = (2.0 + pTime) + amp_low * 10.0 + amp_peak * 6.0;
    float spiral = angle + (log(r_dist + 0.1) * spiralTightness) - t * 1.5;

    // AUDIO: Treble cranks the color cycling frequency - high hats = rapid color flash
    float colFreq = 3.0 + amp_high * 14.0;
    float r = sin(spiral * colFreq + t);
    float g = sin(spiral * colFreq + t + 2.094);
    float b = sin(spiral * colFreq + t + 4.188);

    vec3 spiralCol = vec3(r, g, b) * 0.5 + 0.5;

    // AUDIO: Smooth amplitude greatly brightens the spiral between beats
    spiralCol *= 1.0 + amp_smooth * 5.0;

    // 4. Shading & Lighting
    // AUDIO: Mids spin the light source fast
    float lightAngle = time_f + amp_mid * 12.0;
    vec3 lightDir = normalize(vec3(sin(lightAngle), cos(lightAngle), 1.0));
    float diff = max(dot(normal, lightDir), 0.0);
    // AUDIO: Peak causes huge specular flares on transients
    float specExp = max(1.0, 16.0 - amp_peak * 15.0);
    float spec = pow(max(dot(reflect(-lightDir, normal), vec3(0,0,1)), 0.0), specExp);
    spec *= 1.0 + amp_peak * 10.0;

    // 5. Final Mix
    vec3 texColor = texture(samp, tc).rgb;

    // AUDIO: RMS pushes the blend toward pure spiral on loud passages
    float mixFactor = clamp(0.7 + amp_rms * 0.29, 0.0, 1.0);
    vec3 finalCol = mix(texColor, spiralCol * (diff + 0.5) + spec, mixFactor);

    // AUDIO: Peak flashes the vignette open so the whole screen blooms on beat
    finalCol *= smoothstep(2.0, 0.5, d * (1.0 - amp_peak * 0.75));

    // AUDIO: Smooth energy adds a persistent additive glow across the frame
    finalCol += spiralCol * amp_smooth * 1.0;

    color = vec4(finalCol, alpha);
}