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
        title: Text('Verify Identity'),
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'), // Custom back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Align(
        alignment: Alignment(0, -0.5), // Adjust vertical alignment here
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _idImage != null
                ? Image.file(_idImage!, width: 100, height: 100)
                : Image.asset('assets/upload_icon.png', width: 100, height: 100), // Custom upload icon
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload ID Proof'),
            ),
            SizedBox(height: 20),
            if (_isUploading) CircularProgressIndicator(),
            ElevatedButton(
              onPressed: _submitVerification,
              child: Text('Submit for Verification'),
            ),
          ],
        ),
      ),
    );
  }
}
