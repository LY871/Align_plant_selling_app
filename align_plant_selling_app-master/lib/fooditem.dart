import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFoodItem extends StatefulWidget {
  final String userId;
  final String supplierId;

  const AddFoodItem({required this.userId, required this.supplierId, Key? key}) : super(key: key);

  @override
  _AddFoodItemState createState() => _AddFoodItemState();
}

class _AddFoodItemState extends State<AddFoodItem> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    priceController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      String filePath = 'fooditems/${DateTime.now()}.png';
      File file = File(image.path);

      TaskSnapshot uploadTask = await FirebaseStorage.instance.ref(filePath).putFile(file);

      String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadFoodItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        if (_image != null) {
          imageUrl = await uploadImage(XFile(_image!.path));
        }

        await FirebaseFirestore.instance
            .collection('suppliers')
            .doc(widget.supplierId)
            .collection('fooditems')
            .add({
          'name': nameController.text,
          'price': double.tryParse(priceController.text) ?? 0.0,
          'image': imageUrl ?? '',
        });

        print('Food item added successfully!');
      } catch (e) {
        print('Error adding food item: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food Item')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Food Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a food name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickAndUploadImage,
                child: const Text('Pick Image'),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(
                    _image!,
                    height: 150,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadFoodItem,
                child: const Text('Add Food Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
