#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;               // accumulated time value, affected by speed and audio when enabled
uniform sampler2D samp;             // input video frame texture
uniform vec2 iResolution;           // viewport resolution in pixels (width, height)
uniform vec4 iMouse;                // mouse position: xy = current, zw = click start (drag)
uniform float amp;                  // audio amplitude scaled by sensitivity
uniform float uamp;                 // raw audio amplitude before sensitivity scaling
uniform float iTime;                // elapsed wall-clock time in seconds
uniform int iFrame;                 // current frame number
uniform float iTimeDelta;           // time since last frame in seconds
uniform vec4 iDate;                 // current date/time: (year, month, day, seconds since midnight)
uniform vec2 iMouseClick;           // position of last mouse click
uniform float iFrameRate;           // target frame rate
uniform vec3 iChannelResolution[4]; // resolution of each texture channel
uniform float iChannelTime[4];      // playback time for each texture channel
uniform float iSampleRate;          // audio sample rate in Hz (e.g. 44100)
uniform float amp_peak;             // peak absolute sample value in current audio buffer
uniform float amp_rms;              // RMS energy of current audio buffer
uniform float amp_smooth;           // exponentially smoothed amplitude for gradual transitions
uniform float amp_low;              // bass energy (below ~300 Hz)
uniform float amp_mid;              // mid-range energy (~300-3000 Hz)
uniform float amp_high;             // treble energy (above ~3000 Hz)
uniform float iamp;                 // estimated dominant frequency in Hz via zero-crossing rate

void main(void) {
    color = texture(samp, tc);
}
