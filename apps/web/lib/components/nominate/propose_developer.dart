import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../layout/site_header.dart';
import 'modal_shell.dart';

final _username = RegExp(r'^(?:https?://)?(?:www\.)?(?:github\.com/)?@?([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/?$');

/// Nominate a developer for the Hall of Fame.
class ProposeDeveloper extends StatefulComponent {
  const ProposeDeveloper({required this.onClose, super.key});

  final void Function() onClose;

  @override
  State<ProposeDeveloper> createState() => _ProposeDeveloperState();
}

class _ProposeDeveloperState extends State<ProposeDeveloper> {
  String _gh = '';
  String _why = '';
  bool _tried = false;
  bool _done = false;

  String get _user => _username.firstMatch(_gh.trim())?[1] ?? '';

  void _submit() {
    if (_user.isEmpty) return setState(() => _tried = true);
    web.window.open(
      nominationIssueUrl(
        sourceUrl,
        template: 'nominate-developer.yml',
        title: 'Hall of Fame nomination: $_user',
        fields: {'username': _user, 'reason': _why},
      ),
      '_blank',
    );
    setState(() => _done = true);
  }

  @override
  Component build(BuildContext context) {
    final raw = _gh.trim();
    final bad = ((_tried || raw.length > 3) && _user.isEmpty && raw.isNotEmpty) || (_tried && raw.isEmpty);
    return ModalShell(
      width: 520,
      onClose: component.onClose,
      children: _done
          ? [
              modalDone(
                'Almost there',
                'Finish submitting the issue on GitHub to nominate @$_user. The editorial team reviews nominations '
                    'before each edition.',
                component.onClose,
              ),
            ]
          : [
              modalHead(
                'Propose a developer',
                'Nominations are reviewed by the editorial team before each edition.',
                component.onClose,
              ),
              div(classes: 'modal-body', [
                label(classes: 'field', [
                  span(classes: 'field-label', [.text('GitHub profile')]),
                  div(styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': '10px'}), [
                    div(
                      styles: Styles(
                        raw: {
                          'width': '44px',
                          'height': '44px',
                          'border-radius': '50%',
                          'flex-shrink': '0',
                          'box-shadow': '0 0 0 1px var(--line)',
                          'background': _user.isEmpty
                              ? 'var(--surface2)'
                              : 'var(--surface2) url(https://github.com/$_user.png?size=88) center/cover no-repeat',
                        },
                      ),
                      [],
                    ),
                    div(classes: 'field-box', styles: Styles(raw: {'flex': '1'}), [
                      span(classes: 'field-prefix', [.text('github.com/')]),
                      input<String>(
                        value: _gh,
                        attributes: {'placeholder': 'username', 'autofocus': ''},
                        onInput: (v) => setState(
                          () => _gh = v
                              .replaceFirst(
                                RegExp(r'^\s*(?:https?://)?(?:www\.)?github\.com/', caseSensitive: false),
                                '',
                              )
                              .replaceFirst('@', ''),
                        ),
                      ),
                    ]),
                  ]),
                  span(classes: bad ? 'field-hint bad' : 'field-hint', [
                    .text(bad ? 'Enter a valid GitHub username.' : 'Their GitHub username.'),
                  ]),
                ]),
                label(classes: 'field', [
                  span(classes: 'field-label', [
                    .text('Why should they be inducted? '),
                    i([.text('(optional)')]),
                  ]),
                  textarea(
                    rows: 5,
                    attributes: {'maxlength': '600'},
                    placeholder: 'What have they built or done that shaped the Flutter ecosystem?',
                    onInput: (v) => setState(() => _why = v),
                    [.text(_why)],
                  ),
                  span(classes: 'field-hint', [.text('${_why.length} / 600')]),
                ]),
              ]),
              div(classes: 'modal-foot', [
                button(classes: 'modal-btn', type: ButtonType.button, onClick: component.onClose, [.text('Cancel')]),
                button(
                  classes: _user.isEmpty ? 'modal-btn go off' : 'modal-btn go',
                  type: ButtonType.button,
                  onClick: _submit,
                  [.text('Submit nomination')],
                ),
              ]),
            ],
    );
  }
}
