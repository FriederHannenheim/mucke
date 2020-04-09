import 'package:meta/meta.dart';
import 'package:mobx/mobx.dart';

import '../../domain/entities/song.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/music_data_repository.dart';

part 'audio_store.g.dart';

class AudioStore extends _AudioStore with _$AudioStore {
  AudioStore({@required MusicDataRepository musicDataRepository, @required AudioRepository audioRepository})
      : super(musicDataRepository, audioRepository);
}

abstract class _AudioStore with Store {
  _AudioStore(this._musicDataRepository, this._audioRepository);

  final MusicDataRepository _musicDataRepository;
  final AudioRepository _audioRepository;

  ReactionDisposer _disposer;

  @observable
  ObservableStream<Song> currentSong;

  @observable
  Song song;

  @action
  Future<void> init() async {
    currentSong = _audioRepository.watchCurrentSong.asObservable();

    _disposer = autorun((_) {
      updateSong(currentSong.value);
    });
  }

  void dispose() {
    _disposer();
  }

  @action
  Future<void> playSong(int index, List<Song> songList) async {
    _audioRepository.playSong(index, songList);
  }

  @action
  Future<void> updateSong(Song streamValue) async {
    print('updateSong');
    if (streamValue != null && streamValue != song) {
      print('actually updating...');
      song = streamValue;
    }
  }

}