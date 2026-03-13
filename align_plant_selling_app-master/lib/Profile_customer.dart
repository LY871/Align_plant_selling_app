import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profilecustomer extends StatefulWidget {
  final String customerId;

  const Profilecustomer({super.key, required this.customerId});

  @override
  State<Profilecustomer> createState() => _ProfilecustomerState();
}

class _ProfilecustomerState extends State<Profilecustomer> {
  @override
  Widget build(BuildContext context) {
    CollectionReference customers = FirebaseFirestore.instance.collection('customers');

    return Scaffold(
      backgroundColor: Colors.white54,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey,
        title: const Text(
          'Contact Suppliers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
      FutureBuilder<DocumentSnapshot>(
        future: customers.doc(widget.customerId).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundImage: NetworkImage(
                            data['profileImage'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Name not available',
                              style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Local Suppliers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<List<DocumentSnapshot>>(
                      future: fetchSuppliers(),
                      builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text("Error fetching suppliers"));
                        }

                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data!.isEmpty) {
                            return Center(child: Text("No suppliers found"));
                          }

                          return ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              var supplierData = snapshot.data![index].data() as Map<String, dynamic>;
                              return SupplierCard(
                                supplierId: snapshot.data![index].id,
                                supplierName: supplierData['name'] ?? 'Unknown',
                                onTap: () {
                                  showFoodItemsDialog(supplierData['name'], snapshot.data![index].id);
                                },
                              );
                            },
                          );
                        }

                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> fetchSuppliers() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    return querySnapshot.docs;
  }

  void showFoodItemsDialog(String supplierName, String supplierId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: fetchSupplierData(supplierId),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> supplierSnapshot) {
                  if (supplierSnapshot.hasError) {
                    return Text("Error fetching supplier data");
                  }

                  if (supplierSnapshot.connectionState == ConnectionState.done) {
                    Map<String, dynamic> supplierData = supplierSnapshot.data!.data() as Map<String, dynamic>;
                    String phoneNumber = supplierData['phone'] ?? 'No phone number available';

                    return Text(
                      '$supplierName\'s Food Items\nPhone: $phoneNumber',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    );
                  }

                  return CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<DocumentSnapshot>>(
                future: fetchFoodItems(supplierId),
                builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                  if (snapshot.hasError) {
                    return Text("Error fetching food items");
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data!.isEmpty) {
                      return Text("No food items available");
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: snapshot.data!.map((fooditemsDoc) {
                        var foodItemData = fooditemsDoc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: foodItemData['image'] != null
                              ? Image.network(
                            foodItemData['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                              : SizedBox(
                            width: 50,
                            height: 50,
                            child: Placeholder(),
                          ),
                          title: Text(foodItemData['name']),
                          trailing: Text('\JOD ${foodItemData['price'].toString()}'),
                        );
                      }).toList(),
                    );
                  }

                  return CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> fetchFoodItems(String supplierId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('suppliers')
        .doc(supplierId)
        .collection('fooditems')
        .get();
    return querySnapshot.docs;
  }

  Future<DocumentSnapshot> fetchSupplierData(String supplierId) async {
    DocumentSnapshot supplierDoc = await FirebaseFirestore.instance.collection('suppliers').doc(supplierId).get();
    return supplierDoc;
  }
}

class SupplierCard extends StatelessWidget {
  final String supplierName;
  final String supplierId;
  final VoidCallback onTap;

  const SupplierCard({
    Key? key,
    required this.supplierName,
    required this.supplierId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                supplierName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
