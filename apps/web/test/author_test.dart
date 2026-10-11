import 'package:fv_core/fv_core.dart';
import 'package:fv_web/data/author.dart';
import 'package:test/test.dart';

void main() {
  final rows = [
    const ProjectRow(id: 'bloc', name: 'bloc', owner: 'felangel', publisher: 'bloclibrary.dev', stars: 100),
    const ProjectRow(id: 'flutter_bloc', name: 'flutter_bloc', owner: 'FelAngel', stars: 300),
    const ProjectRow(id: 'mason', name: 'mason', owner: 'felangel', stars: 200),
    const ProjectRow(id: 'bloc_test', name: 'bloc_test', publisher: 'bloclibrary.dev', stars: 50),
    const ProjectRow(id: 'dio', name: 'dio', owner: 'cfug', stars: 999),
  ];
  final byAuthor = authorIndex(rows);
  List<String> ids(List<ProjectRow> rs) => [for (final r in rs) r.id];

  test('matches the owner case-insensitively, most starred first', () {
    expect(ids(moreByAuthor(rows[2], byAuthor)), ['flutter_bloc', 'bloc']);
  });

  test('matches the publisher too, without repeats or the project itself', () {
    expect(ids(moreByAuthor(rows[0], byAuthor)), ['flutter_bloc', 'mason', 'bloc_test']);
  });

  test('leaves out excluded projects and stops at max', () {
    expect(ids(moreByAuthor(rows[0], byAuthor, exclude: {'flutter_bloc'}, max: 1)), ['mason']);
  });

  test('is empty for an author with one project', () {
    expect(moreByAuthor(rows[4], byAuthor), isEmpty);
  });
}
