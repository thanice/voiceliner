import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:voice_outliner/data/note.dart';
import 'package:voice_outliner/state/notes_state.dart';
import 'package:voice_outliner/state/outline_state.dart';
import 'package:voice_outliner/state/player_state.dart';

class NoteItem extends StatefulWidget {
  final int num;
  const NoteItem({Key? key, required this.num}) : super(key: key);

  @override
  _NoteItemState createState() => _NoteItemState();
}

Color computeColor(int? magnitude) {
  Color a = const Color.fromRGBO(237, 226, 255, 1);
  Color b = const Color.fromRGBO(255, 191, 217, 1.0);
  double t = magnitude != null && magnitude <= 100 ? magnitude / 100 : 0;
  return Color.lerp(a, b, t)!;
}

class _NoteItemState extends State<NoteItem> {
  final _renameController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _renameController.dispose();
  }

  void _changeNoteTranscript() {
    final note = context.read<NotesModel>().notes.elementAt(widget.num);
    Future<void> _onSubmitted(BuildContext ctx) async {
      if (_renameController.value.text.isNotEmpty) {
        await context
            .read<NotesModel>()
            .setNoteTranscript(note, _renameController.value.text);
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }

    _renameController.text = note.transcript ?? "";
    _renameController.selection = TextSelection(
        baseOffset: 0, extentOffset: _renameController.value.text.length);
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (dialogCtx) => AlertDialog(
                title: const Text("Change text"),
                content: TextField(
                    maxLines: null,
                    decoration: const InputDecoration(hintText: "Transcript"),
                    controller: _renameController,
                    autofocus: true,
                    autocorrect: false,
                    onSubmitted: (_) => _onSubmitted(dialogCtx),
                    textCapitalization: TextCapitalization.sentences),
                actions: [
                  TextButton(
                      child: const Text("cancel"),
                      onPressed: () {
                        Navigator.of(dialogCtx, rootNavigator: true).pop();
                      }),
                  TextButton(
                      child: const Text("set"),
                      onPressed: () => _onSubmitted(dialogCtx))
                ]));
  }

  Future<void> _deleteNote() async {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete note?"),
              content: const Text("It cannot be restored"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text("cancel")),
                TextButton(
                    onPressed: () {
                      final note = context
                          .read<NotesModel>()
                          .notes
                          .elementAt(widget.num);
                      context.read<NotesModel>().deleteNote(note);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text("delete"))
              ],
            ));
  }

  List<PopupMenuEntry<String>> _menuBuilder(BuildContext context) {
    final note = context.read<NotesModel>().notes.elementAt(widget.num);
    final isTranscribing =
        context.read<NotesModel?>()?.isNoteTranscribing(note) ?? false;
    return [
      const PopupMenuItem(
          value: "share",
          child: ListTile(leading: Icon(Icons.share), title: Text("share"))),
      const PopupMenuItem(
          value: "edit",
          child: ListTile(leading: Icon(Icons.edit), title: Text("edit text"))),
      const PopupMenuItem(
          value: "move",
          child: ListTile(
              leading: Icon(Icons.playlist_play), title: Text("move to"))),
      const PopupMenuItem(
          value: "delete",
          child: ListTile(leading: Icon(Icons.delete), title: Text("delete"))),
      if (isTranscribing)
        const PopupMenuItem(
            child: ListTile(
                enabled: false,
                title: Text(
                  "waiting to transcribe...",
                  style: TextStyle(fontSize: 15),
                ))),
    ];
  }

  void _shareNote() {
    final note = context.read<NotesModel>().notes.elementAt(widget.num);
    String path =
        context.read<PlayerModel>().getPathFromFilename(note.filePath);
    String desc = note.transcript ?? note.infoString;
    Share.shareFiles([path],
        mimeTypes: ["audio/aac"], text: desc, subject: desc);
  }

  Widget _buildOutlineButton(BuildContext ctx, int num) {
    final outline = context.read<OutlinesModel>().outlines[num];
    return Card(
        key: Key("select-outline-$num"),
        child: ListTile(
            onTap: () {
              final note =
                  context.read<NotesModel>().notes.elementAt(widget.num);
              context.read<NotesModel>().moveNote(note, outline.id);
              Navigator.pop(ctx);
            },
            title: Text(outline.name)));
  }

  Future<void> _moveNote() async {
    final outlines = context.read<OutlinesModel>().outlines.length;
    Navigator.push(context, MaterialPageRoute(builder: (ct) {
      return Scaffold(
          appBar: AppBar(title: const Text("Select Outline")),
          body: ListView.builder(
              shrinkWrap: true,
              itemCount: outlines,
              itemBuilder: _buildOutlineButton));
    }));
  }

  void _handleMenu(String item) {
    if (item == "delete") {
      _deleteNote();
    } else if (item == "edit") {
      _changeNoteTranscript();
    } else if (item == "share") {
      _shareNote();
    } else if (item == "move") {
      _moveNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = context.select<NotesModel?, Note?>((m) => m == null
        ? null
        : m.notes.length > widget.num
            ? m.notes.elementAt(widget.num)
            : defaultNote);

    if (note == null) {
      return Card(
          child: const Center(
              child: Text(
            "drag to reorder",
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Color.fromRGBO(0, 0, 0, 0.5)),
          )),
          clipBehavior: Clip.hardEdge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          color: const Color.fromRGBO(237, 226, 255, 0.8),
          margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0));
    }
    final isTranscribing =
        context.read<NotesModel?>()?.isNoteTranscribing(note) ?? false;
    final isCurrent = context.select<NotesModel?, bool>((value) => value == null
        ? false
        : value.currentlyPlayingOrRecording != null &&
            value.currentlyPlayingOrRecording!.id == note.id);
    //TODO: make computed
    final currentlyExpanded = context.select<NotesModel?, bool>((value) =>
        value == null
            ? false
            : value.currentlyExpanded != null &&
                value.currentlyExpanded!.id == note.id);

    final depth = context.select<NotesModel?, int>((notesModel) {
      if (notesModel == null || widget.num >= notesModel.notes.length) {
        return 0;
      }
      return notesModel.getDepth(note);
    });
    return Dismissible(
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.2,
          DismissDirection.endToStart: 0.2,
        },
        movementDuration: const Duration(milliseconds: 100),
        dragStartBehavior: DragStartBehavior.down,
        confirmDismiss: (direction) async {
          if (note.previous == null) {
            return false;
          }
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            context.read<NotesModel>().indentNote(note);
          } else if (direction == DismissDirection.endToStart) {
            context.read<NotesModel>().outdentNote(note);
          }
        },
        background: Align(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
              SizedBox(width: 20.0),
              Icon(Icons.arrow_forward)
            ])),
        secondaryBackground: Align(
            child:
                Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
          Icon(Icons.arrow_back),
          SizedBox(width: 20.0),
        ])),
        key: Key("dismissable-${note.id}-$currentlyExpanded"),
        child: Card(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            color: note.isComplete
                ? const Color.fromRGBO(229, 229, 229, 1.0)
                : computeColor(note.color),
            margin: EdgeInsets.only(
                top: 10.0, left: 10.0 + 30.0 * min(depth, 5), right: 10.0),
            child: ExpansionTile(
              initiallyExpanded: currentlyExpanded,
              onExpansionChanged: (bool st) {
                context
                    .read<NotesModel>()
                    .setCurrentlyExpanded(st ? note : null);
              },
              trailing: const SizedBox(width: 0),
              tilePadding: EdgeInsets.zero,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Checkbox(
                      value: note.isComplete,
                      onChanged: (v) {
                        context
                            .read<NotesModel>()
                            .setNoteComplete(note, v ?? false);
                        HapticFeedback.mediumImpact();
                      }),
                  const Spacer(),
                  Timeago(
                      builder: (_, t) => Text(
                            t,
                            style: const TextStyle(
                                color: Color.fromRGBO(0, 0, 0, .5)),
                          ),
                      date: note.dateCreated),
                  PopupMenuButton(
                      itemBuilder: _menuBuilder,
                      icon: const Icon(Icons.more_vert),
                      onSelected: _handleMenu)
                ])
              ],
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        child: isTranscribing
                            ? const Text(
                                "waiting to transcribe...",
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color.fromRGBO(0, 0, 0, 0.5)),
                              )
                            : Text(
                                note.transcript == null
                                    ? note.infoString
                                    : note.transcript!,
                                style: TextStyle(
                                    decoration: note.isComplete
                                        ? TextDecoration.lineThrough
                                        : null),
                              )),
                    Text(
                      note.duration != null
                          ? "${note.duration!.inSeconds}s"
                          : "",
                      style:
                          const TextStyle(color: Color.fromRGBO(0, 0, 0, .5)),
                    )
                  ]),
              leading: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.read<NotesModel>().playNote(note),
                  icon: isCurrent
                      ? const Icon(Icons.stop_circle_outlined)
                      : const Icon(Icons.play_circle_outlined)),
            )));
  }
}
