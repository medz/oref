# DevTools Refactor Memory

Start time: 2026-01-27 02:21:38 +0800
Last updated: 2026-01-27 02:28:06 +0800

**Must work continuously for at least six hours! No stopping is allowed! Continuous iteration and optimization!**

RAW:
发现一个非常严重的问题。widgets 根本没有按照最佳实践而言进行编写。存在
几十个文件，且大量内容是相同的。

    我认为我们应该对 devtools app 进行一次大规模重构。消除各种重复代码，并且应该按照 flutter 官方等最佳
    App 构建结构进行开发。例如现在的 hooks 之类的。pages 编写每个页面的自有逻辑。而 widgets 目录应该存放

通
用 widget而不是针对不同page的单独业务组件。这样重构下来，文件熟练应该不会有这么多，代码量也会大幅度
减少。

虽然这是 devtools app，但它也是一个正常 App，应该按照 App 的标准和结构最佳做法进行开发。我授予你了无限
权限，你现在可以对它进行大规模重构已实现最高的可维护性、最佳的代码实践、最少的代码幻觉、最高效的逻辑、
最已于维护实现。

另外，我推荐你自己编写一个记忆文件（因为你总是忘记）你还应该按照我们之前重构的最佳做法进行少量多次的重
构而不是一蹴而就。记忆文件我建议你每次开发完都需要你审视一下，因为记忆不是完全有效的，你前面发现一个事
情写入记忆，后面可能有新的发现。

重构完之后你应该进行无限轮的代码审视和App实现审视以确保代码是这个世界上最优秀的做法。

另外，我们不应该使用 part，并且按照 SDK 约束，你应该尽可能使用新的愈发特性和语法糖。

记忆文件中我建议你记录一下你的开始时间（精确到秒）和最新的操作时间。强制记忆，你本次任务的工作时间不得
少于六个小时！你现在拥有了完全的自主操作能力！祝你工作愉快！你无需询问我的任何操作，除非我主动暂停你。
否则你应该严格按照本次任务的时常进行开发。

我建议你在 AGENTS.md 中写下关于本次任务的重要约束和信息，以及本次任务的独立记忆文件位置。记住不允许暂
停本次任务或者向我询问任何东西！也不想允许提前完成这项工作，即使你提前重构开发完成了。没有到达工作时长
（基于记忆文件的时长约束）你也应该不断思考和观察 devtool app 并不断优化它。

## Purpose

- Refactor DevTools app into a maintainable Flutter app structure.
- Remove `part` usage entirely.
- Move feature-specific widgets into their feature/page modules.
- Keep `widgets/` for shared, reusable widgets only.
- Reduce file count and duplication, improve clarity.

## Current focus

- Replace `part`-based file splitting with explicit imports and module structure.
- Consolidate constants and shared data into fewer files.
- Move hooks into feature-local state modules.

## Notes

- Prefer small, iterative refactors with validation per step.
- Update this file after each meaningful refactor step.
- 2026-01-27 02:26:03 +0800: Added shared search hook and Live badge widget; updated signals/computed/collections search setup and replaced repeated Live pills across pages.
- 2026-01-27 02:28:06 +0800: Moved search hook under shared/hooks to align with app architecture.
