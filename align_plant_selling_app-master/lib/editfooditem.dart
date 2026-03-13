import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Add this import
import 'package:firebase_storage/firebase_storage.dart'; // Add this import
import 'dart:io'; // Add this import

class EditFoodItem extends StatefulWidget {
  final String userId;
  final String supplierId;
  final String foodItemId;
  final String name;
  final double price;
  final String imageUrl;

  EditFoodItem({
    required this.userId,
    required this.supplierId,
    required this.foodItemId,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  @override
  _EditFoodItemState createState() => _EditFoodItemState();
}

class _EditFoodItemState extends State<EditFoodItem> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  XFile? _image; // To hold the picked image

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    priceController = TextEditingController(text: widget.price.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<String> _uploadImage() async {
    if (_image != null) {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('foodimages/${widget.supplierId}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await imageRef.putFile(File(_image!.path));
      String imageUrl = await imageRef.getDownloadURL();
      return imageUrl;
    }
    return widget.imageUrl;
  }

  Future<void> saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        String imageUrl = await _uploadImage();
        await FirebaseFirestore.instance
            .collection('suppliers')
            .doc(widget.supplierId)
            .collection('fooditems')
            .doc(widget.foodItemId)
            .update({
          'name': nameController.text,
          'price': double.tryParse(priceController.text) ?? 0.0,
          'image': imageUrl,
        });
        Navigator.pop(context);
      } catch (error) {
        print("Error saving changes: $error");
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Food Item'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _image != null
                    ? Image.file(
                  File(_image!.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
                    : Image.network(
                  widget.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
