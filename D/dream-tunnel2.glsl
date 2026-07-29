#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame; 
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;

const float PI = 3.1415926535897932384626433832795;

vec3 hsv2rgb(vec3 c){
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void){
    vec2 uvScreen = gl_FragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;

    vec2 center = (iMouse.z > 0.5 || iMouse.w > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5, 0.5);

    vec2 p = uvScreen - center;
    p.x *= aspect;

    float r = length(p);

    float audio = clamp(uamp * 1.6 + amp * 0.8, 0.0, 3.0);
    float t = time_f;

    float swirlPhase = t * (0.5 + 0.45 * audio) + r * (7.0 + 4.0 * audio);
    float cs = cos(swirlPhase);
    float sn = sin(swirlPhase);
    vec2 q = vec2(cs * p.x - sn * p.y, sn * p.x + cs * p.y);

    float zoomWave = 0.35 + 0.55 * sin(t * 0.4 + audio * 0.7);
    float tunnelDepth = 0.18 + zoomWave + r * (1.6 - 0.4 * audio);
    tunnelDepth = max(tunnelDepth, 0.12);

    vec2 tunnelUV = center + q / tunnelDepth;
    tunnelUV.x /= aspect;

    tunnelUV = clamp(tunnelUV, vec2(0.001), vec2(0.999));

    vec4 texTunnel = texture(samp, tunnelUV);
    vec4 texBase = texture(samp, tc);

    float ring = 0.5 + 0.5 * sin(r * (40.0 + 20.0 * audio) - t * (5.0 + audio * 8.0));
    float hue = fract(t * 0.04 + r * (1.2 + 0.8 * audio));
    float sat = 0.9;
    float val = 0.55 + 0.35 * ring;
    vec3 neon = hsv2rgb(vec3(hue, sat, val));

    float tunnelMix = smoothstep(0.0, 0.8, r * (1.3 + 0.5 * audio));
    tunnelMix = clamp(tunnelMix * (0.7 + 0.5 * audio), 0.0, 1.0);

    vec3 baseMixed = mix(texBase.rgb, texTunnel.rgb, tunnelMix);

    float audioGlow = clamp(audio * 0.75, 0.0, 1.2);
    vec3 withNeon = mix(baseMixed, neon, ring * (0.25 + 0.6 * audioGlow));

    float vigStrength = 0.55 + 0.25 * audioGlow;
    float vignette = 1.0 - vigStrength * r * r;
    vignette = clamp(vignette, 0.3, 1.0);

    vec3 finalCol = withNeon * vignette;
    finalCol = clamp(finalCol, 0.0, 1.0);

    color = vec4(finalCol, 1.0);
}
