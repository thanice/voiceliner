import 'package:binder/binder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:voice_outliner/state/notes_state.dart';

class NoteItem extends StatefulWidget {
  final int num;
  const NoteItem({Key? key, required this.num}) : super(key: key);

  @override
  _NoteItemState createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  @override
  Widget build(BuildContext context) {
    final note = context.watch(notesRef.select((state) => state[widget.num]));
    assert(note.index == widget.num);
    final isCurrent =
        context.watch(currentlyPlayingOrRecordingRef.select((state) {
      return state != null && note.id == state.id;
    }));
    final depth = context.watch(notesRef.select((notes) {
      int getDepth(String? id) {
        if (id != null) {
          final predecessor = notes.firstWhere((element) => element.id == id);
          return 1 + getDepth(predecessor.parentNoteId);
        }
        return 0;
      }

      final d = getDepth(notes[widget.num].parentNoteId);
      return d;
    }));
    return Dismissible(
        confirmDismiss: (direction) async {
          if (note.index == 0) {
            return false;
          }
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            context.use(notesLogicRef).indentNote(note);
          } else if (direction == DismissDirection.endToStart) {
            context.use(notesLogicRef).outdentNote(note);
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
        key: Key("dismissable-${note.id}"),
        child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            color: const Color.fromRGBO(237, 226, 255, 0.8),
            margin: EdgeInsets.only(
                top: 10.0, left: 10.0 + 30.0 * depth, right: 10.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              selected: isCurrent,
              selectedTileColor: Colors.deepPurpleAccent,
              title: Text(note.transcript == null
                  ? "Recording at ${DateFormat.jm().format(note.dateCreated.toLocal())}"
                  : note.transcript!),
              subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(note.duration != null
                        ? "${note.duration!.inSeconds}s"
                        : ""),
                    Timeago(builder: (_, t) => Text(t), date: note.dateCreated)
                  ]),
              onTap: () => context.use(notesLogicRef).playNote(note),
            )));
  }
}
