import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'propose_developer.dart';
import 'propose_project.dart';

/// Hosts the nomination dialogs. Any element with
/// `data-open-modal="propose-developer"` or `"propose-project"` opens one,
/// so the buttons themselves can stay static markup.
@client
class Nominations extends StatefulComponent {
  const Nominations({required this.categories, super.key});

  /// Existing Hall of Fame award categories.
  final List<String> categories;

  @override
  State<Nominations> createState() => _NominationsState();
}

class _NominationsState extends State<Nominations> {
  String? _open;
  JSFunction? _onClick, _onKey;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _onClick = ((web.MouseEvent e) {
      final t = e.target;
      final trigger = t != null && t.isA<web.Element>() ? (t as web.Element).closest('[data-open-modal]') : null;
      if (trigger == null) return;
      e.preventDefault();
      setState(() => _open = trigger.getAttribute('data-open-modal'));
    }).toJS;
    _onKey = ((web.KeyboardEvent e) {
      if (e.key == 'Escape' && _open != null) setState(() => _open = null);
    }).toJS;
    web.document.addEventListener('click', _onClick);
    web.document.addEventListener('keydown', _onKey);
  }

  @override
  void dispose() {
    if (_onClick != null) web.document.removeEventListener('click', _onClick);
    if (_onKey != null) web.document.removeEventListener('keydown', _onKey);
    super.dispose();
  }

  void _close() => setState(() => _open = null);

  @override
  Component build(BuildContext context) {
    return switch (_open) {
      'propose-developer' => ProposeDeveloper(onClose: _close),
      'propose-project' => ProposeProject(categories: component.categories, onClose: _close),
      _ => const Component.empty(),
    };
  }
}
