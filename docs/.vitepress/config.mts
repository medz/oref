import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'Oref',
  description: 'High-performance Flutter signals with minimal boilerplate.',
  cleanUrls: true,
  markdown: {
    lineNumbers: true,
  },
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
          { text: 'API Reference', link: 'https://pub.dev/documentation/oref/latest/oref/' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Guide',
              items: [
                { text: 'Getting Started', link: '/guide/getting-started' },
                { text: 'Core Concepts', link: '/guide/core-concepts' },
                { text: 'Effects & Batching', link: '/guide/effects' },
                { text: 'Async Data', link: '/guide/async-data' },
                { text: 'Collections', link: '/guide/collections' },
              ],
            },
          ],
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
          { text: 'API 参考', link: 'https://pub.dev/documentation/oref/latest/oref/' },
        ],
        sidebar: {
          '/zh/guide/': [
            {
              text: '指南',
              items: [
                { text: '快速开始', link: '/zh/guide/getting-started' },
                { text: '核心概念', link: '/zh/guide/core-concepts' },
                { text: 'Effect 与批处理', link: '/zh/guide/effects' },
                { text: '异步数据', link: '/zh/guide/async-data' },
                { text: '集合类型', link: '/zh/guide/collections' },
              ],
            },
          ],
        },
        outlineTitle: '本页目录',
      },
    },
  },
});
