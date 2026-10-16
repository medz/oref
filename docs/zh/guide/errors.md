# Future、错误与取消

异步资源操作返回原生 Future。成功给业务结果；source、loader、writer、execute、update
失败保留原错误对象和堆栈。显式调用应 await/catch、登记 onError，或在 UI 显示 state.error 时
明确 ignore。自动启动会消费 Future 错误，state 仍保留 error/stackTrace。

```dart
try {
  await remote.update((current) => !current);
} on ResourceException catch (error) {
  if (error.reason != ResourceReason.busy) rethrow;
  // A competing operation already owns this instance's write lock.
} catch (error, stackTrace) {
  // Report the original business failure to your application's error UI/log.
  print('$error\n$stackTrace');
}
```

| ResourceReason | 含义 |
| --- | --- |
| busy | 本资源或父模型已有写锁。 |
| disposed | 资源或目录不再接受工作。 |
| notReady | 缺少可靠当前值或首屏。 |
| noReader | 显式刷新但没有 reader。 |
| sourceChanged | 操作或数据属于旧来源。 |
| superseded | 读取被更新的读取替代。 |

当前资源自身产生的控制拒绝不覆盖业务错误。已接受 writer 返回的任何错误，包括它委托
其他资源后收到的 ResourceException，都是本次写的原错误，应发布并按规则回退。
只忽略该调用寿命中明确预期的原因。
捕获过期异常不表示 HTTP 已停止。accept 是同步方法，直接抛错；异步操作中的同步回调错误
通过返回 Future 交付。

## 物理请求取消

ReadRequest 提供 reason（initial/refresh/append）、cancelled 和 onCancel。
登记实际 HTTP 请求的 abort，并在 finally 撤销登记。以下是传输接线片段，client 的
startRequest/abort/result 需映射到实际客户端：

```dart
load: (source, request) async {
  final call = client.startRequest(source);
  final cancellation = request.onCancel(call.abort);
  try {
    return await call.result;
  } finally {
    cancellation.dispose();
  }
},
```

已经取消后登记会立即调用一次。取消与撤销均幂等。不接 abort 也会拒收旧结果，
但旧物理 HTTP 仍可能消耗带宽。

## 寿命和重试成本

dispose 拒绝新操作、废弃读取并停止发布；已接受写仍结算。
超时不一定代表服务器没保存，默认不自动重试非幂等写。
ensureLoaded 缓存失败尝试；需要重试明确 refresh。搜索防抖放在输入 Value 之前，
Timer 由拥有者释放。默认没有自动重试、轮询或焦点恢复刷新。
