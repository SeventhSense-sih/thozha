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
          setState(() {
            _nameController.text = userDoc['name'] ?? '';
            _phoneController.text = userDoc['phone'] ?? '';
            _ageController.text = userDoc['age']?.toString() ?? '';
            _gender = userDoc['gender'];
            _physicallyChallenged = userDoc['physicallyChallenged'] ?? false;
            _profileImageUrl = userDoc['profilePicture'];
            _isVerified = userDoc['isVerified'] ?? false;
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
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload profile picture.')));
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

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'), // Custom back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Display profile picture with a border and shadow
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/upload_icon.png')),
                    child: _profileImage == null && _profileImageUrl == null
                        ? Icon(Icons.camera_alt, size: 50, color: Colors.white)
                        : null,
                    backgroundColor: Colors.grey[300], // Subtle background color
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Show verification status and custom tick icon
              _isVerified
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verified User',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green),
                  ),
                  SizedBox(width: 8),
                  Image.asset('assets/tick_icon.png', width: 24, height: 24),
                ],
              )
                  : Text(
                'Verification Status: $_verificationStatus',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              // Name TextFormField with padding and custom styling
              _buildCustomTextField(
                controller: _nameController,
                labelText: 'Name',
                validatorText: 'Please enter your name',
              ),
              SizedBox(height: 10),
              _buildCustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                validatorText: 'Please enter your phone number',
              ),
              SizedBox(height: 10),
              _buildCustomTextField(
                controller: _ageController,
                labelText: 'Age',
                keyboardType: TextInputType.number,
                validatorText: 'Please enter your age',
              ),
              SizedBox(height: 10),
              // Gender Dropdown with consistent style
              DropdownButtonFormField<String>(
                value: _gender,
                icon: Image.asset('assets/dropdown_icon.png'),
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
                decoration: InputDecoration(
                  labelText: 'Gender',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              // Switch List Tile for physically challenged status
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
              // Update Profile Button
              ElevatedButton(
                onPressed: _updateUserInfo,
                child: Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent, // Button color
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String validatorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorText;
        }
        return null;
      },
    );
  }
}
