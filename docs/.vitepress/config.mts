import { defineConfig } from 'vitepress';

const repoName = process.env.GITHUB_REPOSITORY?.split('/')[1] ?? 'oref';
const base =
  process.env.GITHUB_PAGES_BASE ??
  (process.env.GITHUB_ACTIONS ? `/${repoName}/` : '/');

export default defineConfig({
  title: 'Oref',
  description: 'Object-shaped reactive primitives over alien_signals.',
  cleanUrls: true,
  base,
  markdown: { lineNumbers: true },
  themeConfig: {
    socialLinks: [{ icon: 'github', link: 'https://github.com/medz/oref' }],
    search: { provider: 'local' },
    nav: [
      { text: 'Core Guide', link: '/guide/reactive-core' },
      { text: 'Design', link: 'https://github.com/medz/oref/issues/47' },
    ],
    sidebar: [
      { text: 'Core', items: [
        { text: 'Reactive Core', link: '/guide/reactive-core' },
      ] },
    ],
  },
});
