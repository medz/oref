import { defineConfig } from 'vitepress';

const repoName = process.env.GITHUB_REPOSITORY?.split('/')[1] ?? 'oref';
const base = process.env.GITHUB_PAGES_BASE ??
  (process.env.GITHUB_ACTIONS ? `/${repoName}/` : '/');

const pages = [
  ['getting-started', 'Getting started', '快速开始'],
  ['local-state', 'Local state', '局部状态'],
  ['query', 'Query', '查询'],
  ['pages', 'Pages', '分页'],
  ['action', 'Action', '显式动作'],
  ['remote-value', 'Remote values and fields', '远端值与字段'],
  ['sharing', 'Sharing and sessions', '共享与会话'],
  ['flutter', 'Flutter ownership', 'Flutter 所有权'],
  ['errors', 'Errors and cancellation', '错误与取消'],
];

export default defineConfig({
  title: 'Oref 3',
  description: 'Values, asynchronous resources, and explicit ownership for Flutter.',
  cleanUrls: true,
  base,
  srcExclude: ['design/**'],
  markdown: { lineNumbers: true },
  themeConfig: {
    socialLinks: [{ icon: 'github', link: 'https://github.com/medz/oref' }],
    search: { provider: 'local' },
  },
  locales: {
    root: {
      label: 'English',
      lang: 'en-US',
      link: '/',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/getting-started' },
          { text: '3.0 source', link: 'https://github.com/medz/oref' },
        ],
        sidebar: {
          '/guide/': [{
            text: 'Oref 3 · development API',
            items: pages.map(([slug, title]) => ({ text: title, link: `/guide/${slug}` })),
          }],
        },
        outlineTitle: 'On this page',
      },
    },
    zh: {
      label: '简体中文',
      lang: 'zh-Hans',
      link: '/zh/',
      themeConfig: {
        nav: [
          { text: '指南', link: '/zh/guide/getting-started' },
          { text: '3.0 源码', link: 'https://github.com/medz/oref' },
        ],
        sidebar: {
          '/zh/guide/': [{
            text: 'Oref 3 · 开发 API',
            items: pages.map(([slug, , title]) => ({ text: title, link: `/zh/guide/${slug}` })),
          }],
        },
        outlineTitle: '本页目录',
      },
    },
  },
});
