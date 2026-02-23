/// Arama ekranı ve SearchDelegate implementasyonu
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state_widget.dart';

/// Flutter SearchDelegate implementasyonu - üst çubuktan arama
class NoteSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  NoteSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => AppStrings.search;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(PhosphorIconsRegular.arrowLeft),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(query: query);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const EmptyStateWidget(
        title: 'Search Notes',
        subtitle: 'Type to search your notes',
        icon: PhosphorIconsRegular.magnifyingGlass,
      );
    }
    return _SearchResults(query: query);
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      data: (notes) => notes.isEmpty
          ? EmptyStateWidget(
              title: 'No results for "$query"',
              subtitle: 'Try different keywords',
              icon: PhosphorIconsRegular.magnifyingGlass,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (ctx, i) => NoteCard(note: notes[i], key: ValueKey(notes[i].id)),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
