#version 330

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse; // xy = mouse position, z>0 means pressed

void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution.xy) : vec2(0.5);
    vec2 uv = tc;

    float dist = distance(uv, m);
    float falloff = smoothstep(0.5, 0.0, dist);

    float distortionStrength = 0.03 * falloff;
    float distortionFrequency = 20.0;

    float distortion1 = sin((uv.y + dist * 5.0) * distortionFrequency + time_f) * distortionStrength;
    float distortion2 = cos((uv.x + uv.y + dist * 5.0) * distortionFrequency + time_f) * distortionStrength;

    vec2 distortedTC1 = uv + vec2(distortion1, distortion2);
    vec2 distortedTC2 = uv + vec2(distortion2, -distortion1);

    vec4 texColor1 = texture(samp, distortedTC1);
    vec4 texColor2 = texture(samp, distortedTC2);

    color = mix(texColor1, texColor2, 0.5 + 0.5 * sin(time_f));
}
