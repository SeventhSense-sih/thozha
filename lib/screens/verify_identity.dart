import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VerifyIdentityScreen extends StatefulWidget {
  @override
  _VerifyIdentityScreenState createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  File? _idImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_idImage == null) return;
    setState(() {
      _isUploading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('verification_docs')
            .child('${user.uid}.jpg');
        await storageRef.putFile(_idImage!);

        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('verifications')
            .doc(user.uid)
            .set({
          'userId': user.uid,
          'idProofUrl': downloadUrl,
          'status': 'pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text('Verification request submitted. Please wait for approval.'),
        ));
      }
    } catch (e) {
      print('Error uploading ID proof: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit verification request.'),
      ));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Identity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Official back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Image or Upload Icon
            _idImage != null
                ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _idImage!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : Column(
              children: [
                Image.asset(
                  'assets/upload_icon.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 10),
                Text(
                  'Upload your ID Proof',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Upload Button
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.upload_file),
              label: Text('Upload ID Proof'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Circular Progress Indicator for Uploading
            if (_isUploading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 20),
            ],

            // Submit for Verification Button
            ElevatedButton(
              onPressed: _submitVerification,
              child: Text(
                'Submit for Verification',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
