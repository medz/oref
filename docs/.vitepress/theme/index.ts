import DefaultTheme from 'vitepress/theme-without-fonts';
import Layout from './Layout.vue';
import './custom.css';

const setupGlassMotion = () => {
  if (typeof window === 'undefined') return;
  const win = window as typeof window & { __orefGlassMotion?: boolean };
  if (win.__orefGlassMotion) return;
  win.__orefGlassMotion = true;

  const root = document.documentElement;
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;
  const prefersReducedTransparency = window.matchMedia(
    '(prefers-reduced-transparency: reduce)'
  ).matches;

  let targetX = 0.5;
  let targetY = 0.18;
  let currentX = targetX;
  let currentY = targetY;
  let targetPointerX = window.innerWidth * targetX;
  let targetPointerY = window.innerHeight * targetY;
  let currentPointerX = targetPointerX;
  let currentPointerY = targetPointerY;
  let currentScroll = 0;
  let frame = 0;
  const localSelector = '.section-card, .VPFeature';
  const localTargets = new Set<HTMLElement>();
  let observer: MutationObserver | null = null;

  const setVars = () => {
    root.style.setProperty('--glass-light-x', `${currentX * 100}%`);
    root.style.setProperty('--glass-light-y', `${currentY * 100}%`);
    root.style.setProperty('--glass-light-x2', `${(1 - currentX) * 100}%`);
    root.style.setProperty('--glass-light-y2', `${(1 - currentY) * 100}%`);
    root.style.setProperty('--glass-scroll', `${currentScroll.toFixed(3)}`);
  };

  const collectLocalTargets = () => {
    localTargets.clear();
    document.querySelectorAll<HTMLElement>(localSelector).forEach((el) => {
      localTargets.add(el);
    });
  };

  const setLocalVars = () => {
    if (localTargets.size === 0) return;
    localTargets.forEach((el) => {
      const rect = el.getBoundingClientRect();
      const width = Math.max(rect.width, 1);
      const height = Math.max(rect.height, 1);
      const x = (currentPointerX - rect.left) / width;
      const y = (currentPointerY - rect.top) / height;
      const clampedX = Math.min(1.5, Math.max(-0.5, x));
      const clampedY = Math.min(1.5, Math.max(-0.5, y));
      el.style.setProperty('--glass-card-light-x', `${clampedX * 100}%`);
      el.style.setProperty('--glass-card-light-y', `${clampedY * 100}%`);
      el.style.setProperty('--glass-card-light-x2', `${(1 - clampedX) * 100}%`);
      el.style.setProperty('--glass-card-light-y2', `${(1 - clampedY) * 100}%`);
    });
  };

  const onPointerMove = (event: PointerEvent) => {
    if (prefersReducedMotion || prefersReducedTransparency) return;
    const x = event.clientX / Math.max(window.innerWidth, 1);
    const y = event.clientY / Math.max(window.innerHeight, 1);
    targetX = Math.min(0.95, Math.max(0.05, x));
    targetY = Math.min(0.95, Math.max(0.05, y));
    targetPointerX = event.clientX;
    targetPointerY = event.clientY;
  };

  const onPointerLeave = () => {
    targetX = 0.5;
    targetY = 0.18;
    targetPointerX = window.innerWidth * targetX;
    targetPointerY = window.innerHeight * targetY;
  };

  const onScroll = () => {
    currentScroll = Math.min(window.scrollY / 900, 1);
  };

  const tick = () => {
    if (!prefersReducedMotion && !prefersReducedTransparency) {
      currentX += (targetX - currentX) * 0.08;
      currentY += (targetY - currentY) * 0.08;
      currentPointerX += (targetPointerX - currentPointerX) * 0.08;
      currentPointerY += (targetPointerY - currentPointerY) * 0.08;
    }
    setVars();
    setLocalVars();
    frame = window.requestAnimationFrame(tick);
  };

  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('pointerleave', onPointerLeave);
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', collectLocalTargets);

  onScroll();
  collectLocalTargets();
  setVars();
  setLocalVars();
  frame = window.requestAnimationFrame(tick);

  observer = new MutationObserver(() => {
    collectLocalTargets();
  });
  observer.observe(document.body, { childList: true, subtree: true });

  window.addEventListener('beforeunload', () => {
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('pointerleave', onPointerLeave);
    window.removeEventListener('scroll', onScroll);
    window.removeEventListener('resize', collectLocalTargets);
    observer?.disconnect();
    window.cancelAnimationFrame(frame);
  });
};

export default {
  extends: DefaultTheme,
  Layout,
  enhanceApp() {
    setupGlassMotion();
  },
};
