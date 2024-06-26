import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/home_widgets/artist_of_day.dart';
import '../../../domain/entities/home_widgets/home_widget.dart';
import '../../../domain/entities/shuffle_mode.dart';
import '../../datasources/drift_database.dart';
import 'home_widget_model.dart';

class HomeArtistOfDayModel extends HomeArtistOfDay implements HomeWidgetModel {
  HomeArtistOfDayModel(
    int position,
    ShuffleMode shuffleMode,
  ) : super(
          position: position,
          shuffleMode: shuffleMode,
        );

  factory HomeArtistOfDayModel.fromDrift(DriftHomeWidget driftHomeWidget) {
    final type = driftHomeWidget.type.toHomeWidgetType();
    if (type != HomeWidgetType.artist_of_day) {
      throw TypeError();
    }

    final data = jsonDecode(driftHomeWidget.data);
    final shuffleMode = (data['shuffleMode'] as String).toShuffleMode();
    return HomeArtistOfDayModel(driftHomeWidget.position, shuffleMode);
  }

  factory HomeArtistOfDayModel.fromEntity(HomeWidget entity) {
    if (entity.type != HomeWidgetType.artist_of_day) {
      throw TypeError();
    }
    entity as HomeArtistOfDay;
    return HomeArtistOfDayModel(entity.position, entity.shuffleMode);
  }

  @override
  HomeWidgetsCompanion toDrift() {
    final data = {'shuffleMode': '$shuffleMode'};
    return HomeWidgetsCompanion(
      position: Value(position),
      type: Value(type.toString()),
      data: Value(json.encode(data)),
    );
  }
}
