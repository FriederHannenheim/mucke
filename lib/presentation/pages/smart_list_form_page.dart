import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:reorderables/reorderables.dart';

import '../../constants.dart';
import '../../domain/entities/smart_list.dart';
import '../state/navigation_store.dart';
import '../state/settings_store.dart';
import '../state/smart_list_form_store.dart';
import '../theming.dart';
import 'smart_lists_artists_page.dart';

class SmartListFormPage extends StatefulWidget {
  const SmartListFormPage({Key? key, this.smartList}) : super(key: key);

  final SmartList? smartList;

  @override
  _SmartListFormPageState createState() => _SmartListFormPageState();
}

class _SmartListFormPageState extends State<SmartListFormPage> {
  late SmartListFormStore store;

  @override
  void initState() {
    store = GetIt.I<SmartListFormStore>(param1: widget.smartList);
    super.initState();
    store.setupValidations();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.smartList == null ? 'Create smart list' : 'Edit smart list';
    final SettingsStore settingsStore = GetIt.I<SettingsStore>();
    final NavigationStore navStore = GetIt.I<NavigationStore>();

    const blockLevelTexts = <String>[
      'Exclude all songs marked for exclusion.',
      'Exclude songs marked for exclusion in shuffle mode.',
      'Exclude only songs marked as always exclude.',
      "Don't exclude any songs.",
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TEXT_HEADER,
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => navStore.pop(context),
          ),
          actions: [
            if (widget.smartList != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // TODO: this works, but may only pop back to the smart list page...
                  // can I use pop 2x here?
                  await settingsStore.removeSmartList(widget.smartList!);
                  navStore.pop(context);
                },
              ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                store.validateAll();
                if (!store.error.hasErrors) {
                  await store.save();
                  navStore.pop(context);
                }
              },
            ),
          ],
          titleSpacing: 0.0,
        ),
        body: ListTileTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) => TextFormField(
                          initialValue: store.name,
                          onChanged: (value) => store.name = value,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            errorText: store.error.name,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          final RangeValues _currentRangeValues = RangeValues(
                              store.minLikeCount.toDouble(), store.maxLikeCount.toDouble());
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Likes between ${store.minLikeCount} and ${store.maxLikeCount}'),
                              RangeSlider(
                                values: _currentRangeValues,
                                min: 0,
                                max: MAX_LIKE_COUNT.toDouble(),
                                divisions: MAX_LIKE_COUNT,
                                labels: RangeLabels(
                                  _currentRangeValues.start.round().toString(),
                                  _currentRangeValues.end.round().toString(),
                                ),
                                onChanged: (RangeValues values) {
                                  store.minLikeCount = values.start.toInt();
                                  store.maxLikeCount = values.end.toInt();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.minPlayCountEnabled,
                                onChanged: (bool value) => store.minPlayCountEnabled = value,
                              ),
                              const Text('Minimum play count'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.minPlayCountEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.minPlayCount,
                                  onChanged: (value) {
                                    store.minPlayCount = value;
                                  },
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    errorText: store.error.minPlayCount,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.maxPlayCountEnabled,
                                onChanged: (bool value) => store.maxPlayCountEnabled = value,
                              ),
                              const Text('Maximum play count'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.maxPlayCountEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.maxPlayCount,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    store.maxPlayCount = value;
                                  },
                                  decoration: InputDecoration(
                                    errorText: store.error.maxPlayCount,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.minSkipCountEnabled,
                                onChanged: (bool value) => store.minSkipCountEnabled = value,
                              ),
                              const Text('Minimum skip count'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.minSkipCountEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.minSkipCount,
                                  onChanged: (value) {
                                    store.minSkipCount = value;
                                  },
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    errorText: store.error.minSkipCount,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.maxSkipCountEnabled,
                                onChanged: (bool value) => store.maxSkipCountEnabled = value,
                              ),
                              const Text('Maximum skip count'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.maxSkipCountEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.maxSkipCount,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    store.maxSkipCount = value;
                                  },
                                  decoration: InputDecoration(
                                    errorText: store.error.maxSkipCount,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.minYearEnabled,
                                onChanged: (bool value) => store.minYearEnabled = value,
                              ),
                              const Text('Minimum year'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.minYearEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.minYear,
                                  onChanged: (value) {
                                    store.minYear = value;
                                  },
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    errorText: store.error.minYear,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.maxYearEnabled,
                                onChanged: (bool value) => store.maxYearEnabled = value,
                              ),
                              const Text('Maximum year'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.maxYearEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.maxYear,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    store.maxYear = value;
                                  },
                                  decoration: InputDecoration(
                                    errorText: store.error.maxYear,
                                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.limitEnabled,
                                onChanged: (bool value) => store.limitEnabled = value,
                              ),
                              const Text('Limit number of songs'),
                              const Spacer(),
                              SizedBox(
                                width: 36.0,
                                child: TextFormField(
                                  enabled: store.limitEnabled,
                                  keyboardType: TextInputType.number,
                                  initialValue: store.limit,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    store.limit = value;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return DropdownButton<int>(
                            value: store.blockLevel,
                            hint: const Text('Select which songs to exclude.'),
                            isExpanded: true,
                            onChanged: (int? newValue) {
                              if (newValue != null) store.blockLevel = newValue;
                            },
                            items: <int>[0, 1, 2, 3].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  blockLevelTexts[value],
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) {
                          return Row(
                            children: [
                              Switch(
                                value: store.excludeArtists,
                                onChanged: (bool value) => store.excludeArtists = value,
                              ),
                              const Text('Exclude selected artists'),
                              const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                      child: Observer(
                        builder: (_) => GestureDetector(
                          onTap: () {
                            navStore.push(
                              context,
                              MaterialPageRoute<Widget>(
                                builder: (BuildContext context) =>
                                    SmartListArtistsPage(formStore: store),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const SizedBox(width: 60.0, height: 36),
                              Text(
                                  'Select artists to ${store.excludeArtists ? "exclude" : "include"} (${store.selectedArtists.length} selected)'),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    const ListTile(
                      title: Text('Order settings', style: TEXT_HEADER),
                    ),
                  ],
                ),
              ),
              Observer(
                builder: (_) => ReorderableSliverList(
                  delegate: ReorderableSliverChildBuilderDelegate(
                    (context, int i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HORIZONTAL_PADDING,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            Switch(
                              value: store.orderState[i].enabled,
                              onChanged: (bool value) => store.setOrderEnabled(i, value),
                            ),
                            Text(store.orderState[i].text),
                            const Spacer(),
                            IconButton(
                              icon: store.orderState[i].orderDirection == OrderDirection.ascending
                                  ? const Icon(Icons.arrow_upward)
                                  : const Icon(Icons.arrow_downward),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 8.0,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => store.toggleOrderDirection(i),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: store.orderState.length,
                  ),
                  onReorder: (oldIndex, newIndex) => store.reorderOrderState(oldIndex, newIndex),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}