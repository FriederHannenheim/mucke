import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/song.dart';
import '../state/audio_store.dart';
import '../state/music_data_store.dart';
import '../widgets/song_bottom_sheet.dart';
import '../widgets/song_list_tile.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({Key key}) : super(key: key);

  @override
  _SongsPageState createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    print('SongsPage.build');
    final MusicDataStore musicDataStore = Provider.of<MusicDataStore>(context);
    final AudioStore audioStore = Provider.of<AudioStore>(context);

    super.build(context);
    return Observer(builder: (_) {
      print('SongsPage.build -> Observer.builder');

      final songStream = musicDataStore.songStream;

      switch (songStream.status) {
        case StreamStatus.active:
          final List<Song> songs = songStream.value;
          return ListView.separated(
            itemCount: songs.length,
            itemBuilder: (_, int index) {
              final Song song = songs[index];
              return SongListTile(
                song: song,
                showAlbum: true,
                onTap: () => audioStore.playSong(index, songs),
                onTapMore: () => SongBottomSheet()(song, context),
              );
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(
              height: 4.0,
            ),
          );
        case StreamStatus.waiting:
        case StreamStatus.done:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              CircularProgressIndicator(),
              Text('Loading items...'),
            ],
          );
      }
      return Container();
    });
  }

  @override
  bool get wantKeepAlive => true;
}
