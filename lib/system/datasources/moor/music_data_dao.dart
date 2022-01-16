import 'package:drift/drift.dart';

import '../../models/album_model.dart';
import '../../models/artist_model.dart';
import '../../models/song_model.dart';
import '../moor_database.dart';
import '../music_data_source_contract.dart';

part 'music_data_dao.g.dart';

@DriftAccessor(tables: [Albums, Artists, Songs, MoorAlbumOfDay, Playlists, PlaylistEntries])
class MusicDataDao extends DatabaseAccessor<MoorDatabase>
    with _$MusicDataDaoMixin
    implements MusicDataSource {
  MusicDataDao(MoorDatabase db) : super(db);

  @override
  Stream<List<SongModel>> get songStream {
    return (select(songs)..orderBy([(t) => OrderingTerm(expression: t.title)])).watch().map(
        (moorSongList) => moorSongList.map((moorSong) => SongModel.fromMoor(moorSong)).toList());
  }

  @override
  Stream<List<AlbumModel>> get albumStream {
    return (select(albums)..orderBy([(t) => OrderingTerm(expression: t.title)])).watch().map(
        (moorAlbumList) =>
            moorAlbumList.map((moorAlbum) => AlbumModel.fromMoor(moorAlbum)).toList());
  }

  @override
  Stream<List<ArtistModel>> get artistStream {
    return (select(artists)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch().map(
        (moorArtistList) =>
            moorArtistList.map((moorArtist) => ArtistModel.fromMoor(moorArtist)).toList());
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
            moorSongList.map((moorSong) => SongModel.fromMoor(moorSong)).toList());
  }

  @override
  Stream<List<AlbumModel>> getArtistAlbumStream(ArtistModel artist) {
    return (select(albums)
          ..where((tbl) => tbl.artist.equals(artist.name))
          ..orderBy([
            (t) => OrderingTerm(expression: t.title),
          ]))
        .watch()
        .map((moorAlbumList) {
      return moorAlbumList.map((moorAlbum) => AlbumModel.fromMoor(moorAlbum)).toList();
    });
  }

  @override
  Stream<List<SongModel>> getArtistSongStream(ArtistModel artist) {
    return (select(albums)..where((tbl) => tbl.artist.equals(artist.name)))
        .join([innerJoin(songs, songs.albumId.equalsExp(albums.id))])
        .map((row) => row.readTable(songs))
        .watch()
        .map(
          (moorSongList) => moorSongList.map((moorSong) => SongModel.fromMoor(moorSong)).toList(),
        );
  }

  

  @override
  Future<SongModel?> getSongByPath(String path) async {
    return (select(songs)..where((t) => t.path.equals(path))).getSingleOrNull().then(
          (moorSong) => moorSong == null ? null : SongModel.fromMoor(moorSong),
        );
  }

  @override
  Future<void> deleteAllArtists() async {
    delete(artists).go();
  }

  @override
  Future<void> deleteAllAlbums() async {
    delete(albums).go();
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
  Future<void> insertAlbums(List<AlbumModel> albumModels) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        albums,
        albumModels.map((e) => e.toAlbumsCompanion()).toList(),
      );
    });
  }

  @override
  Future<void> insertArtists(List<ArtistModel> artistModels) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        artists,
        artistModels.map((e) => e.toArtistsCompanion()).toList(),
      );
    });
  }

  @override
  Future<SongModel?> getPredecessor(SongModel song) async {
    final albumSongs = await (select(songs)
          ..where((tbl) => tbl.albumId.equals(song.albumId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.discNumber),
            (t) => OrderingTerm(expression: t.trackNumber)
          ]))
        .get()
        .then((moorSongList) =>
            moorSongList.map((moorSong) => SongModel.fromMoor(moorSong)).toList());

    SongModel? prevSong;
    for (final s in albumSongs) {
      if (s.path == song.path) {
        break;
      }
      prevSong = s;
    }
    return prevSong;
  }

  @override
  Future<SongModel?> getSuccessor(SongModel song) async {
    final albumSongs = await (select(songs)
          ..where((tbl) => tbl.albumId.equals(song.albumId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.discNumber),
            (t) => OrderingTerm(expression: t.trackNumber)
          ]))
        .get()
        .then((moorSongList) =>
            moorSongList.map((moorSong) => SongModel.fromMoor(moorSong)).toList());

    bool current = false;
    SongModel? nextSong;
    for (final s in albumSongs) {
      if (current) {
        nextSong = s;
        break;
      }
      if (s.path == song.path) {
        current = true;
      }
    }
    return nextSong;
  }

  @override
  Future<void> updateSong(SongModel songModel) async {
    await (update(songs)..where((tbl) => tbl.path.equals(songModel.path)))
        .write(songModel.toSongsCompanion());
  }

  @override
  Future<AlbumOfDay?> getAlbumOfDay() async {
    final query = select(moorAlbumOfDay)
        .join([innerJoin(albums, albums.id.equalsExp(moorAlbumOfDay.albumId))]);

    return (query..limit(1)).getSingleOrNull().then(
      (result) {
        if (result == null) return null;
        return AlbumOfDay(
          AlbumModel.fromMoor(result.readTable(albums)),
          DateTime.fromMillisecondsSinceEpoch(
            result.readTable(moorAlbumOfDay).milliSecSinceEpoch,
          ),
        );
      },
    );
  }

  @override
  Future<void> setAlbumOfDay(AlbumOfDay albumOfDay) async {
    transaction(() async {
      await delete(moorAlbumOfDay).go();
      await into(moorAlbumOfDay).insert(
        MoorAlbumOfDayCompanion(
          albumId: Value(albumOfDay.albumModel.id),
          milliSecSinceEpoch: Value(albumOfDay.date.millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<List> search(String searchText, {int limit = 0}) async {
    List<dynamic> result = [];

    result += await (select(artists)
          ..where((tbl) => tbl.name.regexp(searchText, dotAll: true, caseSensitive: false)))
        .get()
        .then(
          (moorList) => moorList.map((moorArtist) => ArtistModel.fromMoor(moorArtist)).toList(),
        );

    result += await (select(albums)
          ..where((tbl) => tbl.title.regexp(searchText, dotAll: true, caseSensitive: false)))
        .get()
        .then(
          (moorList) => moorList.map((moorAlbum) => AlbumModel.fromMoor(moorAlbum)).toList(),
        );

    result += await (select(songs)
          ..where((tbl) => tbl.title.regexp(searchText, dotAll: true, caseSensitive: false)))
        .get()
        .then(
          (moorList) => moorList.map((moorSong) => SongModel.fromMoor(moorSong)).toList(),
        );

    if (limit <= 0) return result;
    return result.take(limit).toList();
  }
}
