<template>
  <div ref="container" class="hero-mascot" aria-hidden="true"></div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue';

type ThreeModule = typeof import('three');

const container = ref<HTMLDivElement | null>(null);

let disposeScene: (() => void) | null = null;

onMounted(async () => {
  if (typeof window === 'undefined') return;
  const host = container.value;
  if (!host) return;

  const THREE: ThreeModule = await import('three');
  const {
    WebGLRenderer,
    Scene,
    PerspectiveCamera,
    Color,
    Group,
    BoxGeometry,
    SphereGeometry,
    CylinderGeometry,
    TorusGeometry,
    MeshStandardMaterial,
    Mesh,
    AmbientLight,
    DirectionalLight,
    HemisphereLight,
    Vector2,
    MathUtils,
  } = THREE;

  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  const scene = new Scene();
  scene.background = null;

  const size = host.getBoundingClientRect();
  const camera = new PerspectiveCamera(35, size.width / size.height, 0.1, 100);
  camera.position.set(0, 1.2, 7.6);

  const renderer = new WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(size.width, size.height);
  renderer.setClearColor(new Color(0x000000), 0);
  host.appendChild(renderer.domElement);

  const ambient = new AmbientLight(0xffffff, 0.55);
  const hemi = new HemisphereLight(0xb9f5f0, 0x12181b, 0.9);
  const key = new DirectionalLight(0xffffff, 1.0);
  key.position.set(4, 6, 4);
  const rim = new DirectionalLight(0x14b8a6, 0.6);
  rim.position.set(-5, 3, -4);
  scene.add(ambient, hemi, key, rim);

  const armor = new MeshStandardMaterial({
    color: 0x0f766e,
    roughness: 0.35,
    metalness: 0.35,
  });
  const armorDark = new MeshStandardMaterial({
    color: 0x0b3f3b,
    roughness: 0.55,
    metalness: 0.2,
  });
  const accent = new MeshStandardMaterial({
    color: 0xf59e0b,
    roughness: 0.4,
    metalness: 0.25,
  });
  const pupilMat = new MeshStandardMaterial({
    color: 0x0f172a,
    emissive: 0x0f172a,
    emissiveIntensity: 0.35,
    roughness: 0.2,
    metalness: 0.0,
  });
  const mouthMat = new MeshStandardMaterial({
    color: 0xf8fafc,
    emissive: 0xf59e0b,
    emissiveIntensity: 0.7,
    roughness: 0.35,
    metalness: 0.2,
  });
  const coreMat = new MeshStandardMaterial({
    color: 0x14b8a6,
    emissive: 0x14b8a6,
    emissiveIntensity: 1.2,
    roughness: 0.2,
    metalness: 0.3,
  });

  const root = new Group();
  scene.add(root);

  const torso = new Mesh(new BoxGeometry(1.7, 2.2, 1.2), armor);
  torso.position.set(0, 0.2, 0);
  root.add(torso);

  const torsoPlate = new Mesh(new BoxGeometry(1.2, 1.6, 0.2), armorDark);
  torsoPlate.position.set(0, 0.25, 0.6);
  root.add(torsoPlate);

  const core = new Mesh(new BoxGeometry(0.5, 0.5, 0.2), coreMat);
  core.position.set(0, 0.25, 0.75);
  root.add(core);

  const hips = new Mesh(new BoxGeometry(1.4, 0.5, 1.0), armorDark);
  hips.position.set(0, -1.05, 0);
  root.add(hips);

  const shoulderL = new Mesh(new BoxGeometry(0.7, 0.5, 0.9), armor);
  shoulderL.position.set(-1.15, 0.9, 0);
  root.add(shoulderL);
  const shoulderR = shoulderL.clone();
  shoulderR.position.x = 1.15;
  root.add(shoulderR);

  const armL = new Mesh(new BoxGeometry(0.4, 1.4, 0.4), armorDark);
  armL.position.set(-1.35, -0.1, 0.1);
  root.add(armL);
  const armR = armL.clone();
  armR.position.x = 1.35;
  root.add(armR);

  const neck = new Mesh(new CylinderGeometry(0.35, 0.45, 0.4, 24), armorDark);
  neck.position.set(0, 1.45, 0);
  root.add(neck);

  const headGroup = new Group();
  headGroup.position.set(0, 1.75, 0.1);
  root.add(headGroup);

  const helmet = new Mesh(new SphereGeometry(0.95, 32, 32), armor);
  helmet.position.set(0, 0.25, 0);
  headGroup.add(helmet);

  const eyeL = new Group();
  eyeL.position.set(-0.25, 0.32, 0.86);
  headGroup.add(eyeL);
  const eyeR = new Group();
  eyeR.position.set(0.25, 0.32, 0.86);
  headGroup.add(eyeR);

  const pupilGeometry = new SphereGeometry(0.08, 16, 16);
  const pupilL = new Mesh(pupilGeometry, pupilMat);
  const pupilR = new Mesh(pupilGeometry, pupilMat);
  eyeL.add(pupilL);
  eyeR.add(pupilR);

  const mouth = new Mesh(
    new TorusGeometry(0.22, 0.025, 10, 32, Math.PI),
    mouthMat
  );
  mouth.position.set(0, 0.02, 0.86);
  mouth.rotation.z = Math.PI;
  headGroup.add(mouth);

  const antenna = new Mesh(new CylinderGeometry(0.04, 0.04, 0.5, 12), accent);
  antenna.position.set(0.45, 1.05, -0.1);
  antenna.rotation.z = MathUtils.degToRad(15);
  headGroup.add(antenna);

  const antennaTip = new Mesh(new SphereGeometry(0.08, 12, 12), coreMat);
  antennaTip.position.set(0.55, 1.3, -0.1);
  headGroup.add(antennaTip);

  root.position.y = -0.1;

  const pointer = new Vector2(0, 0);
  const target = new Vector2(0, 0);

  const onPointerMove = (event: PointerEvent) => {
    const rect = host.getBoundingClientRect();
    const x = (event.clientX - rect.left) / rect.width;
    const y = (event.clientY - rect.top) / rect.height;
    target.set((x - 0.5) * 2, (y - 0.5) * 2);
  };

  const onResize = () => {
    const next = host.getBoundingClientRect();
    camera.aspect = next.width / next.height;
    camera.updateProjectionMatrix();
    renderer.setSize(next.width, next.height);
  };

  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('resize', onResize);

  let frame = 0;
  const animate = () => {
    const t = performance.now() / 1000;

    pointer.lerp(target, 0.08);

    if (!prefersReducedMotion) {
      root.position.y = -0.1 + Math.sin(t * 1.4) * 0.04;
      coreMat.emissiveIntensity = 1.0 + Math.sin(t * 2.4) * 0.2;
    }

    headGroup.rotation.y = pointer.x * 0.45;
    headGroup.rotation.x = pointer.y * 0.18;

    const eyeRangeX = 0.08;
    const eyeRangeY = 0.05;
    pupilL.position.x = pointer.x * eyeRangeX;
    pupilL.position.y = pointer.y * eyeRangeY;
    pupilR.position.x = pointer.x * eyeRangeX;
    pupilR.position.y = pointer.y * eyeRangeY;

    if (!prefersReducedMotion) {
      const blink = Math.pow(Math.max(0, Math.sin(t * 1.7 + 0.8)), 16);
      const eyeScaleY = 1 - blink * 0.85;
      pupilL.scale.y = eyeScaleY;
      pupilR.scale.y = eyeScaleY;

      const smile = Math.sin(t * 1.3) * 0.07;
      mouth.scale.y = 0.65 + smile;
      mouth.scale.x = 0.95 + smile * 0.15;
      mouth.position.y = 0.02 + smile * 0.2;
    } else {
      pupilL.scale.y = 1;
      pupilR.scale.y = 1;
      mouth.scale.y = 0.65;
      mouth.scale.x = 0.95;
      mouth.position.y = 0.02;
    }

    renderer.render(scene, camera);
    frame = window.requestAnimationFrame(animate);
  };

  animate();

  disposeScene = () => {
    window.cancelAnimationFrame(frame);
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('resize', onResize);

    pupilGeometry.dispose();
    torso.geometry.dispose();
    torsoPlate.geometry.dispose();
    core.geometry.dispose();
    hips.geometry.dispose();
    shoulderL.geometry.dispose();
    armL.geometry.dispose();
    neck.geometry.dispose();
    helmet.geometry.dispose();
    mouth.geometry.dispose();
    antenna.geometry.dispose();
    antennaTip.geometry.dispose();

    armor.dispose();
    armorDark.dispose();
    accent.dispose();
    pupilMat.dispose();
    mouthMat.dispose();
    coreMat.dispose();

    renderer.dispose();

    if (renderer.domElement.parentElement === host) {
      host.removeChild(renderer.domElement);
    }
  };
});

onBeforeUnmount(() => {
  disposeScene?.();
  disposeScene = null;
});
</script>
