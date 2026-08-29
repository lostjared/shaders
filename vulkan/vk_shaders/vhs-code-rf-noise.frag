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
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
    return fract(p.x * p.y * 95.4337);
}

void main(void) {
    vec2 uv = tc;
    float frame = floor(time_f * 30.0);
    float line = floor(uv.y * max(iResolution.y, 1.0));
    float interference = sin(uv.y * 330.0 + time_f * 31.0);
    interference += 0.5 * sin(uv.y * 91.0 - time_f * 17.0);
    float burst = pow(hash21(vec2(floor(line * 0.125), floor(frame * 0.25))), 18.0);

    uv.x += interference * 0.0018 + burst * (hash21(vec2(line, frame)) - 0.5) * 0.18;
    uv = clamp(uv, 0.001, 0.999);

    vec3 image;
    image.r = texture(samp, uv + vec2(0.0025, 0.0)).r;
    image.g = texture(samp, uv).g;
    image.b = texture(samp, uv - vec2(0.003, 0.0)).b;

    float fineSnow = hash21(gl_FragCoord.xy + frame * 47.0) - 0.5;
    float streakSnow = hash21(vec2(gl_FragCoord.x * 0.08 + frame, line)) - 0.5;
    float signalLoss = 0.04 + burst * 0.75;
    vec3 snow = vec3(fineSnow + streakSnow * 0.45);
    image = mix(image, vec3(0.5) + snow, signalLoss);
    image += interference * 0.012;
    image *= 0.95 + 0.05 * sin(line * 3.14159265);

    color = vec4(clamp(image, 0.0, 1.0), 1.0);
}
