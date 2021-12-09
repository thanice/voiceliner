import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class OutlineWizard extends StatefulWidget {
  final String name;
  final String emoji;
  final String confirm;
  final bool autofocus;
  final Function(String name, String emoji) onSubmit;
  const OutlineWizard(
      {Key? key,
      required this.name,
      required this.emoji,
      required this.confirm,
      required this.onSubmit,
      this.autofocus = false})
      : super(key: key);

  @override
  _OutlineWizardState createState() => _OutlineWizardState();
}

class _OutlineWizardState extends State<OutlineWizard> {
  final _renameController = TextEditingController();
  String emoji = "";
  bool showEmojiEditor = false;
  @override
  void dispose() {
    super.dispose();
    _renameController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _renameController.text = widget.name;
    if (widget.autofocus) {
      _renameController.selection = TextSelection(
          baseOffset: 0, extentOffset: _renameController.value.text.length);
    }
    setState(() {
      emoji = widget.emoji;
    });
  }

  Future<void> _onSubmitted(BuildContext ctx) async {
    if (_renameController.value.text.isNotEmpty) {
      widget.onSubmit(_renameController.value.text, emoji);
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }

  _selectEmoji(Category c, Emoji e) {
    setState(() {
      emoji = e.emoji;
      showEmojiEditor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text("Setup Outline"),
        content: showEmojiEditor
            ? SizedBox(
                height: 250,
                width: 300,
                child: EmojiPicker(
                  onEmojiSelected: _selectEmoji,
                  config: const Config(bgColor: Colors.white),
                ))
            : Column(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() {
                          showEmojiEditor = true;
                        }),
                    icon: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    )),
                TextField(
                    decoration:
                        const InputDecoration(hintText: "Outline Title"),
                    controller: _renameController,
                    autofocus: widget.autofocus,
                    autocorrect: false,
                    onSubmitted: (_) => _onSubmitted(context),
                    textCapitalization: TextCapitalization.words)
              ]),
        actions: [
          TextButton(
              child: const Text("cancel"),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              }),
          TextButton(
              child: Text(widget.confirm),
              onPressed: () => _onSubmitted(context))
        ]);
  }
}

Future<void> launchOutlineWizard(
    String name,
    String emoji,
    BuildContext context,
    String confirm,
    Function(String name, String emoji) onSubmit,
    {bool autofocus = false}) async {
  await showDialog(
      context: context,
      builder: (dialogCtx) => OutlineWizard(
            name: name,
            emoji: emoji,
            confirm: confirm,
            onSubmit: onSubmit,
            autofocus: autofocus,
          ));
}