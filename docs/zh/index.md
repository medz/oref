---
layout: home
hero:
  name: Oref
  text: Flutter Signals，快速又省心
  tagline: 更少样板代码，自动重建，清晰可预测的响应式。
  actions:
    - theme: brand
      text: 快速开始
      link: /zh/guide/getting-started
    - theme: alt
      text: 核心概念
      link: /zh/guide/core-concepts
features:
  - title: Signal 优先 API
    details: "通过 `signal()` 创建响应式值，使用 `.set(...)` 更新。"
  - title: Computed + Effect
    details: "`computed()` 负责派生，`effect()` 处理副作用。"
  - title: 内置异步数据
    details: "`useAsyncData()` 管理加载/成功/失败状态。"
  - title: 集合类型封装
    details: "Reactive List/Map/Set 适合复杂 UI 状态。"
---

<p class="section-kicker">为什么选择 Oref</p>

<div class="section-grid">
  <div class="section-card">
    <h3>可预测的响应式</h3>
    <p>读取会追踪依赖，写入会通知订阅者，没有隐藏魔法。</p>
  </div>
  <div class="section-card">
    <h3>以 Widget 为中心</h3>
    <p>信号与组件同域，使用 <code>SignalBuilder</code> 精准控制重建范围。</p>
  </div>
  <div class="section-card">
    <h3>简单又可组合</h3>
    <p>Signals、Computed、Effects 与 Batch 组合自然。</p>
  </div>
</div>

## 三步快速开始

### 1. 安装

```bash
flutter pub add oref
```

### 2. 创建 signal

```dart
final count = signal(context, 0);
```

### 3. 派生与更新

```dart
final doubled = computed(context, (_) => count() * 2);
count.set(count() + 1);
```

<div class="callout">
  <strong>需要完整方案？</strong>
  <p>查看指南中的异步数据、批处理与集合类型示例。</p>
</div>

## 推荐上手场景

<div class="section-grid">
  <div class="section-card">
    <h3>表单状态</h3>
    <p>使用 signal 存储输入值，用 computed 派生校验结果。</p>
  </div>
  <div class="section-card">
    <h3>列表筛选</h3>
    <p>通过 computed 派生过滤后的列表视图。</p>
  </div>
  <div class="section-card">
    <h3>异步加载</h3>
    <p>用 <code>useAsyncData()</code> 管理请求状态。</p>
  </div>
</div>

继续阅读 **快速开始** 了解更多。
