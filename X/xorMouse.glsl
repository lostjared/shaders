#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

vec3 hueShift(vec3 color, float hue) {
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle);
}

void main() {
    vec4 baseColor = texture(samp, tc);
    vec2 mouseNorm = iMouse.xy / iResolution.xy;
    vec2 clickNorm = iMouse.zw / iResolution.xy;

    // Calculate drag vector and strength
    vec2 dragVec = mouseNorm - clickNorm;
    float dragStrength = smoothstep(0.0, 0.5, length(dragVec));
    vec2 dragDir = normalize(dragVec + vec2(0.0001));

    // Calculate color shift parameters
    float hueAngle = atan(dragDir.y, dragDir.x);
    float shiftAmount = dragStrength * 2.0;

    // Animate return when released
    float returnSpeed = 2.0;
    float timeDecay = exp(-time_f * returnSpeed * (1.0 - step(0.5, iMouse.z)));
    shiftAmount *= mix(timeDecay, 1.0, step(0.5, iMouse.z));

    // Apply directional hue shift
    vec3 shiftedColor = hueShift(baseColor.rgb, hueAngle * shiftAmount);

    // Add chromatic aberration
    vec2 redOffset = dragDir * shiftAmount * 0.02;
    vec2 greenOffset = dragDir * shiftAmount * 0.01;
    vec3 finalColor = vec3(
        texture(samp, tc - redOffset).r,
        texture(samp, tc - greenOffset).g,
        texture(samp, tc).b);

    // Blend between original and shifted colors
    finalColor = mix(finalColor, shiftedColor, dragStrength);

    color = vec4(finalColor, baseColor.a);
}