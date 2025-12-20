<template>
  <div ref="container" class="hero-canvas" aria-hidden="true"></div>
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
    BufferGeometry,
    BufferAttribute,
    Points,
    PointsMaterial,
    AdditiveBlending,
  } = THREE;

  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  const scene = new Scene();

  const size = host.getBoundingClientRect();
  const camera = new PerspectiveCamera(42, size.width / size.height, 0.1, 200);
  camera.position.set(0, 10, 24);

  const renderer = new WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(size.width, size.height);
  renderer.setClearColor(new Color(0x000000), 0);
  host.appendChild(renderer.domElement);

  const grid = 68;
  const spacing = 0.65;
  const total = grid * grid;
  const positions = new Float32Array(total * 3);
  const base = new Float32Array(total * 3);
  let idx = 0;

  for (let x = 0; x < grid; x += 1) {
    for (let z = 0; z < grid; z += 1) {
      const px = (x - grid / 2) * spacing;
      const pz = (z - grid / 2) * spacing;
      positions[idx] = px;
      base[idx++] = px;
      positions[idx] = 0;
      base[idx++] = 0;
      positions[idx] = pz;
      base[idx++] = pz;
    }
  }

  const pointGeometry = new BufferGeometry();
  pointGeometry.setAttribute('position', new BufferAttribute(positions, 3));

  const pointMaterial = new PointsMaterial({
    color: 0x14b8a6,
    size: 0.085,
    sizeAttenuation: true,
    opacity: 0.65,
    transparent: true,
    blending: AdditiveBlending,
  });

  const points = new Points(pointGeometry, pointMaterial);
  points.position.y = -4;
  points.rotation.x = -Math.PI / 3.3;
  scene.add(points);

  const onResize = () => {
    const next = host.getBoundingClientRect();
    camera.aspect = next.width / next.height;
    camera.updateProjectionMatrix();
    renderer.setSize(next.width, next.height);
  };

  window.addEventListener('resize', onResize);

  let frame = 0;
  const start = performance.now();

  const animate = () => {
    const t = (performance.now() - start) / 1000;

    if (!prefersReducedMotion) {
      const attr = pointGeometry.getAttribute('position') as BufferAttribute;
      for (let i = 0; i < total; i += 1) {
        const offset = i * 3;
        const bx = base[offset];
        const bz = base[offset + 2];
        attr.array[offset + 1] =
          Math.sin((bx + t * 2.2) * 0.35) * 0.5 +
          Math.cos((bz - t * 1.6) * 0.28) * 0.4;
      }
      attr.needsUpdate = true;
    }

    camera.lookAt(0, 0, 0);

    renderer.render(scene, camera);
    frame = window.requestAnimationFrame(animate);
  };

  animate();

  disposeScene = () => {
    window.cancelAnimationFrame(frame);
    window.removeEventListener('resize', onResize);

    pointGeometry.dispose();
    pointMaterial.dispose();
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
