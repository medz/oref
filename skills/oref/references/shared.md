# Sharing and ownership

Define Family once at the application assembly boundary. family(key) makes a
lazy reference without creating a resource. A Resources directory shares by
namespace, Family identity, and key equality. Distinct directories or Families
are independent.

Configure nonnegative maxIdle and retain explicitly at the root. Zero disables
idle retention. Choose limits for real model sizes and navigation; active UI and
unfinished writes are counted separately. Idle entries pause source observation.

ResourceScope.create owns its directory; value borrows an external one. Put the
scope above Navigator. Resource builders follow the same rule:

- create / remote ack owns, starts reads, and disposes.
- value only observes; its external owner starts/configures/disposes.
- shared borrows by ref, starts reads, and returns on unmount.

Actions never start automatically. Detach observation before releasing resources.
A pending accepted write pins its instance and lock after consumers leave;
reentry cannot create a second instance to bypass that lock.

Use a fresh opaque session identity at each login/logout, including relogin as
the same account. Refreshing a token within one session can preserve identity.
Credentials belong in operation input, not directory keys. Namespace transitions
rebind mounted shared builders even for equal refs and isolate old writes.

Outside widgets, resources.use(ref, callback) holds a borrow until the callback's
Future completes, releasing it in finally. After account-changing navigation,
resolve the ref again instead of using a captured old-session resource.
