import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodItem.dart';
import 'editfooditem.dart';

class Profilesupplier extends StatefulWidget {
  final String userId;
  final String supplierId;

  Profilesupplier({required this.userId, required this.supplierId});

  @override
  _ProfilesupplierState createState() => _ProfilesupplierState();
}

class _ProfilesupplierState extends State<Profilesupplier> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    // Fetch supplier data when initializing
    _fetchSupplierData();
  }

  void _fetchSupplierData() async {
    try {
      DocumentSnapshot supplierDoc = await FirebaseFirestore.instance
          .collection('suppliers') // Changed path
          .doc(widget.supplierId)
          .get();

      if (supplierDoc.exists) {
        Map<String, dynamic> data = supplierDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
        });
      } else {
        print('Supplier document does not exist');
      }
    } catch (error) {
      print('Error fetching supplier data: $error');
    }
  }


  void toggleEdit() {
    setState(() {
      isEditing = !isEditing; // Toggle edit mode
    });
  }

  void saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('suppliers') // Changed path
            .doc(widget.supplierId)
            .update({
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
        });
        toggleEdit();
      } catch (error) {
        print("Error saving changes: $error");
      }
    }
  }



  Stream<List<FoodItem>> _fetchFoodItems() {
    return FirebaseFirestore.instance
        .collection('suppliers') // Changed path
        .doc(widget.supplierId)
        .collection('fooditems')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => FoodItem.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteFoodItem(String foodItemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('suppliers')
          .doc(widget.supplierId)
          .collection('fooditems')
          .doc(foodItemId)
          .delete();
    } catch (e) {
      print('Error deleting food item: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supplier Profile',
          style: TextStyle(
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.blueGrey[100],
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: isEditing ? saveChanges : toggleEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${nameController.text}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                readOnly: !isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                readOnly: !isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                readOnly: !isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddFoodItem(userId: widget.userId,
                              supplierId: widget.supplierId),
                    ),
                  );
                },
                child: const Text('Add Food Item',style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black,),
              ),),
              SizedBox(height: 20),
              Text(
                'Food Items:',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<FoodItem>>(
                stream: _fetchFoodItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final foodItems = snapshot.data ?? [];

                  if (foodItems.isEmpty) {
                    return Text('No food items added yet.');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: foodItems.length,
                    itemBuilder: (context, index) {
                      final foodItem = foodItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            foodItem.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '\JOD ${foodItem.price}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          leading: Image.network(
                            foodItem.imageUrl,
                            width: 100,
                            height: 200,
                            fit: BoxFit.fill,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditFoodItem(
                                            userId: widget.userId,
                                            supplierId: widget.supplierId,
                                            foodItemId: foodItem.id,
                                            name: foodItem.name,
                                            price: foodItem.price,
                                            imageUrl: foodItem.imageUrl,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool? confirmDelete = await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Delete Food Item'),
                                        content: Text(
                                            'Are you sure you want to delete this food item?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmDelete == true) {
                                    await deleteFoodItem(foodItem.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      imageUrl: data['image'] ?? '',
    );
  }
}
