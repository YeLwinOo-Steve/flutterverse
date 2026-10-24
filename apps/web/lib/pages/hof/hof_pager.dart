import 'dart:async';

import 'package:jaspr/jaspr.dart';

import '../../components/ui/pager.dart';
import 'hof_filter.dart';

/// Page numbers for the Hall of Fame grid whose `data-hof-grid` is
/// [section]. [total] is its card count before any search, for the
/// pre-rendered page.
@client
class HofPager extends StatefulComponent {
  const HofPager({required this.section, required this.total, required this.pageSize, super.key});

  final String section;
  final int total;
  final int pageSize;

  @override
  State<HofPager> createState() => _HofPagerState();
}

class _HofPagerState extends State<HofPager> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _sub = hofChanges.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final s = component.section;
    final count = hofMatches(s) ?? component.total;
    return Pager(
      page: hofPage(s),
      pages: (count / component.pageSize).ceil(),
      anchor: '#hof-$s',
      onPage: (n) => setHofPage(s, n),
    );
  }
}
