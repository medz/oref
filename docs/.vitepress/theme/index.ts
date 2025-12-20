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
  let currentScroll = 0;
  let frame = 0;

  const setVars = () => {
    root.style.setProperty('--glass-light-x', `${currentX * 100}%`);
    root.style.setProperty('--glass-light-y', `${currentY * 100}%`);
    root.style.setProperty('--glass-light-x2', `${(1 - currentX) * 100}%`);
    root.style.setProperty('--glass-light-y2', `${(1 - currentY) * 100}%`);
    root.style.setProperty('--glass-scroll', `${currentScroll.toFixed(3)}`);
  };

  const onPointerMove = (event: PointerEvent) => {
    if (prefersReducedMotion || prefersReducedTransparency) return;
    const x = event.clientX / Math.max(window.innerWidth, 1);
    const y = event.clientY / Math.max(window.innerHeight, 1);
    targetX = Math.min(0.95, Math.max(0.05, x));
    targetY = Math.min(0.95, Math.max(0.05, y));
  };

  const onPointerLeave = () => {
    targetX = 0.5;
    targetY = 0.18;
  };

  const onScroll = () => {
    currentScroll = Math.min(window.scrollY / 900, 1);
  };

  const tick = () => {
    if (!prefersReducedMotion && !prefersReducedTransparency) {
      currentX += (targetX - currentX) * 0.08;
      currentY += (targetY - currentY) * 0.08;
    }
    setVars();
    frame = window.requestAnimationFrame(tick);
  };

  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('pointerleave', onPointerLeave);
  window.addEventListener('scroll', onScroll, { passive: true });

  onScroll();
  setVars();
  frame = window.requestAnimationFrame(tick);

  window.addEventListener('beforeunload', () => {
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('pointerleave', onPointerLeave);
    window.removeEventListener('scroll', onScroll);
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
