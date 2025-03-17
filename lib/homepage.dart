import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BiodataService.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Biodataservice? service;
  String? selectedDocId;

  @override
  void initState() {
    service = Biodataservice(FirebaseFirestore.instance);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final addressController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(hintText: 'Age'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(hintText: 'Address'),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: service?.getBiodata(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error fetching data: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }

                    final documents = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final docId = documents[index].id;
                        final data = documents[index].data();

                        return ListTile(
                          title: Text(data['name']),
                          subtitle: Text(data['age']),
                          onTap: () {
                            setState(() {
                              nameController.text = data['name'];
                              ageController.text = data['age'];
                              addressController.text = data['address'];
                              selectedDocId = docId;
                            });
                          },
                          trailing: IconButton(
                            onPressed: () {
                              service?.delete(docId);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final Name = nameController.text.trim();
          final Age = ageController.text.trim();
          final Address = addressController.text.trim();

          if (Name.isEmpty || Age.isEmpty || Address.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All fields must be filled')),
            );
            return;
          }

          if (selectedDocId != null) {
            service?.update(selectedDocId!, {
              'name': Name,
              'age': Age,
              'address': Address,
            });
          } else {
            service?.add({'name': Name, 'age': Age, 'address': Address});
          }

          nameController.clear();
          ageController.clear();
          addressController.clear();
          setState(() {
            selectedDocId = null;
          });
        },
      ),
    );
  }
}
