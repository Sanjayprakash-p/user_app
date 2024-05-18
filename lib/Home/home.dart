import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_app/Authentication/signin.dart';
import 'package:user_app/Home/qrcode.dart';

bool loading = false;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _kilogramsController = TextEditingController();
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Order Details",
                        style: TextStyle(
                            fontSize: 50, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: _kilogramsController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.scale),
                          hintText: 'Kilograms',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the weight in kilograms';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: 'Preferred Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );

                          if (pickedDate != null) {
                            String formattedDate =
                                "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                            setState(() {
                              _dateController.text = formattedDate;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select Date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.access_time),
                          hintText: 'Preferred Time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        readOnly: true,
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              _timeController.text = pickedTime.format(context);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select Time';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      imageButton(),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Special Instructions',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter any special instructions';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      submitButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget imageButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.deepPurpleAccent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: () {
          _showImageSourceDialog(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _imageFile != null ? Icons.check : Icons.image,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            const Text(
              'Select Image',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          loading = true;
        });
        // String imageUrl = '';
        // if (_imageFile != null) {
        //   final storageRef = FirebaseStorage.instance
        //       .ref()
        //       .child('orders')
        //       .child('${DateTime.now().toIso8601String()}.jpg');
        //   await storageRef.putFile(File(_imageFile!.path));
        //   imageUrl = await storageRef.getDownloadURL();
        // }

        // Uncomment to get the current location
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        double latitude = position.latitude;
        double longitude = position.longitude;

        await FirebaseFirestore.instance.collection('orders').add({
          'kilograms': _kilogramsController.text.trim(),
          'preferred_date': _dateController.text.trim(),
          'preferred_time': _timeController.text.trim(),
          'special_instructions': _instructionsController.text.trim(),
          // 'image_url': imageUrl,
          'location': GeoPoint(latitude, longitude),
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'email_id': FirebaseAuth.instance.currentUser!.email,
        });
        setState(() {
          loading = false;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order submitted successfully!')));

        _dateController.clear();
        _timeController.clear();
        _instructionsController.clear();
        _kilogramsController.clear();
      } catch (e) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit order: $e')));
      }
    }
  }

  Widget submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.deepPurpleAccent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        onPressed: _submitOrder,
        child: const Text(
          'Submit',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
              ),
              Text(
                'PROFILE',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20),
              CircleAvatar(
                radius: 75,
                backgroundImage: NetworkImage(
                    'https://www.shutterstock.com/image-photo/head-shot-portrait-close-smiling-600nw-1714666150.jpg'), // Replace with your image path or network image
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Handle Edit Profile
                },
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    backgroundColor: Colors.deepPurpleAccent),
                onPressed: () {
                  // Handle Settings
                },
                child: const Text(
                  'Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 25,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              "Participation",
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("QR Code"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black, fontSize: 15),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const QRCodePage(),
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.emoji_events_outlined),
            title: Text("Total Points"),
            titleTextStyle: TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black, fontSize: 15),
            trailing: Text(
              "120",
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 15),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.star),
            title: Text("Completed Challenges"),
            titleTextStyle: TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black, fontSize: 15),
            trailing: Text(
              "11",
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 15),
            ),
          ),
          ListTile(
            onTap: () async {
              // _showQRCodeDialog(context);
            },
            leading: const Icon(Icons.recycling_outlined),
            title: const Text("Total waste saved"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black, fontSize: 15),
            trailing: const Text(
              "950kg",
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 15),
            ),
          ),
          ListTile(
            onTap: () async {
              // Show logout confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Logout"),
                    content: Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: Text("No"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut().then((value) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => Signin()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Logged out successfully')),
                            );
                          });

                          // Navigate to the SignIn page after logout

                          // Show a snackbar after logout
                        },
                        child: const Text("Yes"),
                      ),
                    ],
                  );
                },
              );
            },
            leading: const Icon(Icons.logout_outlined),
            title: const Text("Logout"),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
