import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  TextEditingController nameController = TextEditingController();

  String? imageUrl;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    var doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    var data = doc.data();

    nameController.text = data?['name'] ?? "";
    imageUrl = data?['photo'];

    setState(() {});
  }

  // 📷 image pick + upload
  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/dev6zewn8/image/upload'),
    );

    request.fields['upload_preset'] = 'chat_upload';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: 'profile.jpg'),
    );

    var res = await request.send();
    var data = json.decode(await res.stream.bytesToString());

    setState(() {
      imageUrl = data['secure_url'];
    });
  }

  // 💾 save
  Future saveProfile() async {
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
      "name": nameController.text.trim(),
      "photo": imageUrl,
    }, SetOptions(merge: true));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : null,
                child: imageUrl == null ? Icon(Icons.person, size: 40) : null,
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(onPressed: saveProfile, child: Text("Save")),
          ],
        ),
      ),
    );
  }
}
