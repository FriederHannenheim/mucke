import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/entities/album.dart';
import '../../domain/entities/song.dart';
import '../utils.dart' as utils;

class AlbumSliverAppBar extends StatefulWidget {
  const AlbumSliverAppBar({
    Key? key,
    required this.album,
    required this.songs,
  }) : super(key: key);

  final Album album;
  final List<Song> songs;

  @override
  State<AlbumSliverAppBar> createState() => _AlbumSliverAppBarState();
}

class _AlbumSliverAppBarState extends State<AlbumSliverAppBar> {
  double get maxHeight => 220 + MediaQuery.of(context).padding.top;
  double get minHeight => kToolbarHeight + MediaQuery.of(context).padding.top;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: maxHeight - MediaQuery.of(context).padding.top,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      flexibleSpace: Header(
        album: widget.album,
        songs: widget.songs,
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: () => Navigator.pop(context),
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.more_vert),
      //     onPressed: () {},
      //   )
      // ],
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.album,
    required this.songs,
    required this.maxHeight,
    required this.minHeight,
  }) : super(key: key);

  final Album album;
  final List<Song> songs;
  final double maxHeight;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandRatio = _calculateExpandRatio(constraints);
        final expandRatio2 = _calculateExpandRatio2(constraints);
        final animation = AlwaysStoppedAnimation(expandRatio);
        final animation2 = AlwaysStoppedAnimation(expandRatio2);

        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: _buildBackground(album, animation, maxHeight, minHeight),
            ),
            _buildGradient(animation, context),
            _buildImage(album, animation, context),
            _buildTitle(album, songs, animation, animation2, context),
          ],
        );
      },
    );
  }

  double _calculateExpandRatio(BoxConstraints constraints) {
    var expandRatio = (constraints.maxHeight - minHeight) / (maxHeight - minHeight);
    if (expandRatio > 1.0) expandRatio = 1.0;
    if (expandRatio < 0.0) expandRatio = 0.0;
    return expandRatio;
  }

  double _calculateExpandRatio2(BoxConstraints constraints) {
    var expandRatio = (constraints.maxHeight - minHeight) / (maxHeight - minHeight);
    if (expandRatio > 1.0)
      expandRatio = 1.0;
    else if (expandRatio < 0.8)
      expandRatio = 0.0;
    else
      expandRatio = (expandRatio - 0.8) * 5;
    return expandRatio;
  }

  Align _buildTitle(
    Album album,
    List<Song> songs,
    Animation<double> animation,
    Animation<double> animation2,
    BuildContext context,
  ) {
    final totalDuration =
        songs.fold(const Duration(milliseconds: 0), (Duration d, s) => d + s.duration);

    return Align(
      alignment: AlignmentTween(
        begin: Alignment.center,
        end: Alignment.topLeft,
      ).evaluate(animation),
      child: Container(
        margin: EdgeInsets.only(
          top: Tween<double>(
            begin: MediaQuery.of(context).padding.top,
            end: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
          ).evaluate(animation),
          left: Tween<double>(begin: 56, end: 152).evaluate(animation),
          right: Tween<double>(begin: 56, end: 16).evaluate(animation),
          bottom: Tween<double>(begin: 0, end: 16).evaluate(animation),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              album.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tween<double>(begin: 16, end: 24).evaluate(animation),
                color: Colors.white,
                fontWeight: FontWeight.lerp(
                  FontWeight.w400,
                  FontWeight.w600,
                  Tween<double>(begin: 0, end: 1).evaluate(animation),
                ),
                
              ),
            ),
            Container(
              height: Tween<double>(begin: 0, end: 8).evaluate(animation),
              width: 10.0,
            ),
            Text(
              album.artist,
              style: TextStyle(
                fontSize: Tween<double>(begin: 0, end: 16).evaluate(animation),
                color:
                    Colors.white.withOpacity(Tween<double>(begin: 0, end: 1).evaluate(animation2)),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${album.pubYear.toString()} • ${songs.length} Songs • ${utils.msToTimeString(totalDuration)}',
              style: TextStyle(
                fontSize: Tween<double>(begin: 0, end: 13).evaluate(animation),
                color:
                    Colors.white.withOpacity(Tween<double>(begin: 0, end: 1).evaluate(animation2)),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Album album, Animation<double> animation, BuildContext context) {
    return Positioned(
      width: 120,
      height: 120,
      left: 16,
      top: Tween<double>(
        begin: kToolbarHeight + MediaQuery.of(context).padding.top + 96,
        end: kToolbarHeight + MediaQuery.of(context).padding.top,
      ).evaluate(animation),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 1)),
          ],
          image: DecorationImage(
              image: utils.getAlbumImage(album.albumArtPath),
              fit: BoxFit.contain,
              opacity: Tween<double>(begin: 0, end: 1).evaluate(animation)),
        ),
      ),
    );
  }

  Container _buildGradient(Animation<double> animation, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorTween(
                  begin: Theme.of(context).primaryColor,
                  end: Theme.of(context).primaryColor.withOpacity(0.2),
                ).evaluate(animation) ??
                Colors.transparent,
            ColorTween(
                  begin: Theme.of(context).primaryColor,
                  end: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
                ).evaluate(animation) ??
                Colors.transparent,
            ColorTween(
                  begin: Theme.of(context).primaryColor,
                  end: Theme.of(context).scaffoldBackgroundColor,
                ).evaluate(animation) ??
                Colors.transparent,
          ],
          stops: const [0, 0.7, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBackground(
    Album album,
    Animation<double> animation,
    double maxHeight,
    double minHeight,
  ) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: Image(
          image: utils.getAlbumImage(album.albumArtPath),
          fit: BoxFit.cover,
          opacity: animation,
        ),
      ),
    );
  }
}
