import 'dart:convert';
import 'dart:io';

import 'package:chat_flow/providers/theme_provider.dart';
import 'package:chat_flow/screens/configure/config.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String? playUrl;
  bool isPlaying = false;
  final player = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? filePath;
  final TextEditingController messageController = TextEditingController();
  final myId = FirebaseAuth.instance.currentUser!.uid;

  // late String myId;
  final ScrollController _scrollController = ScrollController();
  bool showEmoji = false;
  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    player.durationStream.listen((d) {
      setState(() => duration = d ?? Duration.zero);
    });

    player.positionStream.listen((p) {
      setState(() => position = p);
    });

    WidgetsBinding.instance.addObserver(this);
    requestPermission();

    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    setOnline(true);
  }

  Future<void> requestPermission() async {
    await Permission.microphone.request();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   myId = Provider.of<UserProvider>(context).uid;
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    setOnline(false);
    _recorder!.closeRecorder();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline(true); //
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setOnline(false);
    }
  }

  // Future playAudio(String url) async {
  //   await player.setUrl(url);
  //   player.play();
  // }

  Future playAudio(String url) async {
    if (playUrl == url && isPlaying) {
      await player.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await player.setUrl(url);
      player.play();

      setState(() {
        playUrl = url;
        isPlaying = true;
      });

      // jab audio complete ho
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            isPlaying = false;
            playUrl = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isdark;
    print("MY ID: $myId");
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(widget.receiverId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(widget.receiverEmail);
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            bool isOnline = data['isOnline'] ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text(widget.receiverEmail), SizedBox(width: 6)]),

                Text(
                  isOnline ? "Online" : "Offline",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ================= MESSAGES =================
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .orderBy("time")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    final isAtBottom =
                        _scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent;

                    if (isAtBottom) {
                      scrollToBottom();
                    }
                  }
                });
                return ListView(
                  controller: _scrollController,
                  children: messages.map((msg) {
                    var data = msg.data() as Map<String, dynamic>;

                    bool isChat =
                        (data['senderId'] == myId &&
                            data['receiverId'] == widget.receiverId) ||
                        (data['senderId'] == widget.receiverId &&
                            data['receiverId'] == myId);

                    if (!isChat) return SizedBox();

                    bool isMe = data['senderId'] == myId;
                    if (!isMe &&
                        (data['seen'] == false || data['seen'] == null)) {
                      FirebaseFirestore.instance
                          .collection("messages")
                          .doc(msg.id)
                          .update({"seen": true});
                    }

                    return GestureDetector(
                      onLongPress: () {
                        deleteMessage(msg.id);
                      },

                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // 💬 MESSAGE BUBBLE
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  //color: isMe ? Colors.blue : Colors.grey[300],
                                  color: isMe
                                      ? (isDark
                                            ? Colors.blue[700]
                                            : Colors.blue)
                                      : (isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[300]),
                                  //borderRadius: BorderRadius.circular(12),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: isMe
                                        ? Radius.circular(16)
                                        : Radius.circular(0),
                                    bottomRight: isMe
                                        ? Radius.circular(0)
                                        : Radius.circular(16),
                                  ),
                                ),
                                // child:
                                //     data['imageUrl'] != null &&
                                //         data['imageUrl'] != ""
                                //     ? Stack(
                                //         children: [
                                //           ClipRRect(
                                //             borderRadius: BorderRadius.circular(
                                //               12,
                                //             ),
                                //             child: Image.network(
                                //               data['imageUrl'],
                                //               width: 200,
                                //               height: 200,
                                //               fit: BoxFit.cover,
                                //             ),
                                //           ),
                                //           if (isMe)
                                //             Positioned(
                                //               top: 5,
                                //               right: 5,
                                //               child: GestureDetector(
                                //                 onTap: () {
                                //                   deleteImage(msg.id);
                                //                 },
                                //                 child: Container(
                                //                   padding: EdgeInsets.all(5),
                                //                   decoration: BoxDecoration(
                                //                     color: Colors.black54,
                                //                     shape: BoxShape.circle,
                                //                   ),
                                //                   child: Icon(
                                //                     Icons.delete,
                                //                     size: 16,
                                //                     color: Colors.white,
                                //                   ),
                                //                 ),
                                //               ),
                                //             ),
                                //         ],
                                //       )
                                //     : Text(
                                //         data['text'],
                                //         style: TextStyle(
                                //           // color: isMe
                                //           //     ? Colors.white
                                //           //     : Colors.black,
                                //           color: isMe
                                //               ? Colors.white
                                //               : (isDark
                                //                     ? Colors.white
                                //                     : Colors.black),
                                //         ),
                                //       ),
                                child:
                                    data['imageUrl'] != null &&
                                        data['imageUrl'] != ""
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              data['imageUrl'],
                                              width: 200,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      )
                                    : data['audioUrl'] != null
                                    ? GestureDetector(
                                        onTap: () =>
                                            playAudio(data['audioUrl']),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Icon(
                                            //   Icons.play_arrow,
                                            //   color: isMe
                                            //       ? Colors.white
                                            //       : Colors.black,
                                            // ),
                                            // Icon(
                                            //   (playUrl == data['audioUrl'] &&
                                            //           isPlaying)
                                            //       ? Icons.pause
                                            //       : Icons.play_arrow,
                                            //   color: isMe
                                            //       ? Colors.white
                                            //       : Colors.black,
                                            // ),
                                            Row(
                                              children: [
                                                Icon(
                                                  (playUrl == data['audioUrl'] &&
                                                          isPlaying)
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                ),
                                                Expanded(
                                                  child: Slider(
                                                    value: position.inSeconds
                                                        .toDouble(),
                                                    max:
                                                        duration.inSeconds
                                                                .toDouble() ==
                                                            0
                                                        ? 1
                                                        : duration.inSeconds
                                                              .toDouble(),
                                                    onChanged: (value) async {
                                                      await player.seek(
                                                        Duration(
                                                          seconds: value
                                                              .toInt(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "${position.inSeconds}s / ${duration.inSeconds}s",
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              "Voice Message",
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        data['text'],
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                        ),
                                      ),
                              ),

                              // ⏱ TIME + TICK (OUTSIDE PERFECT ALIGNMENT)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatTime(data['time']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(width: 4),

                                    if (isMe)
                                      Icon(
                                        data['seen'] == true
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 14,
                                        color: data['seen'] == true
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (showEmoji) {
                              showEmoji = false;
                              focusNode.requestFocus();
                            } else {
                              showEmoji = true;
                              focusNode.unfocus();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                        ),

                        Expanded(
                          child: TextField(
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              sendMessage();
                            },
                            focusNode: focusNode,
                            controller: messageController,
                            onTap: () {
                              if (showEmoji) {
                                setState(() => showEmoji = false);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onLongPressStart: (_) => startRecording(),
                              onLongPressEnd: (_) => stopRecording(),
                              child: Icon(
                                isRecording ? Icons.mic : Icons.mic_none,
                                color: isRecording ? Colors.red : Colors.grey,
                                size: 26,
                              ),
                            ),
                            IconButton(
                              onPressed: sendImage,
                              icon: Icon(Icons.attach_file, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ================= EMOJI PICKER =================
          if (showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  messageController.text += emoji.emoji;

                  messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: messageController.text.length),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future startRecording() async {
    final dir = await getTemporaryDirectory();
    filePath = '${dir.path}/voice.aac';
    await _recorder!.startRecorder(toFile: filePath);
    setState(() {
      isRecording = true;
    });
  }

  Future stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      isRecording = false;
      print("Audio saved at: $filePath");

      uploadAudio();
    });
  }

  Future uploadAudio() async {
    final bytes = await File(filePath!).readAsBytes();

    var request = http.MultipartRequest(
      'POST',
     // Uri.parse('https://api.cloudinary.com/v1_1/dev6zewn8/video/upload'),
     Uri.parse(AppConfig.cloudinaryVideoUrl)
    );

    request.fields['upload_preset'] = 'chat_upload';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'voice.aac'),
    );

    var response = await request.send();
    var res = await response.stream.bytesToString();
    var data = json.decode(res);

    String audioUrl = data['secure_url'];

    // 🔥 Firebase me save
    await FirebaseFirestore.instance.collection("messages").add({
      "senderId": myId,
      "receiverId": widget.receiverId,
      "audioUrl": audioUrl,
      "text": "",
      "time": DateTime.now(),
      "seen": false,
    });
  }

  Future sendNotification(String token, String message) async {
    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=YOUR_SERVER_KEY",
      },
      body: jsonEncode({
        "to": token,
        "notification": {"title": "New Message", "body": message},
      }),
    );
  }

  String formatTime(Timestamp time) {
    final date = time.toDate();

    int hour = date.hour;
    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    String minute = date.minute.toString().padLeft(2, '0');

    return "$hour:$minute $period";
  }

  //  Send Message
  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String messageText = messageController.text.trim();

    // 1. Save message
    await FirebaseFirestore.instance.collection("messages").add({
      "senderId": myId,
      "receiverId": widget.receiverId,
      "text": messageText,
      "time": DateTime.now(),
      "seen": false,
    });

    // 2. Get receiver token
    var userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.receiverId)
        .get();

    String? token = userDoc.data()?['fcmToken'];

    // 3. Send notification
    if (token != null) {
      await sendNotification(token, messageText);
    }

    messageController.clear();
  }

  void setOnline(bool status) {
    FirebaseFirestore.instance.collection("users").doc(myId).set({
      "isOnline": status,
      "lastSeen": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // delete message
  void deleteMessage(String id) async {
    await FirebaseFirestore.instance.collection("messages").doc(id).delete();
  }

  Future sendImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    var request = http.MultipartRequest(
      'POST',
     // Uri.parse('https://api.cloudinary.com/v1_1/dev6zewn8/image/upload'),
     Uri.parse(AppConfig.cloudinaryImageUrl)
    );

    request.fields['upload_preset'] = 'chat_upload';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'chat.jpg'),
    );

    var response = await request.send();
    var res = await response.stream.bytesToString();
    var data = json.decode(res);

    if (data['secure_url'] == null) {
      print("Upload failed");
      return;
    }

    // String imageUrl = data['secure_url'];
    // // Firestore me save
    // await FirebaseFirestore.instance.collection("messages").add({
    //   "senderId": myId,
    //   "receiverId": widget.receiverId,
    //   "imageUrl": imageUrl,
    //   "text": "",
    //   "time": DateTime.now(),
    //   "seen": false,
    // });
    String imageUrl = data['secure_url'];

    // 1. Save image message
    await FirebaseFirestore.instance.collection("messages").add({
      "senderId": myId,
      "receiverId": widget.receiverId,
      "imageUrl": imageUrl,
      "text": "",
      "time": DateTime.now(),
      "seen": false,
    });

    // 2. Get receiver token
    var userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.receiverId)
        .get();

    String? token = userDoc.data()?['fcmToken'];

    // 3. Send notification
    if (token != null) {
      await sendNotification(token, "📷 Image");
    }
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void deleteImage(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Image"),
          content: Text("Are you want to delete your love image?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                deleteMessage(id);
                Navigator.pop(context);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
