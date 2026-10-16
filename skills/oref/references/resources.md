# Resources

Construction sends no request. Only synchronous reads inside source establish
input dependencies. Inputs are immutable snapshots compared with Dart ==.
Loaders, writers, and Action.execute run untracked. Keep source cheap.

Query.ensureLoaded reuses the active/latest attempt, including failures; retry
with refresh. Same-input refresh retains the previous value. New source clears
old display and rejects stale reads. hasValue distinguishes valid null from
unknown state.

Pages uses a nonnullable cursor type and nullable next cursor. The loader returns
the new page, and nextCursor returns null at the end. Empty pages must end;
repeating a cursor is an error. Refresh supersedes append and reloads only page
one. nextError is separate from first-page/refresh error. Existing items survive
append failures. Exhausted loadMore performs zero HTTP.

Action runs only through run(arguments). Accepted immutable arguments are the
operation snapshot. A busy instance rejects new writes without queuing or
merging. New operations clear old result/error. Accepted writes settle even after
disposal, without publishing state. Include account identity and credentials in
arguments when needed.

RemoteValue.set/update optimistically show desired state and roll back failures.
Canonical write returns a confirmed value; ack adopts desired on acknowledgment.
Independent set/update require a known value and do not implicitly read. Seed tags initial
data with source and is consumed once. accept supplies authoritative data when
the source matches and no operation is busy. Independent identity can preserve
value across transport-token changes.

Query.field/fieldAck shares its parent model, source, read, lock, and entry.
select projects the field, apply immutably replaces only that field, and write
saves it. Writes supersede old GETs; reads during a write return busy. Query source
changes, including tokens, clear the model. Fields have no separate seed,
identity, GET, TTL, or cache entry. Family.field/fieldAck defines a field once.

All operations return native Future. Await/catch, register an error handler, or
explicitly ignore when rendering state.error. Business errors and stacks are
preserved. ResourceException carries busy/disposed/notReady/noReader/
sourceChanged/superseded; ignore only reasons expected for the call's lifecycle.
Only control errors produced by the current resource itself are excluded from
business error state. An accepted writer's returned error, even a ResourceException
from a delegated operation, remains its business failure and triggers rollback.
Automatic starts ignore their Future errors while exposing state.error.
ReadRequest.onCancel must connect to actual HTTP cancellation to stop traffic;
rejecting a stale result alone does not abort transport.
