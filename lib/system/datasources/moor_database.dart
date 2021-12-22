import 'dart:io';
import 'dart:isolate';

import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../constants.dart';
import 'moor/music_data_dao.dart';
import 'moor/persistent_state_dao.dart';
import 'moor/playlist_dao.dart';
import 'moor/settings_dao.dart';

part 'moor_database.g.dart';

const String MOOR_ISOLATE = 'MOOR_ISOLATE';

@DataClassName('MoorArtist')
class Artists extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

@DataClassName('MoorAlbum')
class Albums extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get year => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MoorSong')
class Songs extends Table {
  TextColumn get title => text()();
  TextColumn get albumTitle => text()();
  IntColumn get albumId => integer()();
  TextColumn get artist => text()();
  TextColumn get path => text()();
  IntColumn get duration => integer()();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get discNumber => integer()();
  IntColumn get trackNumber => integer()();
  IntColumn get year => integer().nullable()();
  IntColumn get blockLevel => integer().withDefault(const Constant(0))();
  IntColumn get likeCount => integer().withDefault(const Constant(0))();
  IntColumn get skipCount => integer().withDefault(const Constant(0))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  BoolColumn get present => boolean().withDefault(const Constant(true))();
  DateTimeColumn get timeAdded => dateTime().withDefault(currentDateAndTime)();

  TextColumn get previous => text().withDefault(const Constant(''))();
  TextColumn get next => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {path};
}

@DataClassName('MoorQueueEntry')
class QueueEntries extends Table {
  IntColumn get index => integer()();
  TextColumn get path => text()();
  IntColumn get originalIndex => integer()();
  IntColumn get type => integer()();

  @override
  Set<Column> get primaryKey => {index};
}

@DataClassName('OriginalSongEntry')
class OriginalSongEntries extends Table {
  IntColumn get index => integer()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {index};
}

@DataClassName('AddedSongEntry')
class AddedSongEntries extends Table {
  IntColumn get index => integer()();
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {index};
}

@DataClassName('KeyValueEntry')
class KeyValueEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class LibraryFolders extends Table {
  TextColumn get path => text()();
}

class MoorAlbumOfDay extends Table {
  IntColumn get albumId => integer()();
  IntColumn get milliSecSinceEpoch => integer()();

  @override
  Set<Column> get primaryKey => {albumId};
}

@DataClassName('MoorSmartList')
class SmartLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get shuffleMode => text().nullable()();

  // Filter
  BoolColumn get excludeArtists => boolean().withDefault(const Constant(false))();
  BoolColumn get excludeBlocked => boolean().withDefault(const Constant(false))();
  IntColumn get minLikeCount => integer().withDefault(const Constant(0))();
  IntColumn get maxLikeCount => integer().withDefault(const Constant(5))();
  IntColumn get minPlayCount => integer().nullable()();
  IntColumn get maxPlayCount => integer().nullable()();
  IntColumn get minSkipCount => integer().nullable()();
  IntColumn get maxSkipCount => integer().nullable()();
  IntColumn get minYear => integer().nullable()();
  IntColumn get maxYear => integer().nullable()();
  IntColumn get limit => integer().nullable()();

  // OrderBy
  TextColumn get orderCriteria => text()();
  TextColumn get orderDirections => text()();
}

@DataClassName('MoorSmartListArtist')
class SmartListArtists extends Table {
  IntColumn get smartListId => integer()();
  TextColumn get artistName => text()();
}

@DataClassName('MoorPlaylist')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DataClassName('MoorPlaylistEntry')
class PlaylistEntries extends Table {
  IntColumn get playlistId => integer()();
  TextColumn get songPath => text()();
  IntColumn get position => integer()();
}

@UseMoor(
  tables: [
    Albums,
    Artists,
    LibraryFolders,
    QueueEntries,
    OriginalSongEntries,
    AddedSongEntries,
    Songs,
    MoorAlbumOfDay,
    SmartLists,
    SmartListArtists,
    Playlists,
    PlaylistEntries,
    KeyValueEntries,
  ],
  daos: [
    PersistentStateDao,
    SettingsDao,
    MusicDataDao,
    PlaylistDao,
  ],
)
class MoorDatabase extends _$MoorDatabase {
  /// Use MoorMusicDataSource in main isolate only.
  MoorDatabase() : super(_openConnection());

  /// Used for testing with in-memory database.
  MoorDatabase.withQueryExecutor(QueryExecutor e) : super(e);

  /// Used to connect to a database on another isolate.
  MoorDatabase.connect(DatabaseConnection connection) : super.connect(connection);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (details) async {
        if (details.wasCreated) {
          await into(keyValueEntries).insert(
            const KeyValueEntriesCompanion(key: Value(PERSISTENT_INDEX), value: Value('0')),
          );
          await into(keyValueEntries).insert(
            const KeyValueEntriesCompanion(key: Value(PERSISTENT_LOOPMODE), value: Value('0')),
          );
          await into(keyValueEntries).insert(
            const KeyValueEntriesCompanion(key: Value(PERSISTENT_SHUFFLEMODE), value: Value('0')),
          );
        }
      }, onUpgrade: (Migrator m, int from, int to) async {
        print('$from -> $to');
        if (from == 1) {
          await m.createTable(smartLists);
          await m.createTable(smartListArtists);

          await m.addColumn(songs, songs.timeAdded);
          await m.addColumn(songs, songs.year);
          await m.alterTable(TableMigration(songs));

          final albumMap =
              await select(albums).get().then((value) => {for (var a in value) a.id: a.year});

          await transaction(() async {
            for (final album in albumMap.entries) {
              await (update(songs)..where((tbl) => tbl.albumId.equals(album.key)))
                  .write(SongsCompanion(year: Value(album.value)));
            }
          });
        }
        if (from < 3) {
          await m.alterTable(
            TableMigration(songs, columnTransformer: {
              songs.timeAdded: currentDateAndTime,
            }),
          );
        }
        if (from < 4) {
          await m.alterTable(TableMigration(smartLists));
          await m.createTable(playlists);
          await m.createTable(playlistEntries);
        }
        if (from < 5) {
          await m.addColumn(smartLists, smartLists.minSkipCount);
          await m.addColumn(smartLists, smartLists.maxSkipCount);
        }
        if (from < 6) {
          await (update(songs)..where((tbl) => tbl.likeCount.equals(3)))
              .write(const SongsCompanion(likeCount: Value(2)));
          await (update(songs)..where((tbl) => tbl.likeCount.equals(4)))
              .write(const SongsCompanion(likeCount: Value(3)));
          await (update(songs)..where((tbl) => tbl.likeCount.equals(5)))
              .write(const SongsCompanion(likeCount: Value(3)));
        }
      });
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final Directory dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

Future<MoorIsolate> createMoorIsolate() async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'db.sqlite');
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the MoorIsolate to this ReceivePort
  return await receivePort.first as MoorIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = VmDatabase(File(request.targetPath));
  // we're using MoorIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used MoorIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendMoorIsolate.send(moorIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);

  final SendPort sendMoorIsolate;
  final String targetPath;
}
