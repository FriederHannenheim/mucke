import 'dart:io';
import 'dart:isolate';

import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/loop_mode.dart';
import '../../domain/entities/shuffle_mode.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../models/loop_mode_model.dart';
import '../models/queue_item_model.dart';
import '../models/shuffle_mode_model.dart';
import '../models/song_model.dart';
import 'music_data_source_contract.dart';

part 'moor_music_data_source.g.dart';

const String MOOR_ISOLATE = 'MOOR_ISOLATE';

@DataClassName('MoorArtist')
class Artists extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

@DataClassName('MoorAlbum')
class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get year => integer().nullable()();
}

@DataClassName('MoorSong')
class Songs extends Table {
  TextColumn get title => text()();
  TextColumn get albumTitle => text()();
  IntColumn get albumId => integer()();
  TextColumn get artist => text()();
  TextColumn get path => text()();
  IntColumn get duration => integer().nullable()();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
  BoolColumn get present => boolean().withDefault(const Constant(true))();

  TextColumn get previous => text().nullable()();
  TextColumn get next => text().nullable()();

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

@DataClassName('PersistentPlayerState')
class PlayerState extends Table {
  IntColumn get index => integer()();
  IntColumn get shuffleMode => integer().withDefault(const Constant(0))();
  IntColumn get loopMode => integer().withDefault(const Constant(0))();
}

@UseMoor(tables: [Artists, Albums, Songs, QueueEntries, PlayerState])
class MoorMusicDataSource extends _$MoorMusicDataSource implements MusicDataSource {
  /// Use MoorMusicDataSource in main isolate only.
  MoorMusicDataSource() : super(_openConnection());

  /// Used for testing with in-memory database.
  MoorMusicDataSource.withQueryExecutor(QueryExecutor e) : super(e);

  /// Used to connect to a database on another isolate.
  MoorMusicDataSource.connect(DatabaseConnection connection) : super.connect(connection);

  @override
  int get schemaVersion => 1;

  @override
  Future<List<AlbumModel>> getAlbums() async {
    return select(albums).get().then((moorAlbumList) =>
        moorAlbumList.map((moorAlbum) => AlbumModel.fromMoorAlbum(moorAlbum)).toList());
  }

  // TODO: insert can throw exception -> implications?
  @override
  Future<int> insertAlbum(AlbumModel albumModel) async {
    return await into(albums).insert(albumModel.toAlbumsCompanion());
  }

  @override
  Stream<List<SongModel>> get songStream {
    return select(songs).watch().map((moorSongList) =>
        moorSongList.map((moorSong) => SongModel.fromMoorSong(moorSong)).toList());
  }

  @override
  Future<List<SongModel>> getSongs() {
    return select(songs).get().then((moorSongList) =>
        moorSongList.map((moorSong) => SongModel.fromMoorSong(moorSong)).toList());
  }

  @override
  Stream<List<SongModel>> getAlbumSongStream(AlbumModel album) {
    return (select(songs)
          ..where((tbl) => tbl.albumId.equals(album.id))
          ..orderBy([
            (t) => OrderingTerm(expression: t.discNumber),
            (t) => OrderingTerm(expression: t.trackNumber)
          ]))
        .watch()
        .map((moorSongList) =>
            moorSongList.map((moorSong) => SongModel.fromMoorSong(moorSong)).toList());
  }

  @override
  Future<List<SongModel>> getSongsFromAlbum(AlbumModel album) {
    return (select(songs)
          ..where((tbl) => tbl.albumTitle.equals(album.title))
          ..orderBy([
            (t) => OrderingTerm(expression: t.discNumber),
            (t) => OrderingTerm(expression: t.trackNumber)
          ]))
        .get()
        .then((moorSongList) =>
            moorSongList.map((moorSong) => SongModel.fromMoorSong(moorSong)).toList());
  }

  @override
  Future<void> insertSong(SongModel songModel) async {
    await into(songs).insert(songModel.toSongsCompanion());
  }

  @override
  Future<SongModel> getSongByPath(String path) async {
    return (select(songs)..where((t) => t.path.equals(path))).getSingle().then(
      (moorSong) {
        if (moorSong == null) {
          return null;
        }
        return SongModel.fromMoorSong(moorSong);
      },
    );
  }

  @override
  Future<void> deleteAllArtists() async {
    delete(artists).go();
  }

  @override
  Future<int> insertArtist(ArtistModel artistModel) async {
    return into(artists).insert(artistModel.toArtistsCompanion());
  }

  @override
  Future<void> deleteAllAlbums() async {
    delete(albums).go();
  }

  @override
  Future<void> deleteAllSongs() async {
    delete(songs).go();
  }

  @override
  Future<List<ArtistModel>> getArtists() {
    return select(artists).get().then((moorArtistList) =>
        moorArtistList.map((moorArtist) => ArtistModel.fromMoorArtist(moorArtist)).toList());
  }

  @override
  Future<void> insertSongs(List<SongModel> songModels) async {
    await update(songs).write(const SongsCompanion(present: Value(false)));

    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        songs,
        songModels.map((e) => e.toMoorInsert()).toList(),
      );
    });

    await (delete(songs)..where((tbl) => tbl.present.equals(false))).go();
  }

  @override
  Future<void> setSongBlocked(SongModel song, bool blocked) async {
    await (update(songs)..where((tbl) => tbl.path.equals(song.path)))
        .write(SongsCompanion(blocked: Value(blocked)));
  }

  // EXPLORATORY CODE!!!
  @override
  Future<void> toggleNextSongLink(SongModel song) async {
    if (song.next == null) {
      final albumSongs = await (select(songs)
            ..where((tbl) => tbl.albumId.equals(song.albumId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.discNumber),
              (t) => OrderingTerm(expression: t.trackNumber)
            ]))
          .get()
          .then((moorSongList) =>
              moorSongList.map((moorSong) => SongModel.fromMoorSong(moorSong)).toList());

      bool current = false;
      SongModel nextSong;
      for (final s in albumSongs) {
        if (current) {
          nextSong = s;
          break;
        }
        if (s.path == song.path) {
          current = true;
        }
      }
      await (update(songs)..where((tbl) => tbl.path.equals(song.path)))
          .write(SongsCompanion(next: Value(nextSong.path)));
    } else {
      await (update(songs)..where((tbl) => tbl.path.equals(song.path)))
          .write(const SongsCompanion(next: Value(null)));
    }
  }

  @override
  Stream<List<SongModel>> get songQueueStream {
    final query = (select(queueEntries)..orderBy([(t) => OrderingTerm(expression: t.index)]))
        .join([innerJoin(songs, songs.path.equalsExp(queueEntries.path))]);

    return query.watch().map((rows) {
      return rows.map((row) => SongModel.fromMoorSong(row.readTable(songs))).toList();
    });
  }

  @override
  Stream<List<QueueItemModel>> get queueStream {
    final query = (select(queueEntries)..orderBy([(t) => OrderingTerm(expression: t.index)]))
        .join([innerJoin(songs, songs.path.equalsExp(queueEntries.path))]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return QueueItemModel(
          SongModel.fromMoorSong(row.readTable(songs)),
          originalIndex: row.readTable(queueEntries).originalIndex,
          type: row.readTable(queueEntries).type.toQueueItemType(),
        );
      }).toList();
    });
  }

  @override
  Future<void> setQueue(List<QueueItemModel> queue) async {
    final _queueEntries = <Insertable<MoorQueueEntry>>[];

    for (var i = 0; i < queue.length; i++) {
      _queueEntries.add(QueueEntriesCompanion(
        index: Value(i),
        path: Value(queue[i].song.path),
        originalIndex: Value(queue[i].originalIndex),
        type: Value(queue[i].type.toInt()),
      ));
    }

    await delete(queueEntries).go();
    await batch((batch) {
      batch.insertAll(queueEntries, _queueEntries);
    });
  }

  @override
  Stream<int> get currentIndexStream {
    return select(playerState).watchSingle().map((event) => event.index);
  }

  @override
  Future<void> setCurrentIndex(int index) async {
    final currentState = await select(playerState).getSingle();
    if (currentState != null) {
      update(playerState).write(PlayerStateCompanion(index: Value(index)));
    } else {
      into(playerState).insert(PlayerStateCompanion(index: Value(index)));
    }
  }

  @override
  Stream<LoopMode> get loopModeStream {
    return select(playerState).watchSingle().map((event) => event.loopMode.toLoopMode());
  }

  @override
  Future<void> setLoopMode(LoopMode loopMode) async {
    final currentState = await select(playerState).getSingle();
    if (currentState != null) {
      update(playerState).write(PlayerStateCompanion(loopMode: Value(loopMode.toInt())));
    } else {
      into(playerState).insert(PlayerStateCompanion(loopMode: Value(loopMode.toInt())));
    }
  }

  @override
  Future<void> setShuffleMode(ShuffleMode shuffleMode) async {
    final currentState = await select(playerState).getSingle();
    if (currentState != null) {
      update(playerState).write(PlayerStateCompanion(shuffleMode: Value(shuffleMode.toInt())));
    } else {
      into(playerState).insert(PlayerStateCompanion(shuffleMode: Value(shuffleMode.toInt())));
    }
  }

  @override
  Stream<ShuffleMode> get shuffleModeStream {
    return select(playerState).watchSingle().map((event) => event.shuffleMode.toShuffleMode());
  }
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
