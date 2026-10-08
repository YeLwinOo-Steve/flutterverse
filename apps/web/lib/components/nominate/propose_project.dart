import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../layout/site_header.dart';
import 'category_combo.dart';
import 'modal_shell.dart';

final _repo = RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$');

/// Nominate a project for the Hall of Fame under an award category.
class ProposeProject extends StatefulComponent {
  const ProposeProject({required this.categories, required this.onClose, super.key});

  final List<String> categories;
  final void Function() onClose;

  @override
  State<ProposeProject> createState() => _ProposeProjectState();
}

class _ProposeProjectState extends State<ProposeProject> {
  String _repoText = '';
  String _query = '';
  String _category = '';
  String _why = '';
  bool _menu = false;
  int _highlight = 0;
  bool _tried = false;
  bool _done = false;

  String get _repoValue => _repoText.trim();
  bool get _repoOk => _repo.hasMatch(_repoValue);
  bool get _ok => _repoOk && _category.isNotEmpty;

  void _submit() {
    if (!_ok) return setState(() => _tried = true);
    web.window.open(
      nominationIssueUrl(
        sourceUrl,
        template: 'nominate-project.yml',
        title: 'Hall of Fame nomination: $_repoValue ($_category)',
        fields: {'repo': _repoValue, 'category': _category, 'reason': _why},
      ),
      '_blank',
    );
    setState(() => _done = true);
  }

  @override
  Component build(BuildContext context) {
    final repoBad = (_tried && !_repoOk) || (_repoValue.contains('/') && !_repoOk);
    return ModalShell(
      onClose: component.onClose,
      onBackgroundClick: () {
        if (_menu) setState(() => _menu = false);
      },
      children: _done
          ? [
              modalDone(
                'Almost there',
                'Finish submitting the issue on GitHub to propose $_repoValue for $_category. The editorial team '
                    'reviews nominations before each edition.',
                component.onClose,
              ),
            ]
          : [
              modalHead(
                'Propose a project',
                'Nominate an open-source project or app for the Hall of Fame.',
                component.onClose,
              ),
              div(classes: 'modal-body', [
                label(classes: 'field', [
                  span(classes: 'field-label', [.text('GitHub repository')]),
                  div(classes: 'field-box', [
                    span(classes: 'field-prefix', [.text('github.com/')]),
                    input<String>(
                      value: _repoText,
                      attributes: {'placeholder': 'owner/repo', 'autofocus': ''},
                      onInput: (v) => setState(
                        () => _repoText = v
                            .replaceFirst(RegExp(r'^\s*(?:https?://)?(?:www\.)?github\.com/', caseSensitive: false), '')
                            .replaceFirst(RegExp(r'\.git$|/$'), ''),
                      ),
                    ),
                  ]),
                  span(classes: repoBad ? 'field-hint bad' : 'field-hint', [
                    .text(repoBad ? 'Use the owner/repo format, e.g. felangel/bloc.' : 'Owner and repository name.'),
                  ]),
                ]),
                CategoryCombo(
                  categories: component.categories,
                  query: _query,
                  selected: _category,
                  menuOpen: _menu,
                  highlight: _highlight,
                  onQuery: (v) => setState(() {
                    _query = v;
                    _category = '';
                    _menu = true;
                    _highlight = 0;
                  }),
                  onPick: (c) => setState(() {
                    _category = c;
                    _query = c;
                    _menu = false;
                    _highlight = 0;
                  }),
                  onMenu: (open) => setState(() => _menu = open),
                  onHighlight: (n) => setState(() => _highlight = n),
                ),
                label(classes: 'field', [
                  span(classes: 'field-label', [
                    .text('Why should it be inducted? '),
                    i([.text('(optional)')]),
                  ]),
                  textarea(
                    rows: 4,
                    placeholder: 'What impact has it had on the Flutter ecosystem?',
                    onInput: (v) => setState(() => _why = v),
                    [.text(_why)],
                  ),
                ]),
              ]),
              div(classes: 'modal-foot', [
                button(classes: 'modal-btn', type: ButtonType.button, onClick: component.onClose, [.text('Cancel')]),
                button(
                  classes: _ok ? 'modal-btn go' : 'modal-btn go off',
                  type: ButtonType.button,
                  onClick: _submit,
                  [.text('Submit nomination')],
                ),
              ]),
            ],
    );
  }
}
