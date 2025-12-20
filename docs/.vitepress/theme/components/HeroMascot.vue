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
    SphereGeometry,
    CylinderGeometry,
    TorusGeometry,
    Shape,
    ShapeGeometry,
    MeshStandardMaterial,
    Mesh,
    AmbientLight,
    DirectionalLight,
    HemisphereLight,
    PointLight,
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
  camera.position.set(0, 1.3, 7.4);

  const renderer = new WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(size.width, size.height);
  renderer.setClearColor(new Color(0x000000), 0);
  host.appendChild(renderer.domElement);

  const ambient = new AmbientLight(0xffffff, 0.7);
  const hemi = new HemisphereLight(0xffe5f4, 0x1a2130, 0.95);
  const key = new DirectionalLight(0xffffff, 1.0);
  key.position.set(4, 6, 4);
  const rim = new DirectionalLight(0xff8ad1, 0.8);
  rim.position.set(-5, 3, -4);
  const sparkle = new PointLight(0x7cf9ff, 0.6, 20);
  sparkle.position.set(2.6, 2.6, 4.6);
  scene.add(ambient, hemi, key, rim, sparkle);

  const fur = new MeshStandardMaterial({
    color: 0xffc3de,
    roughness: 0.35,
    metalness: 0.15,
  });
  const furShadow = new MeshStandardMaterial({
    color: 0xd6a4ff,
    roughness: 0.4,
    metalness: 0.1,
  });
  const innerEar = new MeshStandardMaterial({
    color: 0xff8fd2,
    roughness: 0.45,
    metalness: 0.05,
  });
  const belly = new MeshStandardMaterial({
    color: 0xfff3dc,
    roughness: 0.4,
    metalness: 0.05,
  });
  const eyeWhite = new MeshStandardMaterial({
    color: 0xffffff,
    roughness: 0.2,
    metalness: 0.0,
  });
  const pupilMat = new MeshStandardMaterial({
    color: 0x0f172a,
    emissive: 0x0f172a,
    emissiveIntensity: 0.4,
    roughness: 0.2,
    metalness: 0.0,
  });
  const cheek = new MeshStandardMaterial({
    color: 0xff9ad9,
    roughness: 0.4,
    metalness: 0.0,
  });
  const noseMat = new MeshStandardMaterial({
    color: 0xff9fd4,
    emissive: 0xff9fd4,
    emissiveIntensity: 0.35,
    roughness: 0.25,
    metalness: 0.0,
  });
  const mouthMat = new MeshStandardMaterial({
    color: 0xffffff,
    emissive: 0xffc4f2,
    emissiveIntensity: 0.75,
    roughness: 0.3,
    metalness: 0.0,
  });

  const root = new Group();
  scene.add(root);

  const body = new Mesh(new SphereGeometry(1.3, 32, 32), fur);
  body.position.set(0, -0.15, 0);
  body.scale.set(1.05, 0.95, 0.95);
  root.add(body);

  const bellyPatch = new Mesh(new SphereGeometry(0.7, 24, 24), belly);
  bellyPatch.position.set(0, -0.2, 0.85);
  root.add(bellyPatch);

  const pawGeometry = new SphereGeometry(0.32, 20, 20);
  const pawL = new Mesh(pawGeometry, fur);
  pawL.position.set(-0.7, -0.95, 0.8);
  pawL.scale.set(1.05, 0.85, 0.9);
  root.add(pawL);
  const pawR = pawL.clone();
  pawR.position.x = 0.7;
  root.add(pawR);

  const headGroup = new Group();
  headGroup.position.set(0, 1.1, 0.1);
  root.add(headGroup);

  const head = new Mesh(new SphereGeometry(1.0, 32, 32), furShadow);
  head.position.set(0, 0.05, 0);
  headGroup.add(head);

  const earShape = new Shape();
  earShape.moveTo(-0.28, 0.0);
  earShape.quadraticCurveTo(0, -0.14, 0.28, 0.0);
  earShape.quadraticCurveTo(0.4, 0.85, 0.14, 1.55);
  earShape.quadraticCurveTo(0, 1.8, -0.14, 1.55);
  earShape.quadraticCurveTo(-0.4, 0.85, -0.28, 0.0);

  const earGeometry = new ShapeGeometry(earShape);
  const earInnerShape = new Shape();
  earInnerShape.moveTo(-0.18, 0.05);
  earInnerShape.quadraticCurveTo(0, -0.02, 0.18, 0.05);
  earInnerShape.quadraticCurveTo(0.26, 0.7, 0.1, 1.2);
  earInnerShape.quadraticCurveTo(0, 1.35, -0.1, 1.2);
  earInnerShape.quadraticCurveTo(-0.26, 0.7, -0.18, 0.05);
  const earInnerGeometry = new ShapeGeometry(earInnerShape);

  const earL = new Group();
  earL.position.set(-0.5, 0.95, 0.15);
  headGroup.add(earL);
  const earLMesh = new Mesh(earGeometry, fur);
  earLMesh.rotation.z = MathUtils.degToRad(6);
  earLMesh.rotation.y = MathUtils.degToRad(8);
  earLMesh.scale.set(0.9, 0.85, 1);
  earL.add(earLMesh);
  const earLInner = new Mesh(earInnerGeometry, innerEar);
  earLInner.position.set(0, 0.06, 0.05);
  earLInner.rotation.z = MathUtils.degToRad(6);
  earLInner.rotation.y = MathUtils.degToRad(8);
  earL.add(earLInner);

  const earR = new Group();
  earR.position.set(0.5, 0.95, 0.15);
  headGroup.add(earR);
  const earRMesh = new Mesh(earGeometry, fur);
  earRMesh.rotation.z = MathUtils.degToRad(-6);
  earRMesh.rotation.y = MathUtils.degToRad(-8);
  earRMesh.scale.set(0.9, 0.85, 1);
  earR.add(earRMesh);
  const earRInner = new Mesh(earInnerGeometry, innerEar);
  earRInner.position.set(0, 0.06, 0.05);
  earRInner.rotation.z = MathUtils.degToRad(-6);
  earRInner.rotation.y = MathUtils.degToRad(-8);
  earR.add(earRInner);

  const eyeL = new Group();
  eyeL.position.set(-0.38, 0.1, 0.78);
  headGroup.add(eyeL);
  const eyeR = new Group();
  eyeR.position.set(0.38, 0.1, 0.78);
  headGroup.add(eyeR);

  const eyeWhiteGeometry = new SphereGeometry(0.18, 20, 20);
  const eyeWhiteL = new Mesh(eyeWhiteGeometry, eyeWhite);
  const eyeWhiteR = new Mesh(eyeWhiteGeometry, eyeWhite);
  eyeL.add(eyeWhiteL);
  eyeR.add(eyeWhiteR);

  const pupilGeometry = new SphereGeometry(0.08, 16, 16);
  const pupilL = new Mesh(pupilGeometry, pupilMat);
  const pupilR = new Mesh(pupilGeometry, pupilMat);
  pupilL.position.z = 0.12;
  pupilR.position.z = 0.12;
  eyeL.add(pupilL);
  eyeR.add(pupilR);

  const cheekGeometry = new SphereGeometry(0.12, 16, 16);
  const cheekL = new Mesh(cheekGeometry, cheek);
  cheekL.position.set(-0.62, -0.1, 0.68);
  headGroup.add(cheekL);
  const cheekR = new Mesh(cheekGeometry, cheek);
  cheekR.position.set(0.62, -0.1, 0.68);
  headGroup.add(cheekR);

  const nose = new Mesh(new SphereGeometry(0.08, 16, 16), noseMat);
  nose.position.set(0, -0.05, 0.85);
  headGroup.add(nose);

  const mouth = new Mesh(
    new TorusGeometry(0.2, 0.02, 12, 28, Math.PI),
    mouthMat
  );
  mouth.position.set(0, -0.18, 0.82);
  mouth.rotation.z = Math.PI;
  headGroup.add(mouth);

  const toothMat = new MeshStandardMaterial({
    color: 0xffffff,
    roughness: 0.2,
    metalness: 0.0,
  });
  const toothGeometry = new SphereGeometry(0.05, 12, 12);
  const toothL = new Mesh(toothGeometry, toothMat);
  toothL.position.set(-0.06, -0.25, 0.82);
  toothL.scale.set(1.1, 1.6, 0.6);
  headGroup.add(toothL);
  const toothR = toothL.clone();
  toothR.position.x = 0.06;
  headGroup.add(toothR);

  root.position.y = -0.1;

  let mouthEmissiveBase = 0.7;

  const applyPalette = (isDark: boolean) => {
    if (isDark) {
      fur.color.setHex(0xffbfe1);
      furShadow.color.setHex(0x8fb3ff);
      innerEar.color.setHex(0xff8ad1);
      belly.color.setHex(0xfff1d6);
      cheek.color.setHex(0xff8ecf);
      noseMat.color.setHex(0xff96d6);
      noseMat.emissive.setHex(0xff96d6);
      mouthMat.emissive.setHex(0xffb8f0);
      mouthEmissiveBase = 0.9;
      ambient.intensity = 0.6;
      hemi.color.setHex(0xbfe1ff);
      hemi.groundColor.setHex(0x0c1220);
      key.intensity = 0.95;
      rim.color.setHex(0xff7de0);
      rim.intensity = 0.85;
      sparkle.color.setHex(0x7cf9ff);
      sparkle.intensity = 0.75;
    } else {
      fur.color.setHex(0xffc3de);
      furShadow.color.setHex(0xa77bff);
      innerEar.color.setHex(0xff9ad9);
      belly.color.setHex(0xfff3dc);
      cheek.color.setHex(0xff9ad9);
      noseMat.color.setHex(0xff9fd4);
      noseMat.emissive.setHex(0xff9fd4);
      mouthMat.emissive.setHex(0xffc4f2);
      mouthEmissiveBase = 0.7;
      ambient.intensity = 0.72;
      hemi.color.setHex(0xffe5f4);
      hemi.groundColor.setHex(0x1a2130);
      key.intensity = 1.05;
      rim.color.setHex(0xff8ad1);
      rim.intensity = 0.75;
      sparkle.color.setHex(0x7cf9ff);
      sparkle.intensity = 0.55;
    }
  };

  const pointer = new Vector2(0, 0);
  const target = new Vector2(0, 0);

  const getIsDark = () =>
    document.documentElement.classList.contains('dark') ||
    window.matchMedia('(prefers-color-scheme: dark)').matches;

  const updateTheme = () => {
    applyPalette(getIsDark());
  };

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

  const media = window.matchMedia('(prefers-color-scheme: dark)');
  const onMediaChange = () => updateTheme();
  media.addEventListener('change', onMediaChange);

  const observer = new MutationObserver(() => updateTheme());
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['class'],
  });

  updateTheme();

  let frame = 0;
  const animate = () => {
    const t = performance.now() / 1000;

    pointer.lerp(target, 0.08);

    if (!prefersReducedMotion) {
      root.position.y = -0.1 + Math.sin(t * 1.2) * 0.03;
      const earWiggle = Math.sin(t * 2.1) * 0.2;
      earL.rotation.z = MathUtils.degToRad(6) + earWiggle * 0.3;
      earR.rotation.z = MathUtils.degToRad(-6) - earWiggle * 0.3;
      earL.rotation.y = MathUtils.degToRad(8) + earWiggle * 0.2;
      earR.rotation.y = MathUtils.degToRad(-8) - earWiggle * 0.2;
      mouthMat.emissiveIntensity =
        mouthEmissiveBase + Math.sin(t * 2.2) * 0.15;
    }

    headGroup.rotation.y = pointer.x * 0.45;
    headGroup.rotation.x = pointer.y * 0.18;

    const eyeRangeX = 0.08;
    const eyeRangeY = 0.06;
    pupilL.position.x = pointer.x * eyeRangeX;
    pupilL.position.y = -pointer.y * eyeRangeY;
    pupilR.position.x = pointer.x * eyeRangeX;
    pupilR.position.y = -pointer.y * eyeRangeY;

    renderer.render(scene, camera);
    frame = window.requestAnimationFrame(animate);
  };

  animate();

  disposeScene = () => {
    window.cancelAnimationFrame(frame);
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('resize', onResize);
    media.removeEventListener('change', onMediaChange);
    observer.disconnect();

    earGeometry.dispose();
    earInnerGeometry.dispose();
    eyeWhiteGeometry.dispose();
    pupilGeometry.dispose();
    cheekGeometry.dispose();
    pawGeometry.dispose();
    toothGeometry.dispose();

    body.geometry.dispose();
    bellyPatch.geometry.dispose();
    pawL.geometry.dispose();
    head.geometry.dispose();
    nose.geometry.dispose();
    mouth.geometry.dispose();

    fur.dispose();
    furShadow.dispose();
    innerEar.dispose();
    belly.dispose();
    eyeWhite.dispose();
    pupilMat.dispose();
    cheek.dispose();
    toothMat.dispose();
    noseMat.dispose();
    mouthMat.dispose();

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
