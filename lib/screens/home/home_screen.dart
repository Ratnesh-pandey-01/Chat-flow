import 'package:chat_flow/providers/theme_provider.dart';
import 'package:chat_flow/screens/auth/login_screen.dart';
import 'package:chat_flow/screens/chat/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleThem();
            },
            icon: Icon(
              Provider.of<ThemeProvider>(context).isdark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
          IconButton(
            onPressed: () async {
              // await FirebaseAuth.instance.signOut();
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => LoginScreen()),
              // );
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Logout"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text("Logout"),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var data = user.data();

              // apna khud ka account hide karo
              if (data['uid'] == currentUser!.uid) {
                return SizedBox();
              }

              return ListTile(
                title: Text(data['email']),
                // leading: CircleAvatar(child: Icon(Icons.person)),
                leading: Stack(
                  children: [
                    CircleAvatar(child: Icon(Icons.person)),
                    Positioned(
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          color: data['isOnline'] == true
                              ? Colors.blue
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  //print("Open chat with ${data['email']}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: data["uid"],
                        receiverEmail: data["email"],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
