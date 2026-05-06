import * as THREE from "../assets/three_adjustment/vendor/three/build/three.module.js";
import { OrbitControls } from "../assets/three_adjustment/vendor/three/examples/jsm/controls/OrbitControls.js";
import { RoundedBoxGeometry } from "../assets/three_adjustment/vendor/three/examples/jsm/geometries/RoundedBoxGeometry.js";
import { GLTFLoader } from "../assets/three_adjustment/vendor/three/examples/jsm/loaders/GLTFLoader.js";

function readInitialAppConfig() {
  const params = new URLSearchParams(window.location.search);
  const config = {
    embedded: true,
    transparent: true,
    showUI: false,
    mode: "flat",
    performance: "default",
    maxDpr: null,
    renderMode: "continuous",
    ...(window.__SMART_MATTRESS_CONFIG__ || {})
  };
  if (params.has("embedded")) config.embedded = params.get("embedded") !== "0";
  if (params.has("ui")) config.showUI = params.get("ui") !== "0";
  if (params.has("transparent")) config.transparent = params.get("transparent") !== "0";
  if (params.has("mode")) config.mode = params.get("mode");
  if (params.has("autorun")) config.autorun = params.get("autorun") !== "0";
  if (params.has("performance")) config.performance = params.get("performance") || config.performance;
  if (params.has("maxDpr")) config.maxDpr = Number(params.get("maxDpr"));
  if (params.has("renderMode")) config.renderMode = params.get("renderMode") || config.renderMode;
  return config;
}

const initialAppConfig = readInitialAppConfig();
const isIOSNativeEmbed = window.__SMART_MATTRESS_IOS_EMBED__ === true || initialAppConfig.transparent === true;
const glbModelUrl = new URL("./smart-mattress-replica.glb", window.location.href).href;
const performanceProfile = initialAppConfig.performance === "balanced" ? "balanced" : "default";
const renderMode = initialAppConfig.renderMode === "onDemand" ? "onDemand" : "continuous";
const maxDpr = Number.isFinite(initialAppConfig.maxDpr)
  ? Math.max(1, initialAppConfig.maxDpr)
  : (performanceProfile === "balanced" ? 1.25 : 2);
const canvas = document.querySelector("#scene");
const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: isIOSNativeEmbed,
  powerPreference: "high-performance"
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, maxDpr));
renderer.setSize(window.innerWidth, window.innerHeight);
if (isIOSNativeEmbed) {
  renderer.setClearColor(0x000000, 0);
}
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.14;

const scene = new THREE.Scene();
scene.background = isIOSNativeEmbed ? null : new THREE.Color(0x07182c);
scene.fog = new THREE.FogExp2(0x07182c, 0.037);

function cameraAspect() {
  return window.innerWidth / window.innerHeight;
}

const camera = new THREE.PerspectiveCamera(37, cameraAspect(), 0.1, 80);
camera.position.set(0, 5.05, 6.05);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.target.set(0, 0.48, 0.18);
controls.minDistance = 3.4;
controls.maxDistance = 8.2;
controls.minPolarAngle = 0.18;
controls.maxPolarAngle = Math.PI * 0.46;

const bed = new THREE.Group();
scene.add(bed);

const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
const zoneMeshes = [];
const labels = [];
const coverSlices = [];
const heatZones = [];
const sideWalls = [];
const topSurfaces = [];
let glbModelRoot;
let outerCover;
let topSheen;
let scanFrame;
let scanWash;
let reveal = 0;
let targetReveal = 0;
let scanProgress = 1;
const sideRevealTarget = { left: 0, right: 0 };
const sideScanProgress = { left: 1, right: 1 };
const sideAdjustment = {
  left: { active: false, start: -1, config: null, done: true },
  right: { active: false, start: -1, config: null, done: true }
};
const sideScanControl = {
  left: { active: false, start: -1, duration: 2600 },
  right: { active: false, start: -1, duration: 2600 }
};
const manualCamera = {
  active: false,
  start: -1,
  duration: 1800,
  endPhase: "sideHold",
  fromPosition: new THREE.Vector3(),
  fromTarget: new THREE.Vector3(),
  toPosition: new THREE.Vector3(),
  toTarget: new THREE.Vector3(),
  path: "direct",
  arcDirection: 1
};
let autoCameraPausedUntil = 0;
let focusSide = "right";
let cameraPhase = "overview";
let cameraPath = "direct";
let cameraArcDirection = 1;
let cameraManualHoldPhase = "overview";
let adjustmentSequenceStart = -1;
let adjustmentSequenceActive = false;
let visualReturnStarted = false;
let visualReturnStart = -1;
let activeZoneIndex = -1;
let displayedZoneIndex = -2;
let appConfig = {};
let isSceneReady = false;
let renderedFrameCount = 0;
let animationFrameId = 0;
let continuousUntil = 0;
let lastInteractionFrameTime = 0;
let hoveredDirty = true;
const cameraDesired = new THREE.Vector3();
const targetDesired = new THREE.Vector3();
const cameraMoveStart = new THREE.Vector3();
const targetMoveStart = new THREE.Vector3();
const overviewPosition = new THREE.Vector3(0, 5.05, 6.05);
const overviewTarget = new THREE.Vector3(0, 0.48, 0.18);
const tmpColor = new THREE.Color();
const scanStartZ = -1.88;
const scanEndZ = 1.99;
const scanRangeZ = scanEndZ - scanStartZ;
const cameraTiming = {
  moveToSide: 2000,
  sideHold: 27000,
  returnOverview: 35000,
  zoneDuration: 5000,
  scanDuration: 2600
};
const settleTiming = {
  reveal: 6000,
  camera: 500,
  heat: 6000,
  hover: 1000,
  bootstrap: 2000
};

const palette = {
  cyan: new THREE.Color(0x00c8ff),
  blue: new THREE.Color(0x005cff),
  ergonomicBlue: new THREE.Color(0x2496ff),
  ice: new THREE.Color(0xaeeeff),
  electric: new THREE.Color(0x0036cc),
  green: new THREE.Color(0x47d893),
  pink: new THREE.Color(0xff4d79),
  heat: new THREE.Color(0xff8628),
  heatCore: new THREE.Color(0xffd28a),
  heatDark: new THREE.Color(0x5a1608),
  fabric: new THREE.Color(0x25364a),
  side: new THREE.Color(0x0d1725)
};

const heatState = {
  left: { waist: false, leg: false },
  right: { waist: false, leg: false }
};

function postAppEvent(type, detail = {}) {
  const payload = { type, detail, state: getPublicState() };
  window.dispatchEvent(new CustomEvent("SmartMattress3D:event", { detail: payload }));
  window.webkit?.messageHandlers?.smartMattress?.postMessage?.(payload);
  window.SmartMattressBridge?.postMessage?.(JSON.stringify(payload));
  return payload;
}

function requestRender(duration = 1000) {
  continuousUntil = Math.max(continuousUntil, performance.now() + duration);
  if (animationFrameId === 0) {
    animationFrameId = requestAnimationFrame(animate);
  }
}

function hasHeatingActive() {
  return Object.values(heatState.left).some(Boolean) || Object.values(heatState.right).some(Boolean);
}

function shouldContinueRendering(nowMs) {
  if (renderMode !== "onDemand") return true;
  if (nowMs < continuousUntil) return true;
  if (!isSceneReady || renderedFrameCount < 3) return true;
  if (adjustmentSequenceActive || manualCamera.active || hasActiveSideAdjustment()) return true;
  if (sideScanControl.left.active || sideScanControl.right.active) return true;
  if (hasActiveManualBladder() || hasHeatingActive()) return true;
  if (Math.abs(reveal - targetReveal) > 0.006) return true;
  if (coverSlices.some((slice) => Math.abs((slice.userData.reveal ?? 0) - (sideRevealTarget[slice.userData.side] || 0)) > 0.02)) return true;
  if (topSurfaces.some((top) => Math.abs((top.userData.reveal ?? 0) - (sideRevealTarget[top.userData.side] || 0)) > 0.02)) return true;
  if (heatZones.some((heat) => heat.userData.strength > 0.012)) return true;
  if (hoveredDirty || nowMs - lastInteractionFrameTime < settleTiming.hover) return true;
  return false;
}

function getPublicState() {
  return {
    ready: isSceneReady,
    mode: currentMode,
    focusSide,
    cameraPhase,
    reveal: Number(reveal.toFixed(3)),
    scanProgress: Number(scanProgress.toFixed(3)),
    activeZone: activeZoneIndex >= 0 ? zones[activeZoneIndex]?.key ?? null : null,
    sideAdjustment: {
      left: sideAdjustment.left.active,
      right: sideAdjustment.right.active
    },
    manualBladders: JSON.parse(JSON.stringify(manualBladderControl)),
    revealSides: {
      left: Number(sideRevealTarget.left.toFixed(3)),
      right: Number(sideRevealTarget.right.toFixed(3))
    },
    heating: JSON.parse(JSON.stringify(heatState)),
    embedded: document.body.dataset.embedded === "true"
  };
}

function setUIVisible(visible) {
  document.body.dataset.embedded = visible ? "false" : "true";
  postAppEvent("ui", { visible });
}

function createFabricTexture() {
  const canvas = document.createElement("canvas");
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "#26394f";
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  const grad = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
  grad.addColorStop(0, "rgba(255,255,255,.16)");
  grad.addColorStop(0.34, "rgba(255,255,255,.025)");
  grad.addColorStop(1, "rgba(0,0,0,.32)");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  for (let y = 0; y < canvas.height; y += 10) {
    ctx.strokeStyle = y % 30 === 0 ? "rgba(220,235,255,.14)" : "rgba(220,235,255,.045)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, y + 0.5);
    ctx.lineTo(canvas.width, y + 0.5);
    ctx.stroke();
  }
  for (let x = 0; x < canvas.width; x += 12) {
    ctx.strokeStyle = x % 36 === 0 ? "rgba(255,255,255,.09)" : "rgba(255,255,255,.03)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x + 0.5, 0);
    ctx.lineTo(x + 0.5, canvas.height);
    ctx.stroke();
  }
  for (let y = -canvas.height; y < canvas.height * 2; y += 34) {
    ctx.strokeStyle = "rgba(213,234,255,.045)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y + canvas.width * 0.42);
    ctx.stroke();
  }
  for (let y = 18; y < canvas.height; y += 68) {
    ctx.strokeStyle = "rgba(7,18,32,.16)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(24, y + 0.5);
    ctx.lineTo(canvas.width - 24, y + 0.5);
    ctx.stroke();
  }
  for (let i = 0; i < 3000; i++) {
    const alpha = 0.012 + Math.random() * 0.045;
    ctx.fillStyle = Math.random() > 0.35 ? `rgba(255,255,255,${alpha})` : `rgba(0,0,0,${alpha})`;
    ctx.fillRect(Math.random() * canvas.width, Math.random() * canvas.height, 1, 1);
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.wrapS = THREE.RepeatWrapping;
  texture.wrapT = THREE.RepeatWrapping;
  texture.repeat.set(3.8, 5.6);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

const fabricTexture = createFabricTexture();

function createHeatMaterial() {
  return new THREE.ShaderMaterial({
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    depthTest: true,
    side: THREE.DoubleSide,
    uniforms: {
      uTime: { value: 0 },
      uStrength: { value: 0 },
      uRevealDimming: { value: 1 },
      uPhase: { value: 0 },
      uHeatColor: { value: new THREE.Color(0xff8628) },
      uHotColor: { value: new THREE.Color(0xffd28a) }
    },
    vertexShader: `
      varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    `,
    fragmentShader: `
      precision highp float;
      varying vec2 vUv;
      uniform float uTime;
      uniform float uStrength;
      uniform float uRevealDimming;
      uniform float uPhase;
      uniform vec3 uHeatColor;
      uniform vec3 uHotColor;

      float sdRoundBox(vec2 p, vec2 b, float r) {
        vec2 q = abs(p) - b + r;
        return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
      }

      float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
      }

      float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        vec2 u = f * f * (3.0 - 2.0 * f);
        return mix(
          mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
          mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
          u.y
        );
      }

      float fbm(vec2 p) {
        float value = 0.0;
        float amp = 0.5;
        for (int i = 0; i < 4; i++) {
          value += amp * noise(p);
          p *= 2.03;
          amp *= 0.5;
        }
        return value;
      }

      float particleLayer(vec2 uv, float scale, float salt) {
        vec2 g = uv * scale;
        vec2 id = floor(g);
        vec2 f = fract(g);
        float n = hash(id + vec2(salt, salt * 1.73));
        vec2 jitter = vec2(
          hash(id + vec2(17.2 + salt, 41.7)),
          hash(id + vec2(9.6, 23.4 + salt))
        );
        jitter += vec2(
          sin(uTime * 0.12 + n * 6.2831853),
          cos(uTime * 0.09 + n * 5.37)
        ) * 0.075;
        float size = mix(0.028, 0.085, hash(id + vec2(5.1, 13.8 + salt)));
        float dot = 1.0 - smoothstep(size * 0.28, size, length(f - jitter));
        float life = 0.42 + 0.58 * smoothstep(
          0.0,
          1.0,
          0.5 + 0.5 * sin(uTime * 0.34 + n * 6.2831853)
        );
        float sparse = smoothstep(0.38, 0.98, n);
        return dot * life * sparse;
      }

      void main() {
        vec2 p = (vUv - 0.5) * vec2(1.0, 1.0);
        float fieldNoise = fbm(vUv * 4.2 + vec2(uTime * 0.025, -uTime * 0.018 + uPhase));
        float fineNoise = fbm(vUv * 9.0 + vec2(-uTime * 0.018, uTime * 0.026));
        float cleanSd = sdRoundBox(p, vec2(0.43, 0.37), 0.075);
        float inside = 1.0 - smoothstep(0.0, 0.04, cleanSd);
        float particleInside = 1.0 - smoothstep(-0.01, 0.05, cleanSd);
        float breath = 0.5 + 0.5 * sin((uTime * 0.08 + uPhase) * 6.2831853);
        breath = smoothstep(0.0, 1.0, breath);

        float edgeDistance = abs(cleanSd);
        float regularHalo = exp(-edgeDistance * 16.5) * (1.0 - smoothstep(0.11, 0.24, cleanSd));
        float centerDepth = clamp((-cleanSd) / 0.36, 0.0, 1.0);
        float inwardBase = pow(1.0 - centerDepth, 1.18);
        float irregular = mix(0.82, 1.18, fieldNoise) + (fineNoise - 0.5) * 0.16;
        float inward = particleInside * inwardBase * irregular;
        float centerMist = inside * smoothstep(0.08, 0.72, centerDepth) * (0.06 + fieldNoise * 0.035);
        float softFill = inside * (0.065 + fieldNoise * 0.035);
        vec2 warpedUv = vUv + vec2(fieldNoise - 0.5, fineNoise - 0.5) * 0.055;
        float particles = (
          particleLayer(warpedUv, 13.0, uPhase * 11.0 + 1.0) +
          particleLayer(warpedUv + vec2(0.13, -0.07), 20.0, uPhase * 17.0 + 7.0) * 0.66 +
          particleLayer(warpedUv + vec2(-0.09, 0.16), 27.0, uPhase * 23.0 + 3.0) * 0.34
        ) * inward;
        float heatDrift = fbm(vUv * 5.4 + vec2(uTime * 0.036, uPhase * 3.5 - uTime * 0.028));
        float flow = smoothstep(0.58, 1.0, heatDrift) * inward * 0.052;

        float alpha = uStrength * uRevealDimming * (
          softFill +
          centerMist * (0.46 + breath * 0.38) +
          inward * (0.1 + breath * 0.18) +
          particles * (0.16 + breath * 0.34) +
          regularHalo * (0.2 + breath * 0.42) +
          flow
        );
        vec3 color = mix(uHeatColor, uHotColor, clamp(regularHalo * 0.52 + particles * 0.34 + inward * 0.14 + centerMist * 0.2 + breath * 0.2, 0.0, 1.0));
        gl_FragColor = vec4(color, alpha);
      }
    `
  });
}

const matFabric = new THREE.MeshStandardMaterial({
  color: palette.fabric,
  map: fabricTexture,
  roughness: 0.88,
  metalness: 0.02,
  emissive: new THREE.Color(0x061426),
  emissiveIntensity: 0.12
});
const matSide = new THREE.MeshStandardMaterial({
  color: palette.side,
  roughness: 0.82,
  metalness: 0.04,
  emissive: new THREE.Color(0x061426),
  emissiveIntensity: 0.12
});
const matActive = new THREE.MeshBasicMaterial({
  color: 0x0077ff,
  transparent: true,
  opacity: 0,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
  depthTest: true
});
const matBladderAura = new THREE.MeshBasicMaterial({
  color: 0x005cff,
  transparent: true,
  opacity: 0,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
  depthTest: true,
  side: THREE.BackSide
});
const matBladderRim = new THREE.MeshBasicMaterial({
  color: 0x67d7f5,
  transparent: true,
  opacity: 0,
  blending: THREE.AdditiveBlending,
  depthWrite: false,
  depthTest: true,
  side: THREE.BackSide
});
const matWarning = new THREE.MeshBasicMaterial({
  color: 0xff4d9a,
  transparent: true,
  opacity: 0.34,
  blending: THREE.AdditiveBlending,
  depthWrite: false
});
const matBladder = new THREE.MeshStandardMaterial({
  color: 0x005cff,
  roughness: 0.42,
  metalness: 0,
  transparent: true,
  opacity: 0.16,
  emissive: 0x67d7f5,
  emissiveIntensity: 0.28,
  depthWrite: false
});
const matCover = new THREE.MeshPhysicalMaterial({
  color: 0x6f9fc8,
  roughness: 0.48,
  metalness: 0,
  transmission: 0.16,
  thickness: 0.05,
  transparent: true,
  opacity: 0.1,
  emissive: 0x000000,
  emissiveIntensity: 0,
  depthWrite: false
});
const matOuterCover = new THREE.MeshPhysicalMaterial({
  color: 0x2b4058,
  roughness: 0.86,
  metalness: 0,
  transmission: 0,
  thickness: 0.12,
  transparent: true,
  opacity: 1,
  emissive: 0x020812,
  emissiveIntensity: 0.02,
  map: fabricTexture,
  depthWrite: true
});

function roundedBox(w, h, d, radius = 0.06, segments = 4) {
  return new RoundedBoxGeometry(w, h, d, segments, radius);
}

function addMesh(group, geometry, material, position, rotation = [0, 0, 0]) {
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(...position);
  mesh.rotation.set(...rotation);
  group.add(mesh);
  return mesh;
}

function easeInOutCubic(value) {
  const x = THREE.MathUtils.clamp(value, 0, 1);
  return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
}

function linearBreath(timeSeconds, periodSeconds = 4.8, phase = 0) {
  const p = (timeSeconds / periodSeconds + phase) % 1;
  return p < 0.5 ? p * 2 : 2 - p * 2;
}

function createScanSweepTexture() {
  const canvas = document.createElement("canvas");
  canvas.width = 512;
  canvas.height = 256;
  const ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const verticalGlow = ctx.createLinearGradient(0, 0, 0, canvas.height);
  verticalGlow.addColorStop(0, "rgba(0,92,255,0)");
  verticalGlow.addColorStop(0.38, "rgba(0,92,255,.08)");
  verticalGlow.addColorStop(0.48, "rgba(0,200,255,.52)");
  verticalGlow.addColorStop(0.52, "rgba(158,245,255,.78)");
  verticalGlow.addColorStop(0.58, "rgba(0,120,255,.18)");
  verticalGlow.addColorStop(1, "rgba(0,92,255,0)");
  ctx.fillStyle = verticalGlow;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.shadowColor = "rgba(0,220,255,.9)";
  ctx.shadowBlur = 26;
  ctx.strokeStyle = "rgba(190,250,255,.96)";
  ctx.lineWidth = 5;
  ctx.beginPath();
  ctx.moveTo(18, 132);
  ctx.lineTo(canvas.width - 18, 124);
  ctx.stroke();

  ctx.shadowBlur = 12;
  ctx.strokeStyle = "rgba(0,92,255,.34)";
  ctx.lineWidth = 2;
  [158, 184, 212].forEach((y, index) => {
    ctx.globalAlpha = 0.36 - index * 0.08;
    ctx.beginPath();
    ctx.moveTo(44 + index * 28, y);
    ctx.lineTo(canvas.width - 44 - index * 34, y - 14);
    ctx.stroke();
  });
  ctx.globalAlpha = 1;

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

const scanSweepTexture = createScanSweepTexture();

function createScanFrame() {
  const group = new THREE.Group();
  group.name = "line_mode_scan_blade";
  group.userData.scan = true;
  group.position.set(0, 0, scanStartZ);

  const coreMat = new THREE.MeshBasicMaterial({
    color: 0x00c8ff,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    depthTest: false
  });
  const haloMat = new THREE.MeshBasicMaterial({
    color: 0x005cff,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    depthTest: false
  });
  const curtainMat = new THREE.MeshBasicMaterial({
    color: 0xffffff,
    map: scanSweepTexture,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    depthTest: false,
    side: THREE.DoubleSide
  });

  const curtain = new THREE.Mesh(new THREE.PlaneGeometry(3.04, 0.64), curtainMat);
  curtain.rotation.x = -Math.PI / 2;
  curtain.position.set(0, 0.58, 0);
  curtain.userData.scanCurtain = true;
  curtain.renderOrder = 29;
  group.add(curtain);

  const rails = [
    { size: [2.78, 0.014, 0.018], pos: [0, 0.592, 0.01], type: "core", opacity: 0.72 },
    { size: [2.9, 0.04, 0.05], pos: [0, 0.592, 0.005], type: "halo", opacity: 0.2 },
    { size: [2.2, 0.01, 0.012], pos: [0, 0.578, -0.16], type: "tail", opacity: 0.16 },
    { size: [1.68, 0.008, 0.01], pos: [0, 0.566, -0.3], type: "tail", opacity: 0.08 }
  ];

  rails.forEach(({ size, pos, type, opacity }) => {
    const material = type === "core" ? coreMat.clone() : haloMat.clone();
    const mesh = addMesh(group, roundedBox(size[0], size[1], size[2], 0.012, 3), material, pos);
    mesh.userData.scanPart = type;
    mesh.userData.scanOpacity = opacity;
    mesh.renderOrder = type === "core" ? 33 : 32;
  });

  group.visible = false;
  return group;
}

function makeLabel(text, color = "#dff6ff") {
  const c = document.createElement("canvas");
  c.width = 256;
  c.height = 96;
  const ctx = c.getContext("2d");
  ctx.clearRect(0, 0, c.width, c.height);
  ctx.font = "700 32px -apple-system, BlinkMacSystemFont, sans-serif";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.shadowColor = "rgba(57,215,255,.9)";
  ctx.shadowBlur = 18;
  ctx.fillStyle = color;
  ctx.fillText(text, 128, 48);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }));
  sprite.scale.set(0.48, 0.18, 1);
  return sprite;
}

function createEnvironment() {
  scene.add(new THREE.HemisphereLight(0xe9f7ff, 0x1a2b42, 2.65));
  const key = new THREE.DirectionalLight(0xffffff, 3.05);
  key.position.set(4, 6, 3);
  scene.add(key);
  const fill = new THREE.DirectionalLight(0xa9d7ff, 1.75);
  fill.position.set(-2.5, 3.2, 5.5);
  scene.add(fill);
  const rim = new THREE.PointLight(0x1a80ff, 4.2, 8.5);
  rim.position.set(0, 1.8, -2.2);
  scene.add(rim);

  if (!isIOSNativeEmbed) {
    const floor = new THREE.Mesh(
      new THREE.PlaneGeometry(14, 10, 32, 24),
      new THREE.MeshBasicMaterial({ color: 0x0a1a2c, transparent: true, opacity: 0.28, wireframe: true })
    );
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.24;
    scene.add(floor);
  }

  const halo = new THREE.Mesh(
    new THREE.RingGeometry(1.65, 2.35, 96),
    new THREE.MeshBasicMaterial({ color: 0x2496ff, transparent: true, opacity: isIOSNativeEmbed ? 0.018 : 0.06, blending: THREE.AdditiveBlending, side: THREE.DoubleSide })
  );
  halo.rotation.x = -Math.PI / 2;
  halo.position.y = -0.18;
  bed.add(halo);

}

function createBedFrame() {
  const platformMat = matSide.clone();
  platformMat.color.set(0x09121f);
  platformMat.emissive.set(0x020914);
  platformMat.emissiveIntensity = 0.1;
  const platformWidth = 2.96;
  const platformLength = 4.06;
  const platformZ = 0.08;
  addMesh(bed, roundedBox(platformWidth, 0.22, platformLength, 0.12), platformMat, [0, -0.04, platformZ]);
  const mattressBase = addMesh(bed, roundedBox(2.76, 0.18, 3.86, 0.14), matFabric.clone(), [0, 0.17, 0.08]);
  mattressBase.name = "single_mattress_lower_body";
  mattressBase.material.color.set(0x20334a);
  mattressBase.material.emissiveIntensity = 0.06;

  const headboardMat = matSide.clone();
  headboardMat.color.set(0x233149);
  headboardMat.emissive.set(0x040f20);
  headboardMat.emissiveIntensity = 0.14;
  addMesh(bed, roundedBox(2.86, 0.58, 0.22, 0.08), headboardMat, [0, 0.61, -2.23], [-0.08, 0, 0]);

  const wingMat = headboardMat.clone();
  wingMat.color.set(0x2d3e58);
  addMesh(bed, roundedBox(0.16, 0.58, 0.26, 0.06), wingMat, [-1.5, 0.56, -2.12], [-0.08, 0, 0]);
  addMesh(bed, roundedBox(0.16, 0.58, 0.26, 0.06), wingMat, [1.5, 0.56, -2.12], [-0.08, 0, 0]);

  const pillowMat = new THREE.MeshStandardMaterial({
    color: 0x9fb4cf,
    roughness: 0.82,
    metalness: 0,
    emissive: 0x0b1a2f,
    emissiveIntensity: 0.045,
    map: fabricTexture
  });
  const pillowLeft = addMesh(bed, roundedBox(1.14, 0.28, 0.66, 0.15, 8), pillowMat.clone(), [-0.62, 0.56, -1.6], [-0.07, 0, 0]);
  const pillowRight = addMesh(bed, roundedBox(1.14, 0.28, 0.66, 0.15, 8), pillowMat.clone(), [0.62, 0.56, -1.6], [-0.07, 0, 0]);
  const pillowSeamMat = new THREE.MeshBasicMaterial({
    color: 0xd4e8ff,
    transparent: true,
    opacity: 0.16,
    depthWrite: false
  });
  const pillowDimpleMat = new THREE.MeshBasicMaterial({
    color: 0x17304f,
    transparent: true,
    opacity: 0.18,
    depthWrite: false
  });
  [pillowLeft, pillowRight].forEach((pillow) => {
    [-0.28, 0, 0.28].forEach((x) => {
      addMesh(pillow, roundedBox(0.03, 0.01, 0.42, 0.016, 3), pillowDimpleMat.clone(), [x, 0.151, 0]);
    });
    [-0.2, 0.2].forEach((z) => {
      addMesh(pillow, roundedBox(0.72, 0.01, 0.014, 0.012, 3), pillowSeamMat.clone(), [0, 0.149, z]);
    });
  });
}

function createOuterMattressCover() {
  outerCover = new THREE.Group();
  outerCover.name = "continuous_mattress_side_fabric_shell";
  bed.add(outerCover);

  const sideWallMat = matOuterCover.clone();
  sideWallMat.color.set(0x23364d);
  sideWallMat.opacity = 1;
  sideWallMat.transmission = 0;
  sideWallMat.depthWrite = true;
  sideWallMat.emissiveIntensity = 0;

  [
    { size: [0.12, 0.34, 3.86], pos: [-1.42, 0.37, 0.06], side: "left" },
    { size: [0.12, 0.34, 3.86], pos: [1.42, 0.37, 0.06], side: "right" },
    { size: [2.76, 0.34, 0.12], pos: [0, 0.37, -1.87], side: "head" },
    { size: [2.76, 0.34, 0.12], pos: [0, 0.37, 1.99], side: "foot" }
  ].forEach(({ size, pos, side }) => {
    const wall = addMesh(outerCover, roundedBox(size[0], size[1], size[2], 0.08, 5), sideWallMat.clone(), pos);
    wall.name = `${side}_mattress_side_reveal_wall`;
    wall.userData.sideWall = side === "left" || side === "right";
    wall.userData.side = side;
    wall.userData.reveal = 0;
    wall.renderOrder = 3;
    if (wall.userData.sideWall) sideWalls.push(wall);
  });

  const staticTopMat = matOuterCover.clone();
  staticTopMat.color.set(0x30475f);
  staticTopMat.opacity = 1;
  staticTopMat.transmission = 0;
  staticTopMat.depthWrite = true;
  staticTopMat.emissiveIntensity = 0;
  [
    { depth: 0.34, z: -1.66 },
    { depth: 0.34, z: 1.78 }
  ].forEach(({ depth, z }) => {
    const panel = addMesh(outerCover, roundedBox(2.72, 0.07, depth, 0.11, 5), staticTopMat.clone(), [0, 0.505, z]);
    panel.name = "fixed_realistic_mattress_fabric_end_panel";
    panel.renderOrder = 6;
  });

  const pipingMat = new THREE.MeshBasicMaterial({
    color: 0xd2e8ff,
    transparent: true,
    opacity: 0.12,
    depthWrite: false
  });
  [
    { size: [0.025, 0.012, 3.45], pos: [-1.31, 0.555, 0.06] },
    { size: [0.025, 0.012, 3.45], pos: [1.31, 0.555, 0.06] },
    { size: [2.58, 0.012, 0.025], pos: [0, 0.555, -1.48] },
    { size: [2.58, 0.012, 0.025], pos: [0, 0.555, 1.64] }
  ].forEach(({ size, pos }) => {
    const pipe = addMesh(outerCover, roundedBox(size[0], size[1], size[2], 0.012, 3), pipingMat.clone(), pos);
    pipe.name = "subtle_mattress_edge_piping";
    pipe.userData.isPiping = true;
    pipe.renderOrder = 12;
  });

  topSheen = addMesh(
    bed,
    roundedBox(2.48, 0.012, 3.42, 0.12, 5),
    new THREE.MeshBasicMaterial({
      color: 0x7dcaff,
      transparent: true,
      opacity: 0,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    }),
    [0, 0.51, 0.06]
  );
  topSheen.name = "soft_translucent_top_surface";
  topSheen.visible = false;
  topSheen.renderOrder = 9;

  ["left", "right"].forEach((side) => {
    const topMat = matOuterCover.clone();
    topMat.color.set(0x31485f);
    topMat.opacity = 1;
    topMat.transmission = 0;
    topMat.depthWrite = true;
    topMat.roughness = 0.88;
    topMat.emissiveIntensity = 0;
    const top = addMesh(
      outerCover,
      roundedBox(1.36, 0.06, 3.42, 0.1, 5),
      topMat,
      [side === "left" ? -0.68 : 0.68, 0.505, 0.06]
    );
    top.name = `${side}_continuous_mattress_top_fabric`;
    top.userData.topSurface = true;
    top.userData.side = side;
    top.userData.reveal = 0;
    top.renderOrder = 7;
    topSurfaces.push(top);
  });

  zones.forEach((zone) => {
    ["left", "right"].forEach((side) => {
      const sliceMat = matOuterCover.clone();
      sliceMat.color.set(0x314860);
      sliceMat.opacity = 0;
      sliceMat.transmission = 0;
      sliceMat.depthWrite = false;
      sliceMat.roughness = 0.88;
      sliceMat.emissiveIntensity = 0;
      const slice = addMesh(
        bed,
        roundedBox(1.38, 0.07, zone.depth * 1.04, 0.1, 5),
        sliceMat,
        [side === "left" ? -0.69 : 0.69, 0.505, zone.z]
      );
      slice.name = `${side}_${zone.key}_realistic_fabric_slice`;
      slice.userData.coverSlice = true;
      slice.userData.key = zone.key;
      slice.userData.side = side;
      slice.userData.zStart = zone.z - zone.depth * 0.5;
      slice.userData.zEnd = zone.z + zone.depth * 0.5;
      slice.userData.reveal = 0;
      slice.visible = false;
      slice.renderOrder = 8;
      coverSlices.push(slice);
    });
  });

  zones.filter((zone) => zone.key === "waist" || zone.key === "leg").forEach((zone) => {
    ["left", "right"].forEach((side) => {
      const heat = new THREE.Mesh(new THREE.PlaneGeometry(1.28, zone.depth * 1.14), createHeatMaterial());
      heat.name = `${side}_${zone.key}_surface_heating_halo`;
      heat.rotation.x = -Math.PI / 2;
      heat.position.set(side === "left" ? -0.69 : 0.69, 0.552, zone.z);
      heat.userData = {
        isHeat: true,
        side,
        key: zone.key,
        target: 0,
        strength: 0,
        phase: zone.key === "waist" ? 0 : 0.31
      };
      heat.renderOrder = 24;
      bed.add(heat);
      heatZones.push(heat);
    });
  });
}

function zoneExportLabel(key) {
  return key.charAt(0).toUpperCase() + key.slice(1);
}

function cloneRuntimeMaterial(mesh) {
  if (!mesh.material) return;
  mesh.material = Array.isArray(mesh.material)
    ? mesh.material[0].clone()
    : mesh.material.clone();
  mesh.userData.baseOpacity = mesh.material.opacity ?? 1;
}

function assignRuntimeMaterial(mesh, material) {
  mesh.material = material;
  mesh.userData.baseOpacity = material.opacity ?? 1;
  mesh.material.needsUpdate = true;
}

function makeRuntimeFabricMaterial(color, options = {}) {
  const material = matOuterCover.clone();
  material.color.set(color);
  material.opacity = options.opacity ?? 1;
  material.roughness = options.roughness ?? 0.88;
  material.metalness = options.metalness ?? 0;
  material.transparent = options.transparent ?? true;
  material.depthWrite = options.depthWrite ?? true;
  if (material.transmission !== undefined) material.transmission = 0;
  if (material.thickness !== undefined) material.thickness = 0.12;
  material.emissive.set(options.emissive ?? 0x020812);
  material.emissiveIntensity = options.emissiveIntensity ?? 0;
  material.map = fabricTexture;
  return material;
}

function makeRuntimeBasicMaterial(color, opacity) {
  return new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity,
    depthWrite: false
  });
}

function isExportedSurfaceThread(mesh) {
  return mesh.name.startsWith("top_cross_thread_")
    || mesh.name.startsWith("top_length_thread_")
    || mesh.name.startsWith("subtle_diagonal_fabric_grain_");
}

function configureGlbMesh(mesh) {
  cloneRuntimeMaterial(mesh);
  if (mesh.name === "Bed_Frame_Platform") {
    mesh.scale.x *= 2.96 / 3.2;
    mesh.scale.z *= 4.06 / 4.32;
    mesh.position.z = 0.08;
    const platformMat = matSide.clone();
    platformMat.color.set(0x09121f);
    platformMat.emissive.set(0x020914);
    platformMat.emissiveIntensity = 0.1;
    assignRuntimeMaterial(mesh, platformMat);
  } else if (mesh.name === "Bed_Frame_Headboard") {
    const headboardMat = matSide.clone();
    headboardMat.color.set(0x233149);
    headboardMat.emissive.set(0x040f20);
    headboardMat.emissiveIntensity = 0.14;
    assignRuntimeMaterial(mesh, headboardMat);
  } else if (mesh.name === "Bed_Frame_Left_Headboard_Wing" || mesh.name === "Bed_Frame_Right_Headboard_Wing") {
    const wingMat = matSide.clone();
    wingMat.color.set(0x2d3e58);
    wingMat.emissive.set(0x040f20);
    wingMat.emissiveIntensity = 0.14;
    assignRuntimeMaterial(mesh, wingMat);
  } else if (mesh.name === "Mattress_Lower_Body") {
    const lowerMat = matFabric.clone();
    lowerMat.color.set(0x20334a);
    lowerMat.emissive.set(0x061426);
    lowerMat.emissiveIntensity = 0.06;
    lowerMat.transparent = false;
    lowerMat.opacity = 1;
    lowerMat.depthWrite = true;
    assignRuntimeMaterial(mesh, lowerMat);
  } else if (mesh.name === "Pillow_Left" || mesh.name === "Pillow_Right") {
    const pillowMat = new THREE.MeshStandardMaterial({
      color: 0x7f97b2,
      roughness: 0.84,
      metalness: 0,
      emissive: 0x07182b,
      emissiveIntensity: 0.035,
      map: fabricTexture
    });
    assignRuntimeMaterial(mesh, pillowMat);
  } else if (mesh.name.startsWith("pillow_soft_dimple_")) {
    assignRuntimeMaterial(mesh, makeRuntimeBasicMaterial(0x17304f, 0.18));
  } else if (mesh.name.startsWith("pillow_subtle_seam_")) {
    assignRuntimeMaterial(mesh, makeRuntimeBasicMaterial(0xd4e8ff, 0.16));
  } else if (isExportedSurfaceThread(mesh)) {
    mesh.userData.forceHidden = true;
    mesh.visible = false;
    if (mesh.material) {
      mesh.material.transparent = true;
      mesh.material.opacity = 0;
      mesh.material.depthWrite = false;
    }
  }
  const role = mesh.userData.smartMattressRole;
  if (role === "supportLayer") {
    mesh.userData.isInternalSupport = true;
    const supportMat = matFabric.clone();
    supportMat.color.set(0x25364a);
    supportMat.emissive.set(0x081b30);
    assignRuntimeMaterial(mesh, supportMat);
    mesh.material.transparent = true;
    mesh.material.opacity = 0;
    mesh.material.depthWrite = false;
    if (mesh.material.emissiveIntensity !== undefined) mesh.material.emissiveIntensity = 0;
  } else if (role === "revealCover") {
    mesh.userData.isCover = true;
    mesh.material = matCover.clone();
    mesh.visible = false;
    mesh.renderOrder = 6;
  } else if (role === "airBladder") {
    mesh.userData.isBladder = true;
    mesh.material = matBladder.clone();
    mesh.userData.baseColor = new THREE.Color(0x073775);
    mesh.renderOrder = 4;
  } else if (role === "bladderAura") {
    mesh.userData.isAura = true;
    mesh.material = matBladderAura.clone();
    mesh.renderOrder = 3;
  } else if (role === "bladderRim") {
    mesh.userData.isBladderRim = true;
    mesh.material = matBladderRim.clone();
    mesh.renderOrder = 5;
  } else if (role === "heatingSurface" || role === "heatingReference") {
    mesh.visible = false;
  } else if (role === "outerCover" || role === "topFabric" || mesh.name.startsWith("Mattress_Edge_Piping")) {
    if (mesh.name.startsWith("Mattress_Edge_Piping")) {
      mesh.userData.isPiping = true;
      assignRuntimeMaterial(mesh, makeRuntimeBasicMaterial(0xd2e8ff, 0.12));
      mesh.renderOrder = 12;
    } else if (role === "outerCover") {
      assignRuntimeMaterial(mesh, makeRuntimeFabricMaterial(0x23364d, { roughness: 0.86 }));
      mesh.userData.sideWall = mesh.userData.side === "left" || mesh.userData.side === "right";
      mesh.userData.reveal = 0;
      mesh.renderOrder = 3;
      if (mesh.userData.sideWall) sideWalls.push(mesh);
    } else if (role === "topFabric" && (mesh.userData.side === "left" || mesh.userData.side === "right")) {
      assignRuntimeMaterial(mesh, makeRuntimeFabricMaterial(0x31485f, { roughness: 0.88 }));
      mesh.userData.topSurface = true;
      mesh.userData.reveal = 0;
      mesh.renderOrder = 7;
      topSurfaces.push(mesh);
    } else if (role === "topFabric") {
      assignRuntimeMaterial(mesh, makeRuntimeFabricMaterial(0x30475f, { roughness: 0.86 }));
      mesh.renderOrder = 6;
    }
  }
}

function bindGlbMattressModel(root) {
  outerCover = root.getObjectByName("Mattress_Outer_Cover_Shell");
  if (!outerCover) throw new Error("GLB 缺少 Mattress_Outer_Cover_Shell 节点");

  root.traverse((object) => {
    if (object.isMesh) configureGlbMesh(object);
  });

  zones.forEach((zone, index) => {
    ["left", "right"].forEach((side) => {
      const sideLabel = side === "left" ? "Left" : "Right";
      const zoneRoot = root.getObjectByName(`${sideLabel}_${zoneExportLabel(zone.key)}_Zone`);
      if (!zoneRoot) throw new Error(`GLB 缺少 ${sideLabel}_${zoneExportLabel(zone.key)}_Zone 节点`);
      zoneRoot.userData = {
        ...zoneRoot.userData,
        side,
        key: zone.key,
        name: zone.name,
        index,
        phase: index * 0.19 + (side === "left" ? 0 : 0.11),
        current: { pressure: 0.18, glow: 0 },
        target: { pressure: 0.18, glow: 0 },
        reveal: 0
      };
      zoneRoot.traverse((child) => {
        if (!child.isMesh) return;
        if (child.userData.isBladder) {
          child.userData.phase = index * 0.42 + (side === "left" ? 0 : 0.28);
        }
      });

      const label = makeLabel(zone.name);
      label.position.set(0, 0.36, -0.02);
      label.visible = index < 5;
      zoneRoot.add(label);
      labels.push(label);
      zoneMeshes.push(zoneRoot);
    });
  });
}

async function loadGlbMattressModel() {
  const loader = new GLTFLoader();
  const gltf = await loader.loadAsync(glbModelUrl);
  glbModelRoot = gltf.scene.getObjectByName("SmartMattress3D_GLBReplica") || gltf.scene;
  bed.add(glbModelRoot);
  bindGlbMattressModel(glbModelRoot);
}

function createGlbRuntimeOverlays() {
  topSheen = addMesh(
    bed,
    roundedBox(2.48, 0.012, 3.42, 0.12, 5),
    new THREE.MeshBasicMaterial({
      color: 0x7dcaff,
      transparent: true,
      opacity: 0,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    }),
    [0, 0.51, 0.06]
  );
  topSheen.name = "soft_translucent_top_surface";
  topSheen.visible = false;
  topSheen.renderOrder = 9;

  zones.forEach((zone) => {
    ["left", "right"].forEach((side) => {
      const sliceMat = matOuterCover.clone();
      sliceMat.color.set(0x314860);
      sliceMat.opacity = 0;
      sliceMat.transmission = 0;
      sliceMat.depthWrite = false;
      sliceMat.roughness = 0.88;
      sliceMat.emissiveIntensity = 0;
      const slice = addMesh(
        bed,
        roundedBox(1.38, 0.07, zone.depth * 1.04, 0.1, 5),
        sliceMat,
        [side === "left" ? -0.69 : 0.69, 0.505, zone.z]
      );
      slice.name = `${side}_${zone.key}_realistic_fabric_slice`;
      slice.userData.coverSlice = true;
      slice.userData.key = zone.key;
      slice.userData.side = side;
      slice.userData.zStart = zone.z - zone.depth * 0.5;
      slice.userData.zEnd = zone.z + zone.depth * 0.5;
      slice.userData.reveal = 0;
      slice.visible = false;
      slice.renderOrder = 8;
      coverSlices.push(slice);
    });
  });

  zones.filter((zone) => zone.key === "waist" || zone.key === "leg").forEach((zone) => {
    ["left", "right"].forEach((side) => {
      const heat = new THREE.Mesh(new THREE.PlaneGeometry(1.28, zone.depth * 1.14), createHeatMaterial());
      heat.name = `${side}_${zone.key}_surface_heating_halo`;
      heat.rotation.x = -Math.PI / 2;
      heat.position.set(side === "left" ? -0.69 : 0.69, 0.552, zone.z);
      heat.userData = {
        isHeat: true,
        side,
        key: zone.key,
        target: 0,
        strength: 0,
        phase: zone.key === "waist" ? 0 : 0.31
      };
      heat.renderOrder = 24;
      bed.add(heat);
      heatZones.push(heat);
    });
  });

  const seamMat = new THREE.MeshBasicMaterial({ color: 0xb7dcff, transparent: true, opacity: 0.12, blending: THREE.AdditiveBlending, depthWrite: false });
  const centerSeam = addMesh(bed, new THREE.BoxGeometry(0.012, 0.012, 3.24), seamMat.clone(), [0, 0.43, 0.06]);
  centerSeam.userData.revealLine = true;
  zones.slice(0, -1).forEach((zone) => {
    const seam = addMesh(bed, new THREE.BoxGeometry(2.45, 0.01, 0.012), seamMat.clone(), [0, 0.435, zone.z + zone.depth * 0.5]);
    seam.userData.revealLine = true;
  });

  scanFrame = createScanFrame();
  bed.add(scanFrame);

  scanWash = addMesh(
    bed,
    new THREE.PlaneGeometry(2.78, 0.38),
    new THREE.MeshBasicMaterial({
      color: 0x79dfff,
      transparent: true,
      opacity: 0,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide
    }),
    [0, 0.555, scanStartZ],
    [-Math.PI / 2, 0, 0]
  );
  scanWash.name = "wide_scan_transparency_wash";
  scanWash.userData.scan = true;
  scanWash.visible = false;
}

const zones = [
  { key: "shoulder", name: "肩部", z: -1.16, depth: 0.58 },
  { key: "back", name: "背部", z: -0.55, depth: 0.58 },
  { key: "waist", name: "腰部", z: 0.05, depth: 0.58 },
  { key: "hip", name: "臀部", z: 0.66, depth: 0.58 },
  { key: "leg", name: "腿部", z: 1.28, depth: 0.66 }
];
const manualBladderControl = {
  left: Object.fromEntries(zones.map((zone) => [zone.key, false])),
  right: Object.fromEntries(zones.map((zone) => [zone.key, false]))
};
const manualBladderMode = {
  left: Object.fromEntries(zones.map((zone) => [zone.key, null])),
  right: Object.fromEntries(zones.map((zone) => [zone.key, null]))
};

function createMattressZones() {
  const halfWidth = 1.24;
  zones.forEach((zone, index) => {
    ["left", "right"].forEach((side) => {
      const root = new THREE.Group();
      root.name = `${side}-${zone.key}`;
      root.userData = {
        side,
        key: zone.key,
        name: zone.name,
        index,
        phase: index * 0.19 + (side === "left" ? 0 : 0.11),
        current: { pressure: 0.18, glow: 0 },
        target: { pressure: 0.18, glow: 0 },
        reveal: 0
      };
      root.position.set(side === "left" ? -0.64 : 0.64, 0.2, zone.z);

      const lower = addMesh(root, roundedBox(halfWidth, 0.08, zone.depth, 0.08), matFabric.clone(), [0, 0.02, 0]);
      lower.name = `${side}_${zone.key}_support_layer`;
      lower.material.emissive = new THREE.Color(0x081b30);
      lower.material.transparent = true;
      lower.material.opacity = 0;
      lower.userData.isInternalSupport = true;

      const cover = addMesh(root, roundedBox(halfWidth * 0.9, 0.03, zone.depth * 0.86, 0.08), matCover.clone(), [0, 0.185, 0]);
      cover.name = `${side}_${zone.key}_transparent_mattress_cover`;
      cover.userData.isCover = true;
      cover.visible = false;
      cover.renderOrder = 6;

      const highlight = addMesh(root, roundedBox(halfWidth * 0.74, 0.012, zone.depth * 0.66, 0.065), matActive.clone(), [0, 0.188, 0]);
      highlight.name = `${side}_${zone.key}_pressure_glow`;
      highlight.userData.isOverlay = true;
      highlight.visible = false;
      highlight.renderOrder = 7;

      const sideFace = addMesh(root, roundedBox(halfWidth, 0.08, 0.02, 0.02), matSide.clone(), [0, -0.13, zone.depth * 0.52]);
      sideFace.name = `${side}_${zone.key}_front_side`;
      sideFace.material.transparent = true;
      sideFace.material.opacity = 0;
      sideFace.userData.isInternalSupport = true;

      const bladder = addMesh(root, roundedBox(halfWidth * 0.74, 0.055, zone.depth * 0.66, 0.08, 6), matBladder.clone(), [0, 0.115, 0], [0, 0, 0]);
      bladder.name = `${side}_${zone.key}_single_large_air_bladder`;
      bladder.userData.isBladder = true;
      bladder.userData.baseColor = new THREE.Color(0x073775);
      bladder.userData.phase = index * 0.42 + (side === "left" ? 0 : 0.28);
      bladder.renderOrder = 4;

      const bladderAura = addMesh(root, roundedBox(halfWidth * 0.79, 0.072, zone.depth * 0.7, 0.1, 7), matBladderAura.clone(), [0, 0.118, 0], [0, 0, 0]);
      bladderAura.name = `${side}_${zone.key}_breathing_light_aura`;
      bladderAura.userData.isAura = true;
      bladderAura.renderOrder = 3;

      const bladderRim = addMesh(root, roundedBox(halfWidth * 0.765, 0.064, zone.depth * 0.685, 0.095, 7), matBladderRim.clone(), [0, 0.119, 0], [0, 0, 0]);
      bladderRim.name = `${side}_${zone.key}_inner_edge_light`;
      bladderRim.userData.isBladderRim = true;
      bladderRim.renderOrder = 5;

      const label = makeLabel(zone.name);
      label.position.set(0, 0.36, -0.02);
      label.visible = index < 5;
      root.add(label);
      labels.push(label);

      bed.add(root);
      zoneMeshes.push(root);
    });
  });

  const seamMat = new THREE.MeshBasicMaterial({ color: 0xb7dcff, transparent: true, opacity: 0.12, blending: THREE.AdditiveBlending, depthWrite: false });
  const centerSeam = addMesh(bed, new THREE.BoxGeometry(0.012, 0.012, 3.24), seamMat.clone(), [0, 0.43, 0.06]);
  centerSeam.userData.revealLine = true;
  zones.slice(0, -1).forEach((zone) => {
    const seam = addMesh(bed, new THREE.BoxGeometry(2.45, 0.01, 0.012), seamMat.clone(), [0, 0.435, zone.z + zone.depth * 0.5]);
    seam.userData.revealLine = true;
  });

  scanFrame = createScanFrame();
  bed.add(scanFrame);

  scanWash = addMesh(
    bed,
    new THREE.PlaneGeometry(2.78, 0.38),
    new THREE.MeshBasicMaterial({
      color: 0x79dfff,
      transparent: true,
      opacity: 0,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      side: THREE.DoubleSide
    }),
    [0, 0.555, scanStartZ],
    [-Math.PI / 2, 0, 0]
  );
  scanWash.name = "wide_scan_transparency_wash";
  scanWash.userData.scan = true;
  scanWash.visible = false;
}

const modes = {
  auto: {
    label: "AUTO",
    reveal: true,
    subtitle: "左右气囊联动微调，床垫表面保持稳定承托",
    status: "检测到人体存在，分区智能调节中",
    values: { shoulder: 48, back: 64, waist: 82, hip: 58, leg: 42 },
    targets: {
      shoulder: { pressure: 0.38, glow: 0.35 },
      back: { pressure: 0.58, glow: 0.62 },
      waist: { pressure: 0.86, glow: 1 },
      hip: { pressure: 0.52, glow: 0.48 },
      leg: { pressure: 0.32, glow: 0.35 }
    }
  },
  zero: {
    label: "ZERO",
    reveal: true,
    subtitle: "气囊按波浪节奏充放气，形成柔和释压按摩",
    status: "气囊释压按摩运行中，压力波从肩部流向腿部",
    values: { shoulder: 78, back: 88, waist: 62, hip: 68, leg: 86 },
    targets: {
      shoulder: { pressure: 0.78, glow: 0.9 },
      back: { pressure: 0.88, glow: 0.78 },
      waist: { pressure: 0.56, glow: 0.45 },
      hip: { pressure: 0.64, glow: 0.52 },
      leg: { pressure: 0.82, glow: 0.92 }
    }
  },
  left: {
    label: "LEFT",
    reveal: true,
    subtitle: "左侧独立调节，右侧保持稳定承托",
    status: "左侧智能调节中，右侧进入低扰动保护",
    values: { shoulder: 56, back: 84, waist: 92, hip: 64, leg: 46 },
    side: "left",
    targets: {
      shoulder: { pressure: 0.46, glow: 0.42 },
      back: { pressure: 0.82, glow: 0.86 },
      waist: { pressure: 0.96, glow: 1 },
      hip: { pressure: 0.6, glow: 0.62 },
      leg: { pressure: 0.34, glow: 0.35 }
    }
  },
  right: {
    label: "RIGHT",
    reveal: true,
    subtitle: "右侧独立调节，左侧保持稳定承托",
    status: "右侧智能调节中，左侧进入低扰动保护",
    values: { shoulder: 54, back: 82, waist: 90, hip: 66, leg: 48 },
    side: "right",
    targets: {
      shoulder: { pressure: 0.44, glow: 0.42 },
      back: { pressure: 0.8, glow: 0.86 },
      waist: { pressure: 0.94, glow: 1 },
      hip: { pressure: 0.62, glow: 0.62 },
      leg: { pressure: 0.36, glow: 0.35 }
    }
  },
  deep: {
    label: "DEEP",
    reveal: true,
    subtitle: "腰臀区域增强承托，呼吸与心率保持低波动",
    status: "深睡承托模式运行中，腰臀分区缓慢释压",
    values: { shoulder: 38, back: 58, waist: 88, hip: 82, leg: 44 },
    warning: "hip",
    targets: {
      shoulder: { pressure: 0.22, glow: 0.18 },
      back: { pressure: 0.5, glow: 0.44 },
      waist: { pressure: 0.9, glow: 0.96 },
      hip: { pressure: 0.84, glow: 0.86 },
      leg: { pressure: 0.3, glow: 0.28 }
    }
  },
  flat: {
    label: "FLAT",
    reveal: false,
    subtitle: "床垫恢复平躺，系统持续监测体压变化",
    status: "智能监测模式，当前无主动调节",
    values: { shoulder: 32, back: 34, waist: 36, hip: 34, leg: 31 },
    targets: {
      shoulder: { pressure: 0.16, glow: 0.12 },
      back: { pressure: 0.18, glow: 0.12 },
      waist: { pressure: 0.2, glow: 0.12 },
      hip: { pressure: 0.18, glow: 0.12 },
      leg: { pressure: 0.16, glow: 0.12 }
    }
  }
};

let currentMode = "auto";
let hovered;

function applyZoneTargets(config, coolDown = false) {
  const targetConfig = coolDown ? modes.flat : config;
  zoneMeshes.forEach((root) => {
    const key = root.userData.key;
    const activeSide = coolDown || !config.side || config.side === root.userData.side;
    const target = targetConfig.targets[key];
    root.userData.target = activeSide
      ? { ...target }
      : { pressure: 0.14 + target.pressure * 0.08, glow: 0.1 };
    root.userData.warning = !coolDown && config.warning === key && activeSide;
  });
}

function getZoneEnvelope(localProgress) {
  const p = THREE.MathUtils.clamp(localProgress, 0, 1);
  if (p < 0.24) return p / 0.24;
  if (p > 0.76) return (1 - p) / 0.24;
  return 1;
}

function updateSequentialAdjustment(config, elapsed, side = focusSide, updateUi = true) {
  const sequenceElapsed = elapsed - cameraTiming.moveToSide;
  const zoneIndex = THREE.MathUtils.clamp(Math.floor(sequenceElapsed / cameraTiming.zoneDuration), 0, zones.length - 1);
  const localProgress = THREE.MathUtils.clamp((sequenceElapsed - zoneIndex * cameraTiming.zoneDuration) / cameraTiming.zoneDuration, 0, 1);
  const envelope = getZoneEnvelope(localProgress);
  if (updateUi) activeZoneIndex = zoneIndex;

  if (updateUi && displayedZoneIndex !== zoneIndex) {
    displayedZoneIndex = zoneIndex;
    const values = { ...modes.flat.values };
    values[zones[zoneIndex].key] = Math.min(96, Math.round((config.values[zones[zoneIndex].key] ?? 70) + 12));
    updateBars(values);
    document.querySelector("#statusText").textContent = `${zones[zoneIndex].name}气囊调节中，高亮呼吸灯循环展示`;
  }

  zoneMeshes.forEach((root) => {
    if (root.userData.side !== side) return;
    const key = root.userData.key;
    const base = modes.flat.targets[key];
    const target = config.targets[key];
    const isCurrentZone = root.userData.index === zoneIndex;
    const sideStrength = 1;
    const intensity = isCurrentZone ? envelope * sideStrength : 0;
    const stableInflate = 0.46 + Math.min(0.16, target.pressure * 0.08);
    const boostedGlow = Math.min(1, 0.88 + target.glow * 0.16);
    root.userData.sequenceEnvelope = intensity;
    root.userData.target = {
      pressure: THREE.MathUtils.lerp(base.pressure * 0.78, stableInflate, intensity),
      glow: THREE.MathUtils.lerp(0.06, boostedGlow, intensity)
    };
    root.userData.warning = config.warning === key && isCurrentZone && sideStrength > 0.8;
  });
}

function resetRevealProgress() {
  sideRevealTarget.left = 0;
  sideRevealTarget.right = 0;
  sideScanProgress.left = 1;
  sideScanProgress.right = 1;
  ["left", "right"].forEach((side) => {
    sideAdjustment[side].active = false;
    sideAdjustment[side].start = -1;
    sideAdjustment[side].config = null;
    sideAdjustment[side].done = true;
    sideScanControl[side].active = false;
    Object.keys(manualBladderControl[side]).forEach((zone) => {
      manualBladderControl[side][zone] = false;
      manualBladderMode[side][zone] = null;
    });
  });
  zoneMeshes.forEach((root) => {
    root.userData.reveal = 0;
    root.userData.sequenceEnvelope = 0;
  });
  coverSlices.forEach((slice) => {
    slice.userData.reveal = 0;
  });
  sideWalls.forEach((wall) => {
    wall.userData.reveal = 0;
  });
}

function updateHeatButtons() {
  let activeCount = 0;
  document.querySelectorAll("button[data-heat-side]").forEach((button) => {
    const side = button.dataset.heatSide;
    const zone = button.dataset.heatZone;
    const active = heatState[side]?.[zone] === true;
    if (active) activeCount += 1;
    button.classList.toggle("active", active);
  });
  document.querySelector("#heatSummary").textContent = activeCount > 0 ? `${activeCount} ON` : "OFF";
}

function toggleHeat(side, zone) {
  if (!heatState[side] || heatState[side][zone] === undefined) return;
  heatState[side][zone] = !heatState[side][zone];
  updateHeatButtons();
  const sideName = side === "left" ? "左侧" : "右侧";
  const zoneName = zone === "waist" ? "腰部" : "腿部";
  document.querySelector("#statusText").textContent = heatState[side][zone]
    ? `${sideName}${zoneName}表层加热已开启，温控光效与调节动画叠加`
    : `${sideName}${zoneName}表层加热已关闭`;
  requestRender(settleTiming.heat);
  postAppEvent("heat", { side, zone, enabled: heatState[side][zone] });
  return heatState[side][zone];
}

function setHeat(side, zone, enabled = true) {
  if (!heatState[side] || heatState[side][zone] === undefined) return false;
  heatState[side][zone] = Boolean(enabled);
  updateHeatButtons();
  requestRender(settleTiming.heat);
  postAppEvent("heat", { side, zone, enabled: heatState[side][zone] });
  return heatState[side][zone];
}

function setHeating(nextHeating = {}) {
  ["left", "right"].forEach((side) => {
    ["waist", "leg"].forEach((zone) => {
      if (nextHeating[side]?.[zone] !== undefined) {
        heatState[side][zone] = Boolean(nextHeating[side][zone]);
      }
    });
  });
  updateHeatButtons();
  requestRender(settleTiming.heat);
  postAppEvent("heating", { heating: JSON.parse(JSON.stringify(heatState)) });
  return getPublicState().heating;
}

function isValidSide(side) {
  return side === "left" || side === "right";
}

function isValidZone(zone) {
  return zones.some((item) => item.key === zone);
}

function focusCameraStart(nextSide) {
  const previousFocusSide = focusSide;
  focusSide = nextSide;
  autoCameraPausedUntil = 0;
  cameraMoveStart.copy(camera.position);
  targetMoveStart.copy(controls.target);
  cameraPath = adjustmentSequenceActive && previousFocusSide !== nextSide ? "sideToSide" : "direct";
  cameraArcDirection = previousFocusSide === "left" && nextSide === "right" ? -1 : 1;
  cameraPhase = "moveToSide";
  return previousFocusSide;
}

function getModeSides(config) {
  return config.side ? [config.side] : ["left", "right"];
}

function startSideRevealTimeline(side, options = {}) {
  if (!isValidSide(side)) return false;
  sideRevealTarget[side] = 1;
  sideScanProgress[side] = 0;
  sideScanControl[side].active = options.manualScan === true;
  sideScanControl[side].start = performance.now();
  sideScanControl[side].duration = Math.max(300, Number(options.duration) || cameraTiming.scanDuration);
  targetReveal = 1;
  requestRender(sideScanControl[side].duration + settleTiming.reveal);
  return true;
}

function stopSideRevealTimeline(side) {
  if (!isValidSide(side)) return false;
  sideRevealTarget[side] = 0;
  sideScanControl[side].active = false;
  if (!sideRevealTarget.left && !sideRevealTarget.right) targetReveal = 0;
  requestRender(settleTiming.reveal);
  return true;
}

function startBladderSequenceTimeline(side, config, options = {}) {
  if (!isValidSide(side) || !config) return false;
  const now = Number(options.startTime) || performance.now();
  sideAdjustment[side].active = true;
  sideAdjustment[side].start = now;
  sideAdjustment[side].config = config;
  sideAdjustment[side].done = false;
  requestRender(cameraTiming.returnOverview + settleTiming.reveal);
  return true;
}

function stopBladderSequenceTimeline(side, options = {}) {
  if (!isValidSide(side)) return false;
  sideAdjustment[side].active = false;
  sideAdjustment[side].start = -1;
  sideAdjustment[side].config = null;
  sideAdjustment[side].done = true;
  zoneMeshes.forEach((root) => {
    if (root.userData.side === side) root.userData.sequenceEnvelope = 0;
  });
  if (options.clearManual !== false) {
    Object.keys(manualBladderControl[side]).forEach((zone) => {
      manualBladderControl[side][zone] = false;
      manualBladderMode[side][zone] = null;
    });
  }
  requestRender(settleTiming.reveal);
  return true;
}

function hasActiveSideAdjustment() {
  return sideAdjustment.left.active || sideAdjustment.right.active;
}

function hasActiveManualBladder(side) {
  if (side) return Object.values(manualBladderControl[side]).some(Boolean);
  return Object.values(manualBladderControl.left).some(Boolean) || Object.values(manualBladderControl.right).some(Boolean);
}

function refreshGlobalRevealTarget() {
  targetReveal = sideRevealTarget.left || sideRevealTarget.right ? 1 : 0;
}

function startComposedAdjustment(side, config, options = {}) {
  if (!isValidSide(side) || !config) return false;
  const now = Number(options.startTime) || performance.now();
  if (options.camera !== false) focusCameraStart(side);
  cameraManualHoldPhase = "sideHold";
  startSideRevealTimeline(side, { duration: options.scanDuration, manualScan: false });
  startBladderSequenceTimeline(side, config, { startTime: now });
  adjustmentSequenceStart = now;
  adjustmentSequenceActive = true;
  visualReturnStarted = false;
  visualReturnStart = -1;
  activeZoneIndex = -1;
  displayedZoneIndex = -2;
  scanProgress = 0;
  return true;
}

function stopComposedAdjustment(side, options = {}) {
  if (!isValidSide(side)) return false;
  stopBladderSequenceTimeline(side, { clearManual: options.clearManual });
  if (options.keepReveal === true || hasActiveManualBladder(side)) {
    sideRevealTarget[side] = 1;
  } else {
    stopSideRevealTimeline(side);
  }
  if (!hasActiveSideAdjustment()) {
    visualReturnStarted = true;
    visualReturnStart = performance.now();
    adjustmentSequenceActive = !hasActiveManualBladder();
    refreshGlobalRevealTarget();
    cameraPhase = options.returnOverview === false ? "sideHold" : "returnOverview";
    applyZoneTargets(modes[currentMode] || modes.flat, true);
  }
  return true;
}

function startSideAdjustment(side, mode = side, options = {}) {
  if (!isValidSide(side)) return false;
  const config = modes[mode] || modes[side] || modes.right;
  if (options.updateMode !== false) currentMode = mode in modes ? mode : side;
  startComposedAdjustment(side, config, options);
  applyZoneTargets(config, false);
  postAppEvent("adjustment", { action: "startSide", side, mode: currentMode });
  return true;
}

function stopSideAdjustment(side, options = {}) {
  if (!isValidSide(side)) return false;
  stopComposedAdjustment(side, options);
  postAppEvent("adjustment", { action: "stopSide", side });
  return true;
}

function setBladderAnimation(side, zone, enabled = true, options = {}) {
  if (!isValidSide(side) || !isValidZone(zone)) return false;
  manualBladderControl[side][zone] = Boolean(enabled);
  manualBladderMode[side][zone] = enabled ? (modes[options.mode] ? options.mode : side) : null;
  if (enabled) {
    sideRevealTarget[side] = Math.max(sideRevealTarget[side], 1);
    sideScanProgress[side] = 1;
    targetReveal = 1;
  } else if (!sideAdjustment[side].active && !Object.values(manualBladderControl[side]).some(Boolean)) {
    sideRevealTarget[side] = 0;
    if (!sideAdjustment.left.active && !sideAdjustment.right.active && !Object.values(manualBladderControl.left).some(Boolean) && !Object.values(manualBladderControl.right).some(Boolean)) {
      targetReveal = 0;
    }
  }
  zoneMeshes.forEach((root) => {
    if (root.userData.side === side && root.userData.key === zone && !enabled) {
      root.userData.target = { ...modes.flat.targets[zone] };
      root.userData.sequenceEnvelope = 0;
    }
  });
  requestRender(settleTiming.reveal);
  postAppEvent("bladder", { side, zone, enabled: manualBladderControl[side][zone] });
  return manualBladderControl[side][zone];
}

function startBladder(side, zone) {
  return setBladderAnimation(side, zone, true, arguments[2] || {});
}

function stopBladder(side, zone) {
  return setBladderAnimation(side, zone, false);
}

function startReveal(side, options = {}) {
  if (!isValidSide(side)) return false;
  startSideRevealTimeline(side, { ...options, manualScan: true });
  postAppEvent("reveal", { action: "start", side, duration: sideScanControl[side].duration });
  return true;
}

function stopReveal(side) {
  if (!isValidSide(side)) return false;
  stopSideRevealTimeline(side);
  postAppEvent("reveal", { action: "stop", side });
  return true;
}

function getSideCameraPose(side) {
  const sideSign = side === "left" ? -1 : 1;
  const target = new THREE.Vector3(sideSign * 0.72, 0.38, 0.14);
  const position = isIOSNativeEmbed
    ? new THREE.Vector3(sideSign * 5.42, 2.84, target.z)
    : new THREE.Vector3(sideSign * 4.35, 2.48, target.z);
  return { position, target };
}

function startCameraTransition(position, target, options = {}) {
  autoCameraPausedUntil = 0;
  manualCamera.active = true;
  manualCamera.start = performance.now();
  manualCamera.duration = Math.max(300, Number(options.duration) || 1800);
  manualCamera.endPhase = options.endPhase || cameraPhase;
  manualCamera.fromPosition.copy(camera.position);
  manualCamera.fromTarget.copy(controls.target);
  manualCamera.toPosition.copy(position);
  manualCamera.toTarget.copy(target);
  manualCamera.path = options.path || "direct";
  manualCamera.arcDirection = Number(options.arcDirection) || 1;
  cameraManualHoldPhase = manualCamera.endPhase;
  requestRender(manualCamera.duration + settleTiming.camera);
  postAppEvent("camera", { action: "transition", duration: manualCamera.duration, endPhase: manualCamera.endPhase });
  return true;
}

function moveCameraToSide(side, options = {}) {
  if (!isValidSide(side)) return false;
  const previousFocusSide = focusSide;
  focusSide = side;
  const pose = getSideCameraPose(side);
  cameraPhase = "sideHold";
  cameraManualHoldPhase = "sideHold";
  const arcDirection = previousFocusSide === "left" && side === "right" ? -1 : 1;
  return startCameraTransition(pose.position, pose.target, { endPhase: "sideHold", arcDirection, ...options });
}

function moveCameraToOverview(options = {}) {
  cameraPhase = "overview";
  cameraManualHoldPhase = "overview";
  return startCameraTransition(overviewPosition, overviewTarget, { endPhase: "overview", ...options });
}

function startHeat(side, zone) {
  return setHeat(side, zone, true);
}

function stopHeat(side, zone) {
  return setHeat(side, zone, false);
}

function setMode(mode) {
  if (!modes[mode]) return false;
  currentMode = mode;
  const config = modes[mode];
  const targetSides = getModeSides(config);
  const nextFocusSide = config.side ?? "right";
  autoCameraPausedUntil = 0;
  if (config.reveal) {
    const activeSides = ["left", "right"].filter((side) => sideAdjustment[side].active);
    const switchingAdjustmentSide = activeSides.length > 0 && !activeSides.includes(nextFocusSide);
    if (!switchingAdjustmentSide) {
      resetRevealProgress();
      reveal = 0;
    }
    const now = performance.now();
    targetSides.forEach((side) => startComposedAdjustment(side, config, { startTime: now, camera: side === nextFocusSide }));
  } else {
    targetReveal = 0;
    stopSideRevealTimeline("left");
    stopSideRevealTimeline("right");
    sideScanProgress.left = 1;
    sideScanProgress.right = 1;
    ["left", "right"].forEach((side) => {
      stopBladderSequenceTimeline(side);
      sideScanControl[side].active = false;
    });
    adjustmentSequenceStart = -1;
    adjustmentSequenceActive = false;
    visualReturnStarted = true;
    activeZoneIndex = -1;
    displayedZoneIndex = -2;
    cameraPath = "direct";
    cameraPhase = "overview";
    cameraManualHoldPhase = "overview";
  }
  document.querySelectorAll("button[data-mode]").forEach((button) => {
    button.classList.toggle("active", button.dataset.mode === mode);
  });
  document.querySelector("#modeName").textContent = config.label;
  document.querySelector("#subtitle").textContent = config.subtitle;
  document.querySelector("#statusText").textContent = config.status;
  updateBars(config.values);
  applyZoneTargets(config, config.reveal);
  requestRender(config.reveal ? cameraTiming.returnOverview + settleTiming.reveal : settleTiming.reveal);
  postAppEvent("mode", { mode });
  return true;
}

const nativeOrbitOffset = new THREE.Vector3();
const nativeOrbitSpherical = new THREE.Spherical();
function rotateBy(deltaX, deltaY = 0) {
  autoCameraPausedUntil = performance.now() + 12000;
  nativeOrbitOffset.copy(camera.position).sub(controls.target);
  nativeOrbitSpherical.setFromVector3(nativeOrbitOffset);
  nativeOrbitSpherical.theta -= deltaX * 0.006;
  nativeOrbitSpherical.phi -= deltaY * 0.0048;
  nativeOrbitSpherical.phi = THREE.MathUtils.clamp(nativeOrbitSpherical.phi, 0.18, controls.maxPolarAngle);
  nativeOrbitOffset.setFromSpherical(nativeOrbitSpherical);
  camera.position.copy(controls.target).add(nativeOrbitOffset);
  controls.update();
  requestRender(settleTiming.hover);
  postAppEvent("camera", { action: "rotateBy", deltaX, deltaY });
}

function resetView(options = {}) {
  autoCameraPausedUntil = 0;
  cameraPhase = adjustmentSequenceActive ? cameraPhase : "overview";
  if (!adjustmentSequenceActive) {
    if (options.instant === true) {
      camera.position.copy(overviewPosition);
      controls.target.copy(overviewTarget);
      controls.update();
    } else {
      moveCameraToOverview({ duration: options.duration || 3000 });
    }
  }
  requestRender((Number(options.duration) || 3000) + settleTiming.reveal);
  postAppEvent("camera", { action: "resetView" });
}

function configureApp(options = {}) {
  appConfig = { ...appConfig, ...options };
  if (options.showUI !== undefined) setUIVisible(Boolean(options.showUI));
  if (options.embedded !== undefined) setUIVisible(!Boolean(options.embedded));
  if (options.heating) setHeating(options.heating);
  if (options.mode) setMode(options.mode);
  if (options.autorun === false && currentMode !== "flat") setMode("flat");
  requestRender(settleTiming.bootstrap);
  postAppEvent("configure", { config: { ...appConfig } });
  return getPublicState();
}

window.setMattressMode = setMode;
window.rotateMattressBy = rotateBy;
window.SmartMattress3D = {
  version: "1.2.2-glb-reveal-parity",
  configure: configureApp,
  setMode,
  startSideAdjustment,
  stopSideAdjustment,
  startBladder,
  stopBladder,
  setBladderAnimation,
  startReveal,
  stopReveal,
  moveCameraToSide,
  moveCameraToOverview,
  startCameraTransition,
  startHeat,
  stopHeat,
  setHeat,
  toggleHeat,
  setHeating,
  getState: getPublicState,
  setUIVisible,
  resetView,
  rotateBy
};

function updateBars(values) {
  const ids = {
    shoulder: ["barShoulder", "txtShoulder"],
    back: ["barBack", "txtBack"],
    waist: ["barWaist", "txtWaist"],
    hip: ["barHip", "txtHip"],
    leg: ["barLeg", "txtLeg"]
  };
  Object.entries(values).forEach(([key, value]) => {
    document.querySelector(`#${ids[key][0]}`).style.setProperty("--value", `${value}%`);
    document.querySelector(`#${ids[key][1]}`).textContent = `${value}%`;
  });
}

function updatePointer(event) {
  pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
  hoveredDirty = true;
  lastInteractionFrameTime = performance.now();
  requestRender(settleTiming.hover);
}

function handlePick(event) {
  updatePointer(event);
  raycaster.setFromCamera(pointer, camera);
  const hits = raycaster.intersectObjects(zoneMeshes, true);
  const hitRoot = hits[0]?.object?.parent;
  if (hitRoot?.userData?.key) {
    const sideName = hitRoot.userData.side === "left" ? "左侧" : "右侧";
    document.querySelector("#statusText").textContent = `${sideName}${hitRoot.userData.name}分区已选中，可映射到 App 业务弹窗`;
    postAppEvent("zonePick", {
      side: hitRoot.userData.side,
      zone: hitRoot.userData.key,
      name: hitRoot.userData.name
    });
  }
}

async function createScene() {
  createEnvironment();
  await loadGlbMattressModel();
  createGlbRuntimeOverlays();
  setMode("flat");
}

function finishAdjustmentVisuals() {
  sideRevealTarget.left = Object.values(manualBladderControl.left).some(Boolean) ? 1 : 0;
  sideRevealTarget.right = Object.values(manualBladderControl.right).some(Boolean) ? 1 : 0;
  targetReveal = sideRevealTarget.left || sideRevealTarget.right ? 1 : 0;
  activeZoneIndex = -1;
  displayedZoneIndex = -2;
  zoneMeshes.forEach((root) => {
    root.userData.sequenceEnvelope = 0;
  });
  applyZoneTargets(modes[currentMode], true);
  updateBars(modes.flat.values);
  document.querySelector("#statusText").textContent = "调节演示完成，床垫恢复整体俯视展示";
}

function animate(time) {
  const t = time * 0.001;
  animationFrameId = 0;
  const nowMs = performance.now();
  const sequenceElapsedMs = adjustmentSequenceActive ? nowMs - adjustmentSequenceStart : 0;
  const hasManualBladder = Object.values(manualBladderControl.left).some(Boolean) || Object.values(manualBladderControl.right).some(Boolean);

  ["left", "right"].forEach((side) => {
    const scanState = sideScanControl[side];
    if (!scanState.active) return;
    sideScanProgress[side] = THREE.MathUtils.clamp((nowMs - scanState.start) / scanState.duration, 0, 1);
    if (sideScanProgress[side] >= 1) scanState.active = false;
  });

  if (adjustmentSequenceActive) {
    const elapsed = sequenceElapsedMs;
    let activeSideCount = 0;
    let allSidesDone = true;
    ["left", "right"].forEach((side) => {
      const state = sideAdjustment[side];
      if (!state.active || !state.config) return;
      activeSideCount += 1;
      const sideElapsed = nowMs - state.start;
      sideScanProgress[side] = THREE.MathUtils.clamp(sideElapsed / cameraTiming.scanDuration, 0, 1);
      if (sideElapsed < cameraTiming.sideHold) {
        allSidesDone = false;
        updateSequentialAdjustment(state.config, sideElapsed, side, side === focusSide);
      } else {
        state.done = true;
        sideScanProgress[side] = 1;
        zoneMeshes.forEach((root) => {
          if (root.userData.side === side) root.userData.sequenceEnvelope = 0;
        });
      }
    });
    if (elapsed < cameraTiming.moveToSide) {
      cameraPhase = "moveToSide";
      if (!sideAdjustment[focusSide]?.active) activeZoneIndex = -1;
    } else if (!allSidesDone || !visualReturnStarted) {
      cameraPhase = "sideHold";
      if (allSidesDone && activeSideCount > 0) {
        visualReturnStarted = true;
        visualReturnStart = nowMs;
        finishAdjustmentVisuals();
      }
    } else if (nowMs - visualReturnStart < cameraTiming.returnOverview - cameraTiming.sideHold) {
      cameraPhase = "returnOverview";
    } else {
      cameraPhase = "overview";
      cameraManualHoldPhase = "overview";
      adjustmentSequenceActive = false;
      sideRevealTarget.left = Object.values(manualBladderControl.left).some(Boolean) ? 1 : 0;
      sideRevealTarget.right = Object.values(manualBladderControl.right).some(Boolean) ? 1 : 0;
      targetReveal = sideRevealTarget.left || sideRevealTarget.right ? 1 : 0;
      sideScanProgress.left = 1;
      sideScanProgress.right = 1;
      ["left", "right"].forEach((side) => {
        sideAdjustment[side].active = false;
        sideAdjustment[side].start = -1;
        sideAdjustment[side].config = null;
        sideAdjustment[side].done = true;
      });
      activeZoneIndex = -1;
      displayedZoneIndex = -2;
      zoneMeshes.forEach((root) => {
        root.userData.sequenceEnvelope = 0;
      });
      applyZoneTargets(modes[currentMode], true);
    }
  } else {
    cameraPhase = manualCamera.active ? cameraPhase : cameraManualHoldPhase;
    activeZoneIndex = -1;
    if (!hasManualBladder) {
      zoneMeshes.forEach((root) => {
        root.userData.sequenceEnvelope = 0;
      });
    }
  }

  if (adjustmentSequenceActive && targetReveal > 0) {
    scanProgress = THREE.MathUtils.clamp(sequenceElapsedMs / cameraTiming.scanDuration, 0, 1);
  } else if (sideScanControl.left.active || sideScanControl.right.active) {
    scanProgress = Math.min(sideScanProgress.left, sideScanProgress.right);
  } else if (targetReveal <= 0) {
    scanProgress = 1;
  }

  zoneMeshes.forEach((root) => {
    const { current, target } = root.userData;
    const zone = zones[root.userData.index];
    const sideProgress = sideScanProgress[root.userData.side] ?? 1;
    const scanZ = scanStartZ + sideProgress * scanRangeZ;
    const desiredReveal = sideRevealTarget[root.userData.side] > 0
      ? THREE.MathUtils.smoothstep(scanZ, zone.z - zone.depth * 0.58, zone.z + zone.depth * 0.18)
      : 0;
    root.userData.reveal += (desiredReveal - root.userData.reveal) * 0.06;
    const localReveal = root.userData.reveal;
    const sequenceEnvelope = root.userData.sequenceEnvelope ?? 0;
    const pulse = linearBreath(t, 4.8, root.userData.phase ?? 0);
    const manualEnvelope = manualBladderControl[root.userData.side]?.[root.userData.key] ? 1 : 0;
    const combinedEnvelope = Math.max(sequenceEnvelope, manualEnvelope);
    const lightAmount = combinedEnvelope * (0.24 + pulse * 0.76);
    const followRate = combinedEnvelope > 0.02 || root.userData.index === activeZoneIndex ? 0.085 : 0.035;
    if (manualEnvelope > sequenceEnvelope) {
      const manualMode = manualBladderMode[root.userData.side]?.[root.userData.key] || root.userData.side;
      const manualTarget = modes[manualMode]?.targets[root.userData.key] || modes[root.userData.side]?.targets[root.userData.key] || modes.right.targets[root.userData.key];
      root.userData.target = {
        pressure: THREE.MathUtils.lerp(modes.flat.targets[root.userData.key].pressure, manualTarget.pressure, 0.92),
        glow: THREE.MathUtils.lerp(0.06, manualTarget.glow, 0.92)
      };
      root.userData.warning = modes[manualMode]?.warning === root.userData.key;
    }
    current.pressure += (target.pressure - current.pressure) * followRate;
    current.glow += (target.glow - current.glow) * followRate;
    root.position.y = 0.2;
    root.rotation.x = 0;

    root.traverse((child) => {
      if (!child.isMesh) return;
      if (child.userData.isOverlay) {
        child.visible = false;
      } else if (child.userData.isCover) {
        child.visible = false;
      } else if (child.userData.isBladder) {
        const activeTint = root.userData.warning ? palette.pink : palette.cyan;
        const baseTint = root.userData.warning ? palette.pink : palette.blue;
        const scaleY = THREE.MathUtils.clamp(1.035 + lightAmount * 0.07, 1.02, 1.12);
        const halfHeight = 0.0275 * scaleY;
        const internalCeiling = 0.285;
        child.position.y = Math.min(0.112 + lightAmount * 0.009, internalCeiling - halfHeight);
        child.scale.y = scaleY;
        child.scale.x = 0.99 + lightAmount * 0.045;
        child.scale.z = 0.99 + lightAmount * 0.052;
        tmpColor.lerpColors(baseTint, activeTint, 0.22 + lightAmount * 0.78);
        child.material.color.copy(tmpColor);
        child.material.opacity = localReveal * (0.16 + sequenceEnvelope * 0.12 + lightAmount * 0.46 + (hovered === root ? 0.035 : 0));
        child.material.emissive.copy(root.userData.warning ? palette.pink : palette.ice);
        child.material.emissiveIntensity = localReveal * (0.12 + lightAmount * 2.35);
      } else if (child.userData.isAura) {
        child.visible = localReveal > 0.04;
        child.material.color.copy(root.userData.warning ? palette.pink : palette.cyan);
        child.material.opacity = localReveal * (0.018 + lightAmount * 0.18);
        child.position.y = 0.117 + lightAmount * 0.005;
        child.scale.set(1.004 + lightAmount * 0.048, 1.004 + lightAmount * 0.034, 1.004 + lightAmount * 0.052);
      } else if (child.userData.isBladderRim) {
        child.visible = localReveal > 0.06;
        child.material.color.copy(root.userData.warning ? palette.pink : palette.cyan);
        child.material.opacity = localReveal * (0.025 + lightAmount * 0.28);
        child.position.y = 0.119 + lightAmount * 0.005;
        child.scale.set(1.006 + lightAmount * 0.035, 1.006 + lightAmount * 0.026, 1.006 + lightAmount * 0.038);
      } else if (child.userData.isInternalSupport) {
        child.material.opacity = localReveal * 0.08;
        if (child.material.emissiveIntensity !== undefined) child.material.emissiveIntensity = 0;
      } else if (child.material?.emissive) {
        child.material.emissiveIntensity = 0;
      }
    });
  });

  const revealRate = cameraPhase === "returnOverview" ? 0.014 : 0.035;
  reveal += (targetReveal - reveal) * revealRate;
  if (outerCover) {
    outerCover.traverse((child) => {
      if (!child.isMesh || !child.material) return;
      if (child.userData.forceHidden) {
        child.visible = false;
        child.material.opacity = 0;
        child.material.depthWrite = false;
        return;
      }
      if (child.userData.isPiping) {
        child.material.opacity = 0.1 + reveal * 0.04;
        child.material.depthWrite = false;
        return;
      }
      if (child.userData.sideWall) {
        const sideProgress = sideScanProgress[child.userData.side] ?? 1;
        const sideScanReveal = THREE.MathUtils.smoothstep(sideProgress, 0.16, 0.82);
        const sideTarget = sideRevealTarget[child.userData.side] * sideScanReveal;
        child.userData.reveal += (sideTarget - child.userData.reveal) * 0.045;
        tmpColor.lerpColors(new THREE.Color(0x23364d), new THREE.Color(0x5e7488), child.userData.reveal * 0.42);
        child.material.color.copy(tmpColor);
        child.material.opacity = THREE.MathUtils.lerp(1, 0.34, child.userData.reveal);
        if (child.material.transmission !== undefined) child.material.transmission = 0;
        child.material.roughness = THREE.MathUtils.lerp(0.86, 0.72, child.userData.reveal);
        child.material.depthWrite = child.userData.reveal < 0.42;
        if (child.material.emissiveIntensity !== undefined) child.material.emissiveIntensity = 0;
        child.material.needsUpdate = true;
        return;
      }
      child.material.opacity = child.userData.baseOpacity ?? 1;
      if (child.material.transmission !== undefined) child.material.transmission = 0;
      child.material.depthWrite = true;
      if (child.material.emissiveIntensity !== undefined) {
        child.material.emissiveIntensity = 0;
      }
    });
  }
  if (topSheen) {
    topSheen.visible = false;
    topSheen.material.opacity = 0;
  }
  topSurfaces.forEach((top) => {
    const sideProgress = sideScanProgress[top.userData.side] ?? 1;
    const sideScanReveal = THREE.MathUtils.smoothstep(sideProgress, 0.14, 0.88);
    const topTarget = sideRevealTarget[top.userData.side] * sideScanReveal;
    top.userData.reveal += (topTarget - top.userData.reveal) * 0.045;
    tmpColor.lerpColors(new THREE.Color(0x31485f), new THREE.Color(0x617789), top.userData.reveal * 0.38);
    top.material.color.copy(tmpColor);
    top.material.opacity = THREE.MathUtils.lerp(1, 0.36, top.userData.reveal);
    if (top.material.transmission !== undefined) top.material.transmission = 0;
    top.material.roughness = THREE.MathUtils.lerp(0.88, 0.74, top.userData.reveal);
    top.material.depthWrite = top.userData.reveal < 0.42;
    if (top.material.emissiveIntensity !== undefined) top.material.emissiveIntensity = 0;
    top.material.needsUpdate = true;
  });
  labels.forEach((label) => {
    const root = label.parent;
    label.material.opacity = 0;
    label.visible = false;
  });
  if (scanFrame) {
    const scanVisible = targetReveal > 0 && scanProgress < 1;
    const fadeIn = THREE.MathUtils.smoothstep(scanProgress, 0, 0.06);
    const fadeOut = 1 - THREE.MathUtils.smoothstep(scanProgress, 0.88, 1);
    const scanPulse = 0.92 + Math.sin(t * 11) * 0.08;
    const scanOpacity = scanVisible ? fadeIn * fadeOut * scanPulse : 0;
    const scanSideX = focusSide === "left" ? -0.69 : 0.69;
    const scanWidthScale = 0.49;
    scanFrame.visible = scanOpacity > 0.01;
    scanFrame.position.set(scanSideX, 0, scanStartZ + scanProgress * scanRangeZ);
    scanFrame.scale.set(scanWidthScale * (1 + Math.sin(t * 7.5) * 0.004), 1 + Math.sin(t * 6.5) * 0.005, 1);
    scanFrame.traverse((child) => {
      if (!child.isMesh || !child.material) return;
      if (child.userData.scanCurtain) {
        child.material.opacity = scanOpacity * 0.38;
      } else if (child.userData.scanPart) {
        const baseOpacity = child.userData.scanOpacity ?? 0.3;
        const shimmer = child.userData.scanPart === "tail" ? 0.82 + Math.sin(t * 6 + child.position.z * 8) * 0.18 : 1;
        child.material.opacity = scanOpacity * baseOpacity * shimmer;
      }
    });
  }
  if (scanWash) {
    scanWash.position.z = scanFrame?.position.z ?? scanStartZ;
    scanWash.visible = false;
    scanWash.material.opacity = 0;
  }
  coverSlices.forEach((slice) => {
    const sideProgress = sideScanProgress[slice.userData.side] ?? 1;
    const scanZ = scanStartZ + sideProgress * scanRangeZ;
    const sliceReveal = sideRevealTarget[slice.userData.side] > 0
      ? THREE.MathUtils.smoothstep(scanZ, slice.userData.zStart - 0.05, slice.userData.zEnd - 0.12)
      : 0;
    slice.userData.reveal += (sliceReveal - slice.userData.reveal) * 0.06;
    slice.visible = slice.userData.reveal > 0.012;
    tmpColor.lerpColors(new THREE.Color(0x314860), new THREE.Color(0x6f8798), slice.userData.reveal * 0.38);
    slice.material.color.copy(tmpColor);
    slice.material.opacity = slice.userData.reveal * 0.062;
    slice.material.transmission = 0;
    slice.material.roughness = THREE.MathUtils.lerp(0.88, 0.74, slice.userData.reveal);
    slice.material.emissiveIntensity = 0;
    slice.material.depthWrite = false;
    slice.material.needsUpdate = true;
  });

  heatZones.forEach((heat) => {
    const enabled = heatState[heat.userData.side]?.[heat.userData.key] === true;
    const matchingSlice = coverSlices.find((slice) => slice.userData.side === heat.userData.side && slice.userData.key === heat.userData.key);
    const localReveal = matchingSlice?.userData.reveal ?? 0;
    const breath = linearBreath(t, 10.8, heat.userData.phase);
    const smoothBreath = THREE.MathUtils.smoothstep(breath, 0, 1);
    const target = enabled ? 1 : 0;
    heat.userData.strength += (target - heat.userData.strength) * 0.02;
    const strength = heat.userData.strength;
    const revealDimming = THREE.MathUtils.lerp(1, 0.68, localReveal);
    heat.visible = strength > 0.008;
    heat.position.y = 0.552 + smoothBreath * 0.004;
    heat.scale.set(1 + smoothBreath * 0.018, 1 + smoothBreath * 0.024, 1);
    heat.material.uniforms.uTime.value = t;
    heat.material.uniforms.uStrength.value = strength;
    heat.material.uniforms.uRevealDimming.value = revealDimming;
    heat.material.uniforms.uPhase.value = heat.userData.phase;
  });

  bed.children.forEach((child) => {
    if (child.userData.scan) return;
    if (child.userData.revealLine) child.material.opacity = 0;
  });

  labels.forEach((label) => label.quaternion.copy(camera.quaternion));

  if (hoveredDirty) {
    raycaster.setFromCamera(pointer, camera);
    const hits = raycaster.intersectObjects(zoneMeshes, true);
    hovered = hits[0]?.object?.parent?.userData?.key ? hits[0].object.parent : null;
    hoveredDirty = false;
  }

  if (manualCamera.active) {
    const cameraEase = easeInOutCubic((nowMs - manualCamera.start) / manualCamera.duration);
    if (manualCamera.path === "orbit") {
      const orbitCenter = targetDesired.set(0, manualCamera.toTarget.y, manualCamera.toTarget.z);
      const startOffset = manualCamera.fromPosition.clone().sub(orbitCenter);
      const endOffset = manualCamera.toPosition.clone().sub(orbitCenter);
      const startRadius = Math.max(3.9, Math.hypot(startOffset.x, startOffset.z));
      const endRadius = Math.max(3.9, Math.hypot(endOffset.x, endOffset.z));
      const radius = THREE.MathUtils.lerp(startRadius, endRadius, cameraEase);
      let startAngle = Math.atan2(startOffset.z, startOffset.x);
      let endAngle = Math.atan2(endOffset.z, endOffset.x);
      if (manualCamera.arcDirection < 0 && startAngle < endAngle) startAngle += Math.PI * 2;
      if (manualCamera.arcDirection > 0 && endAngle < startAngle) endAngle += Math.PI * 2;
      const angle = THREE.MathUtils.lerp(startAngle, endAngle, cameraEase);
      const height = THREE.MathUtils.lerp(manualCamera.fromPosition.y, manualCamera.toPosition.y, cameraEase);
      camera.position.set(Math.cos(angle) * radius, height, manualCamera.toTarget.z + Math.sin(angle) * radius);
    } else {
      camera.position.copy(manualCamera.fromPosition).lerp(manualCamera.toPosition, cameraEase);
    }
    controls.target.copy(manualCamera.fromTarget).lerp(manualCamera.toTarget, cameraEase);
    if (cameraEase >= 1) {
      manualCamera.active = false;
      cameraPhase = manualCamera.endPhase;
    }
  } else if (performance.now() > autoCameraPausedUntil) {
    const sideSign = focusSide === "left" ? -1 : 1;
    const elapsed = sequenceElapsedMs;
    let sideViewAmount = 0;
    const sideTarget = new THREE.Vector3(sideSign * 0.72, 0.38, 0.14);
    const sidePosition = isIOSNativeEmbed
      ? new THREE.Vector3(sideSign * 5.42, 2.84, sideTarget.z)
      : new THREE.Vector3(sideSign * 4.35, 2.48, sideTarget.z);

    if (cameraPhase === "moveToSide") {
      sideViewAmount = easeInOutCubic(elapsed / cameraTiming.moveToSide);
      if (cameraPath === "sideToSide") {
        const orbitCenter = targetDesired.set(0, sideTarget.y, sideTarget.z);
        const startOffset = cameraMoveStart.clone().sub(orbitCenter);
        const endOffset = sidePosition.clone().sub(orbitCenter);
        const startRadius = Math.max(3.9, Math.hypot(startOffset.x, startOffset.z));
        const endRadius = Math.max(3.9, Math.hypot(endOffset.x, endOffset.z));
        const radius = THREE.MathUtils.lerp(startRadius, endRadius, sideViewAmount);
        let startAngle = Math.atan2(startOffset.z, startOffset.x);
        let endAngle = Math.atan2(endOffset.z, endOffset.x);
        if (cameraArcDirection < 0 && startAngle < endAngle) startAngle += Math.PI * 2;
        if (cameraArcDirection > 0 && endAngle < startAngle) endAngle += Math.PI * 2;
        const angle = THREE.MathUtils.lerp(startAngle, endAngle, sideViewAmount);
        const height = THREE.MathUtils.lerp(cameraMoveStart.y, sidePosition.y, sideViewAmount);
        cameraDesired.set(Math.cos(angle) * radius, height, sideTarget.z + Math.sin(angle) * radius);
        targetDesired.copy(targetMoveStart).lerp(sideTarget, sideViewAmount);
      } else {
        cameraDesired.copy(cameraMoveStart).lerp(sidePosition, sideViewAmount);
        targetDesired.copy(targetMoveStart).lerp(sideTarget, sideViewAmount);
      }
    } else if (cameraPhase === "sideHold") {
      sideViewAmount = 1;
      cameraDesired.copy(sidePosition);
      targetDesired.copy(sideTarget);
    } else if (cameraPhase === "returnOverview") {
      sideViewAmount = 1 - easeInOutCubic((elapsed - cameraTiming.sideHold) / (cameraTiming.returnOverview - cameraTiming.sideHold));
      cameraDesired.copy(overviewPosition).lerp(sidePosition, sideViewAmount);
      targetDesired.copy(overviewTarget).lerp(sideTarget, sideViewAmount);
    } else {
      cameraDesired.copy(overviewPosition);
      targetDesired.copy(overviewTarget);
    }

    const cameraLerp = isIOSNativeEmbed
      ? (cameraPhase === "sideHold" ? 0.18 : 0.11)
      : (cameraPhase === "sideHold" ? 0.12 : 0.055);
    camera.position.lerp(cameraDesired, cameraLerp);
    controls.target.lerp(targetDesired, cameraLerp);
  }
  bed.rotation.set(0, 0, 0);
  controls.update();
  renderer.render(scene, camera);
  renderedFrameCount += 1;
  if (!isSceneReady && renderedFrameCount >= 3) {
    isSceneReady = true;
    postAppEvent("ready", { version: window.SmartMattress3D.version });
  }
  if (shouldContinueRendering(nowMs)) {
    animationFrameId = requestAnimationFrame(animate);
  }
}

document.querySelectorAll("button[data-mode]").forEach((button) => {
  button.addEventListener("click", () => setMode(button.dataset.mode));
});
document.querySelectorAll("button[data-heat-side]").forEach((button) => {
  button.addEventListener("click", () => toggleHeat(button.dataset.heatSide, button.dataset.heatZone));
});
canvas.addEventListener("pointermove", updatePointer);
canvas.addEventListener("pointerdown", (event) => {
  autoCameraPausedUntil = performance.now() + 9000;
  handlePick(event);
  requestRender(settleTiming.hover);
});
controls.addEventListener("start", () => {
  autoCameraPausedUntil = performance.now() + 12000;
  requestRender(12000);
});
controls.addEventListener("end", () => {
  autoCameraPausedUntil = performance.now() + 8000;
  requestRender(8000);
});
window.addEventListener("resize", () => {
  camera.aspect = cameraAspect();
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  requestRender(settleTiming.bootstrap);
});

createScene()
  .then(() => {
    updateHeatButtons();
    configureApp({ embedded: initialAppConfig.embedded === true, ...initialAppConfig });
    if (initialAppConfig.autorun !== true && !initialAppConfig.mode) setMode("flat");
    requestRender(settleTiming.bootstrap);
  })
  .catch((error) => {
    console.error(error);
    const message = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    document.querySelector("#statusText").textContent = `模型初始化失败：${message}`;
  });
