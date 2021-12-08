import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class ChewieVideoPlayer extends StatefulWidget {
  const ChewieVideoPlayer({
    Key? key,
    required this.videoPlayerController,
    this.looping,
    this.autoplay,
    this.showControls,
    this.aspectRatio, // hot fix - make this required
  }) : super(key: key);

  final VideoPlayerController videoPlayerController;
  final bool? looping;
  final bool? autoplay;
  final bool? showControls;
  final double? aspectRatio;

  @override
  _ChewieVideoPlayerState createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _createChewieController();
  }

  @override
  void dispose() {
    _chewieController.dispose();
    debugPrint('---Disposed Chewie Controller ---');
    widget.videoPlayerController.dispose();
    debugPrint('---Disposed Video Player Controller ---');

    super.dispose();
  }

  Future<void> initVideoPlayer() async {
    await widget.videoPlayerController.initialize();
    _createChewieController();

    setState(() {});
  }

  void _createChewieController() {
    // Hot fix use webm width/height as aspect ratio
    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      aspectRatio: widget.aspectRatio ??
          widget.videoPlayerController.value
              .aspectRatio, // can comment this line out if using width/height
      autoInitialize:
          true, // display first frame of video, comment this out if await init
      looping: widget.looping ?? false,
      autoPlay: widget.autoplay ?? false,
      showControls: widget.showControls ?? true,
      showControlsOnInitialize: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
          ),
        );
      },
      placeholder: const Center(
        child: CircularProgressIndicator(),
      ),
    );
    debugPrint('---Created Chewie Controller---');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Chewie(controller: _chewieController),
    );
  }
}
