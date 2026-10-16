---
layout: home
hero:
  name: Oref 3
  text: Flutter 的状态与资源
  tagline: 明确输入、共享实例、清晰所有权。尚未发布的 3.0.0-dev.1 开发 API。
  actions:
    - theme: brand
      text: 快速开始
      link: /zh/guide/getting-started
    - theme: alt
      text: 资源共享
      link: /zh/guide/sharing
features:
  - title: 局部状态
    details: Value 与 Computed，由 Watch 和 StateBuilder 自动观察。
  - title: 读取与写入资源
    details: Query、Pages、Action、RemoteValue 各自管理明确的执行协议。
  - title: 可写模型字段
    details: 复用一个 Query 模型，统一乐观更新、回退与父级写锁。
  - title: 明确资源寿命
    details: 局部拥有、外部借用或通过 Navigator 上方的有界目录共享。
---

## 开发版本

本页对应尚未发布的 **3.0.0-dev.1**。通过源码 checkout 评估；pub.dev 现有版本 API 不同。
一个包提供 `oref.dart` 的 Dart 状态与资源，以及 `flutter.dart` 的完整 Flutter 适配器。
响应底座继续使用 alien_signals。

从[局部状态](/zh/guide/local-state)、[查询](/zh/guide/query)开始，或直接了解
[所有权](/zh/guide/flutter)和[会话共享](/zh/guide/sharing)。
源码提供完整双页面关注示例，包含模拟服务、乐观字段更新、失败回退与账号切换。
