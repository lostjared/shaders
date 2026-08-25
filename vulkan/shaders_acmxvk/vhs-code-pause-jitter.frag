#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;
    float field = floor(time_f * 59.94);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float alternate = mod(field, 2.0) * 2.0 - 1.0;
    float verticalJitter = (hash21(vec2(field, 1.0)) - 0.5) * 0.012;
    float horizontalJitter = (hash21(vec2(line, field)) - 0.5) * 0.006;

    uv.y = fract(uv.y + verticalJitter + alternate / max(iResolution.y, 1.0));
    uv.x += horizontalJitter + sin(line * 0.16 + time_f * 8.0) * 0.002;

    float tearCenter = 0.5 + sin(time_f * 0.7) * 0.18;
    float tear = 1.0 - smoothstep(0.0, 0.025, abs(uv.y - tearCenter));
    uv.x += tear * (hash21(vec2(field, 9.0)) - 0.5) * 0.16;
    uv = clamp(uv, 0.001, 0.999);

    vec3 image;
    image.r = texture(samp, uv + vec2(0.0035, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(0.0045, 0.0)).b;

    float staticNoise = hash21(gl_FragCoord.xy + field * 41.0) - 0.5;
    float interlace = mix(0.82, 1.0, step(0.5, fract(line * 0.5)));
    image *= interlace;
    image += staticNoise * (0.045 + tear * 0.3);
    image += tear * 0.08;

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
