import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:neetchan/models/post.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/widgets/html_parser.dart';
import 'package:provider/provider.dart';

class PostDescription extends StatelessWidget {
  const PostDescription({
    Key? key,
    required this.sub,
    required this.com,
  }) : super(key: key);

  final String? sub;
  final String? com;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub != null) ...[
            Html(
              data: sub,
              style: {
                '#': Style(
                  fontSize: const FontSize(16),
                  maxLines: 1,
                ),
                's': Style(
                  backgroundColor: Colors.black,
                  color: Colors.black,
                  textDecoration: TextDecoration.none,
                ),
              },
            ),
          ],
          if (com != null) ...[
            Html(
              data: com,
              style: {
                '#': Style(
                  fontSize: const FontSize(13),
                  maxLines: 8,
                ),
                's': Style(
                  backgroundColor: Colors.black,
                  color: Colors.black,
                  textDecoration: TextDecoration.none,
                ),
              },
            ),
          ]
        ],
      ),
    );
  }
}

class SelectablePostDescription extends StatelessWidget {
  const SelectablePostDescription({
    Key? key,
    required this.sub,
    required this.com,
  }) : super(key: key);

  final String? sub;
  final String? com;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub != null) ...[
            Html(
              data: sub,
              style: {
                '#': Style(
                  fontSize: const FontSize(16),
                  maxLines: 1,
                ),
                '.quote': Style(
                  color: Colors.greenAccent.shade400,
                ),
                '.quotelink': Style(
                  color: Colors.purple,
                ),
              },
              customRender: {
                's': (RenderContext context, Widget child) {
                  var spoiler = context.tree.element!.text;
                  return SelectableText.rich(
                    TextSpan(
                      text: spoiler,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          debugPrint('--spoiler tapped: $spoiler --');
                        },
                      style: const TextStyle(
                          color: Colors.black, backgroundColor: Colors.black),
                    ),
                  );
                }
              },
            ),
          ],
          if (com != null) ...[
            ParseHtmlToText(com: com!),
          ]
        ],
      ),
    );
  }
}

// Retrives single reply to post
Future<Post> getReplyPost(BuildContext context, int no) async {
  final postList = Provider.of<ApiData>(context, listen: false).currentThread;
  // Find the post object with matching post no
  if (postList.isNotEmpty) {
    final replyPost = postList.firstWhere((post) => post.no == no);
    return replyPost;
  } else {
    throw Exception('Failed to find reply post');
  }
}

// Retrives all reply from post
Future<List<Post>> getAllReplyPost(
    BuildContext context, Set<int> replies) async {
  List<Post> replyPosts = [];
  for (int reply in replies) {
    final post = await getReplyPost(context, reply);
    replyPosts.add(post);
  }
  return replyPosts;
}

Future<void> repliesDialog(BuildContext context, Set<int> replies) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('REPLIES'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.close,
              ),
            ),
          ],
        ),
        //scrollable: true,
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        content: FutureBuilder(
          future: getAllReplyPost(context, replies),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else if (snapshot.hasData) {
              return buildReplies(snapshot.data);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      );
    },
  );
}

Widget buildReplies(List<Post> replies) {
  return SizedBox(
    width: double.maxFinite, //double.infinity, //double.minPositive,
    child: ListView.separated(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var item = replies[index];
        return ThreadItem(item: item);
      },
      separatorBuilder: (context, index) =>
          const Divider(thickness: 1.0, height: 0),
      itemCount: replies.length,
    ),
  );
}

class SpoilerText extends StatefulWidget {
  const SpoilerText(
    this.spoiler, {
    Key? key,
  }) : super(key: key);
  final String spoiler;

  @override
  _SpoilerTextState createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<SpoilerText> {
  //bool spoiled = false;
  Color spoiled = Colors.black;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: widget.spoiler,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                debugPrint('--spoiler tapped: ${widget.spoiler}--');
                setState(() {
                  spoiled =
                      (spoiled == Colors.black) ? Colors.white : Colors.black;
                });
              },
            style: TextStyle(color: spoiled, backgroundColor: Colors.black),
          ),
        ],
      ),
    );
  }
}

singleReplyDialogue(BuildContext context, String attribute) async {
  //String? replyNo = attribute['href']!.substring(2);
  String? replyNo = attribute.substring(2);

  final replyPost = await getReplyPost(context, int.parse(replyNo));
  showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (_) => AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      //scrollable: true,
      title: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('REPLIES'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ThreadItem(item: replyPost),
      ),
    ),
  );
}
