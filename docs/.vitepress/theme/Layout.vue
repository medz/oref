<script setup lang="ts">
import DefaultTheme from 'vitepress/theme-without-fonts';
import { useData } from 'vitepress';
import HeroCanvas from './components/HeroCanvas.vue';
import HeroMascot from './components/HeroMascot.vue';

const { frontmatter } = useData();
</script>

<template>
  <DefaultTheme.Layout>
    <template #home-hero-before>
      <ClientOnly v-if="frontmatter.layout === 'home'">
        <HeroCanvas />
      </ClientOnly>
    </template>
    <template #home-hero-image>
      <ClientOnly v-if="frontmatter.layout === 'home'">
        <HeroMascot />
      </ClientOnly>
    </template>
  </DefaultTheme.Layout>
</template>
