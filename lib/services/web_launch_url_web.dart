import 'package:web/web.dart' as web;

void clearWebLaunchUrlQuery() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}${location.hash}',
  );
}
