import 'package:alien_signals/alien_signals.dart';
import 'package:flutter/foundation.dart' show internal;

class _EffectStopLink {
  _EffectStopLink({required this.callback, _EffectStopLink? head}) {
    this.head = head ?? this;
  }

  final void Function() callback;

  _EffectStopLink? next;
  late _EffectStopLink head;
}

final _links = Expando<_EffectStopLink>("oref:core.lifecycle");

void _registerEffectStopCallback(ReactiveNode sub, void Function() callback) {
  final prev = _links[sub], head = prev?.head;
  final link = _EffectStopLink(callback: callback, head: head);

  prev?.next = link;
  _links[sub] = link;
}

void onEffectStop(void Function() callback) {
  final sub = getCurrentSub();

  assert(sub != null, "onEffectStop can only be called inside an effect");
  if (sub != null) {
    _registerEffectStopCallback(sub, callback);
  }
}

@internal
void triggerEffectStopCallback(ReactiveNode sub) {
  _EffectStopLink? link = _links[sub]?.head;
  _links[sub] = null;

  while (link != null) {
    try {
      link.callback();
    } catch (_) {}
    link = link.next;
  }

  for (Link? link = sub.subs; link != null; link = link.nextSub) {
    triggerEffectStopCallback(link.sub);
  }
}
