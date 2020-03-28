import 'package:flutter_test/flutter_test.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:mosh/system/datasources/moor_music_data_source.dart';
import 'package:mosh/system/models/album_model.dart';

import '../../test_constants.dart';

void main() {
  MoorMusicDataSource moorMusicDataSource;
  AlbumModel albumModel;

  setUp(() {
    moorMusicDataSource =
        MoorMusicDataSource.withQueryExecutor(VmDatabase.memory());

    albumModel = AlbumModel(
      title: TITLE_1,
      artist: ARTIST_1,
      albumArtPath: ALBUM_ART_PATH_1,
      year: YEAR_1,
    );
  });

  tearDown(() async {
    await moorMusicDataSource.close();
  });

  group('insertAlbum and getAlbums', () {
    test(
      'should return the album that was inserted',
      () async {
        // act
        moorMusicDataSource.insertAlbum(albumModel);
        // assert
        final List<AlbumModel> albums = await moorMusicDataSource.getAlbums();
        expect(albums.first, albumModel);
      },
    );
  });

  group('albumExists', () {
    test(
      'should return true when album exists in data source',
      () async {
        // arrange
        moorMusicDataSource.insertAlbum(albumModel);
        // act
        final bool result = await moorMusicDataSource.albumExists(albumModel);
        // assert
        assert(result);
      },
    );

    test(
      'should return false when album does not exists in data source',
      () async {
        // act
        final bool result = await moorMusicDataSource.albumExists(albumModel);
        // assert
        assert(!result);
      },
    );
  });
}