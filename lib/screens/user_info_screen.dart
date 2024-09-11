import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _gender;
  bool _isPhysicallyChallenged = false;
  File? _profileImage; // Holds the selected profile image
  String? _profileImageUrl; // To store the profile picture URL after upload

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  // Function to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Function to upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage(String userId) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');
      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Save user info to Firestore
  void _saveUserInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (_profileImage != null) {
          _profileImageUrl = await _uploadProfileImage(currentUser.uid);
        }

        await usersCollection.doc(currentUser.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'age': _ageController.text,
          'gender': _gender,
          'physicallyChallenged': _isPhysicallyChallenged,
          'profileImageUrl': _profileImageUrl, // Store profile image URL
          'isVerified': false, // Default as not verified
          'verificationStatus': 'pending',
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User info saved successfully.')));
      }
    } catch (e) {
      print('Error saving user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save user info.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display profile image or a placeholder
              GestureDetector(
                onTap: _pickImage, // Trigger image picker
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!) as ImageProvider
                      : AssetImage('assets/profile_placeholder.png'),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text('Physically Challenged'),
                value: _isPhysicallyChallenged,
                onChanged: (value) {
                  setState(() {
                    _isPhysicallyChallenged = value ?? false;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserInfo,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
