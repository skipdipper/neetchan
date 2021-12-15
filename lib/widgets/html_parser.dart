import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:neetchan/models/catalog.dart';
import 'package:neetchan/screens/thread_screen.dart';
import 'package:neetchan/services/get_data_api.dart';
import 'package:neetchan/widgets/post_text.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ParseHtmlToText extends StatefulWidget {
  const ParseHtmlToText({
    required this.com,
    Key? key,
  }) : super(key: key);

  final String com;

  @override
  State<ParseHtmlToText> createState() => _ParseHtmlToTextState();
}

class _ParseHtmlToTextState extends State<ParseHtmlToText> {
  bool spoiled = false;
  final regex = r'(((https?:\/\/)|(www\.))[^\s]+)';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('------ Parsing Html to Text ------');

    final textSpans = <TextSpan>[];

    // Replace word breaks, breaks, and url links
    final html = widget.com
        .replaceAll('<wbr>', '')
        .replaceAll('<br>', '\n')
        .replaceAllMapped(RegExp(r'(((https?:\/\/)|(www\.))[^\s<]+)'),
            (Match match) {
      return '<a href="${match.group(0)}" class="link">${match.group(0)}</a>';
    });
    var document = html_parser.parseFragment(html);

    // TODO: add inline css style support
    // e.g. <br><strong style=\"color: red;\">(USER WAS BANNED FOR THIS POST)</strong>
    for (final node in document.nodes) {
      TextDecoration? decoration;
      Color? color;
      Color? backgroundColor;
      GestureRecognizer? recognizer;

      if (node is dom.Element) {
        if (node.className == 'quotelink') {
          color = Colors.blue;
          decoration = TextDecoration.underline;
          if (node.attributes['href']!.startsWith('#p')) {
            recognizer = TapGestureRecognizer()
              ..onTap = () {
                debugPrint('quotelink tapped: ${node.text}');
                debugPrint(node.attributes['href']);

                singleReplyDialogue(context, node.attributes['href']!);
              };
          } else if (node.attributes['href']!.contains('thread')) {
            recognizer = TapGestureRecognizer()
              ..onTap = () {
                debugPrint('Link to another thread');
                debugPrint(node.attributes['href']);
                // href="[url_blank]/[board]/thread/[threadNo]#p[postNo]"
                final divider = node.attributes['href']!.split('/thread/');
                final linkBoard = divider.first.split('/').last;
                final linkThread =
                    int.tryParse(divider.last.split('#p').first) ?? 0;
                final linkPost =
                    int.tryParse(divider.last.split('#p').last) ?? 0;

                //TODO: open link thread at location hash position #p linkPost (scroll to)

                debugPrint(
                    'board:$linkBoard theadNo:$linkThread postNo:$linkPost');

                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Open this thread?'),
                    content: Text('$linkBoard/$linkThread'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Causes provider null error b.c. context poped
                          //Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Thread(
                                no: linkThread,
                                board: linkBoard,
                                op: Catalog.temp(
                                    no: linkThread, resto: 0, board: linkBoard),
                              ),
                            ),
                          ).then((value) {
                            debugPrint('------ Another Thread POPPED ------');
                            if (!context.read<ApiData>().currentThreadError) {
                              context.read<ApiData>().threadNoStack.pop();
                            }
                            // resets image index, images, error
                            context.read<ApiData>().clearThread();
                            // pops off link to another thread dialogue
                            Navigator.pop(context);
                          });
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              };
          }
        } else if (node.className == 'deadlink') {
          color = Colors.blue;
          decoration = TextDecoration.combine(
              [TextDecoration.lineThrough, TextDecoration.underline]);
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              debugPrint('Dead thread, open in archive');
            };
        }

        if (node.className == 'quote') {
          color = Colors.green;
        }

        // TODO: fix to work for spoiler tags or other parent tags,
        if (node.className == 'link') {
          color = Colors.blue;
          decoration = TextDecoration.underline;
          recognizer = TapGestureRecognizer()
            ..onTap = () async {
              debugPrint('Pressed on URL');
              debugPrint(node.attributes['href']);

              if (await canLaunch(node.text)) {
                await launch(node.text);
              }
            };
        }

        //TODO: fix this spoiled color is rebuilding the entire comment section
        //TODO: fix spoiling separate lines in same comment
        if (node.localName == 's') {
          backgroundColor = Colors.black;
          spoiled ? color = Colors.white : color = Colors.black;

          recognizer = TapGestureRecognizer()
            ..onTap = () {
              setState(() {
                spoiled = !spoiled;
                //spoiled ? color = Colors.white : color = Colors.black;
              });
            };
        }
      }

      textSpans.add(
        TextSpan(
          text: node.text,
          style: TextStyle(
              color: color,
              backgroundColor: backgroundColor,
              decoration: decoration),
          recognizer: recognizer,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13),
        children: textSpans,
      ),
    );
  }
}
