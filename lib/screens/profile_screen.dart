import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  bool _physicallyChallenged = false;
  File? _profileImage;
  String? _profileImageUrl; // Store the profile image URL
  bool _isVerified = false; // Store verification status
  String _verificationStatus = 'pending'; // Store verification status string

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          // Update each field separately to ensure proper state update
          setState(() {
            _nameController.text = userDoc['name'] ?? '';
          });
          setState(() {
            _phoneController.text = userDoc['phone'] ?? '';
          });
          setState(() {
            _ageController.text = userDoc['age']?.toString() ?? '';
          });
          setState(() {
            _gender = userDoc['gender'];
          });
          setState(() {
            _physicallyChallenged = userDoc['physicallyChallenged'] ?? false;
          });
          setState(() {
            _profileImageUrl = userDoc['profilePicture'];
          });
          setState(() {
            _isVerified = userDoc['isVerified'] ?? false;
          });
          setState(() {
            _verificationStatus = userDoc['verificationStatus'] ?? 'pending';
          });

          print('User info loaded successfully');
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error loading user info: $e');
      }
    } else {
      print('No user is currently logged in');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateUserInfo() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = _profileImageUrl; // Default to current URL
        if (_profileImage != null) {
          try {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('profile_pictures')
                .child('${user.uid}.jpg');
            await storageRef.putFile(_profileImage!);
            imageUrl = await storageRef.getDownloadURL();
          } catch (e) {
            print('Error uploading profile picture: $e');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to upload profile picture.'),
            ));
            return;
          }
        }

        // Update user information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'age': int.parse(_ageController.text),
          'gender': _gender,
          'physicallyChallenged': _physicallyChallenged,
          'profilePicture': imageUrl, // Update profile picture URL
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully!'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Display profile picture
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : AssetImage('assets/default_profile.png')
                                as ImageProvider),
                    child: _profileImage == null && _profileImageUrl == null
                        ? Icon(Icons.camera_alt, size: 50)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Show verification status and blue tick
              _isVerified
                  ? Row(
                      children: [
                        Text('Verified User'),
                        Icon(Icons.check_circle, color: Colors.blue),
                      ],
                    )
                  : Text('Verification Status: $_verificationStatus'),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: ['Male', 'Female'].map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Gender'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Physically Challenged'),
                value: _physicallyChallenged,
                onChanged: (value) {
                  setState(() {
                    _physicallyChallenged = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserInfo,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
