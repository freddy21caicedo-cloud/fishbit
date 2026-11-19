#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uView;
uniform float uTime;
uniform vec3 uHorizonColor;
uniform vec3 uWaveColor;
uniform vec3 uCrestColor;
uniform float uAmplitude;
uniform float uRelief;
uniform vec2 uLightDir;
uniform float uWaveScale;
uniform float uSwell;
uniform float uTurbulence;
uniform vec2 uPointer;     // normalized [0..1]
uniform vec4 uClickWave;   // xy = normalized origin, z = radius, w = strength
uniform float uOpacity;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float waveHeight(vec2 p, float t) {
  float sc = max(0.25, uWaveScale);
  float swellAmp = uSwell * 0.012;
  float turbAmp = uTurbulence * 0.008;

  // Rolling primary ocean swells
  float w1 = sin(p.x * 1.45 * sc + t * 1.10 + sin(p.y * 0.75 * sc - t * 0.55) * 0.85);
  float w2 = sin(p.y * 2.10 * sc - t * 0.85 + cos(p.x * 1.20 * sc + t * 0.45) * 0.65);
  float w3 = sin((p.x * 0.9 - p.y * 1.35) * 2.6 * sc + t * 1.40) * 0.45;

  // Fine surface turbulence
  float n = (vnoise(p * 2.4 * sc + vec2(t * 0.35, -t * 0.25)) - 0.5) * 2.0;
  float h = (w1 * 0.50 + w2 * 0.34 + w3 * 0.22) * (0.65 + swellAmp) + n * turbAmp;

  // Interactive swell pulse on click/tap
  if (uClickWave.w > 0.001) {
    float dist = length(p - uClickWave.xy);
    float ring = exp(-pow((dist - uClickWave.z) * 4.2, 2.0)) * uClickWave.w;
    h += sin((dist - uClickWave.z) * 14.0) * ring * 0.55;
  }

  return h * uAmplitude * 0.24;
}

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = vec2(fc.x / max(uView.x, 1.0), fc.y / max(uView.y, 1.0));
  float aspect = uView.x / max(uView.y, 1.0);

  // Subtle perspective projection toward the horizon at top
  float horizonY = 0.16;
  float depth = clamp((uv.y - horizonY) / (1.0 - horizonY), 0.0, 1.0);
  float persp = mix(3.4, 0.95, pow(depth, 0.72));

  vec2 centered = vec2((uv.x - 0.5) * aspect, uv.y);
  vec2 ptrShift = (uPointer - 0.5) * vec2(0.45, 0.22);
  vec2 waveCoord = vec2(centered.x * persp, depth * 3.8) + ptrShift;

  // Map click wave into wave coordinate space
  vec2 clickCentered = vec2((uClickWave.x - 0.5) * aspect, uClickWave.y);
  float clickDepth = clamp((uClickWave.y - horizonY) / (1.0 - horizonY), 0.0, 1.0);
  float clickPersp = mix(3.4, 0.95, pow(clickDepth, 0.72));
  vec2 clickCoord = vec2(clickCentered.x * clickPersp, clickDepth * 3.8) + ptrShift;

  // Evaluate height & analytical finite-difference normal
  float eps = 0.045;
  float h0 = waveHeight(waveCoord, uTime);
  float hx = waveHeight(waveCoord + vec2(eps, 0.0), uTime);
  float hy = waveHeight(waveCoord + vec2(0.0, eps), uTime);

  // Add localized click ripple directly in waveCoord space
  if (uClickWave.w > 0.001) {
    float d = length(waveCoord - clickCoord);
    float ring = exp(-pow((d - uClickWave.z * 2.4) * 2.2, 2.0)) * uClickWave.w;
    h0 += sin((d - uClickWave.z * 2.4) * 10.0) * ring * 0.28;
  }

  vec3 normal = normalize(vec3((h0 - hx) * 6.5 * uRelief, (h0 - hy) * 6.5 * uRelief, 1.0));
  vec3 lightDir = normalize(vec3(uLightDir.x, uLightDir.y, 0.78));
  vec3 viewDir = vec3(0.0, 0.0, 1.0);
  vec3 halfVec = normalize(lightDir + viewDir);

  float diffuse = clamp(dot(normal, lightDir) * 0.5 + 0.5, 0.0, 1.0);
  float spec = pow(max(dot(normal, halfVec), 0.0), 22.0) * (0.45 + 0.45 * uRelief);
  float crestFactor = smoothstep(0.18, 0.78, h0 * 1.45 + 0.45) * 0.55 + spec * 0.85;

  // Color blend: horizon haze -> rolling ocean wave -> luminous crest
  float haze = smoothstep(0.0, 0.62, depth);
  vec3 bodyColor = mix(uWaveColor * 0.52, uWaveColor * 1.08, diffuse);
  vec3 litWave = mix(bodyColor, uCrestColor, clamp(crestFactor * haze, 0.0, 0.92));

  // Soft horizon glow transitioning smoothly from top to waves
  float horizonGlow = exp(-pow((uv.y - 0.18) * 3.2, 2.0));
  vec3 skyAndHorizon = mix(uHorizonColor * 0.55, uHorizonColor, smoothstep(0.0, 0.35, uv.y));
  vec3 finalRgb = mix(skyAndHorizon, litWave, smoothstep(0.04, 0.52, depth));
  finalRgb += uHorizonColor * horizonGlow * 0.22;

  float alpha = clamp(uOpacity, 0.0, 1.0);
  fragColor = vec4(clamp(finalRgb, 0.0, 1.0) * alpha, alpha);
}
