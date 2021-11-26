import '../entities/loop_mode.dart';
import '../entities/queue_item.dart';
import '../entities/shuffle_mode.dart';
import '../entities/song.dart';

abstract class PersistentStateRepository {
  Future<List<QueueItem>> get queueItems;
  Future<List<Song>> get originalSongs;
  Future<List<Song>> get addedSongs;  
  Future<int> get currentIndex;

  Future<LoopMode> get loopMode;
  Future<ShuffleMode> get shuffleMode;
  Future<bool> get excludeBlocked;
  Future<bool> get excludeSkipped;
  Future<bool> get respectSongLinks;

  void setShuffleMode(ShuffleMode shuffleMode);
  void setLoopMode(LoopMode loopMode);
  void setQueue(List<QueueItem> queue);
  void setOriginalSongs(List<Song> songs);
  void setAddedSongs(List<Song> songs);
  void setCurrentIndex(int index);
  void setExcludeBlocked(bool active);
  void setExcludeSkipped(bool active);
  void setRespectSongLinks(bool active);
}
