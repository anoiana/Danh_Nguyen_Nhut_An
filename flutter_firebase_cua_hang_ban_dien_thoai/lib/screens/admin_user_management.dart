import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/screens/change_image.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:cross_platform_mobile_app_development/widgets/popup_menu_helper.dart';
import 'package:flutter/material.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool isSelected = false;
  final CollectionReference _collectionRef = FirebaseFirestore.instance
      .collection('users');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _collectionRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error fetching data"));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No data found"));
        }

        List<Map<String, dynamic>> users =
            snapshot.data!.docs
                .map(
                  (doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  },
                )
                .toList();

        return ListView.separated(
          itemCount: users.length,
          itemBuilder: (context, position) {
            var user = users[position];
            return Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                ListTile(
                  title: Text(user['fullName'] ?? 'No Name'),
                  subtitle: Text(user['email'] ?? 'No Email'),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        user['image'] != null
                            ? MemoryImage(
                              base64Decode(user['image'].split(',').last),
                            )
                            : null,
                    child:
                        user['image'] == null
                            ? Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                  ),
                ),

                PopupMenuHelper.buildPopupMenu(
                  context,
                  onSelected: (value) async {
                    switch (value) {
                      case "banning":
                        openBanningDialog(context, user['id'], user);
                        break;
                      case "updating":
                        openUpdatingDialog(context, user['id'], user);
                        break;
                      default:
                        break;
                    }
                  },
                  optionsList: [
                    if (!isSelected) {"updating": "Updating"},
                    {"banning": "Banning "},
                  ],
                ),
              ],
            );
          },
          separatorBuilder: (context, position) => Divider(),
        );
      },
    );
  }

  Future<void> openUpdatingDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> user,
  ) {
    final _formKey = GlobalKey<FormState>();
    String? fullName = user['fullName'];
    String? address = user['address'];

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                'Update user',
                style: TextStyle(
                  color: AppColor.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: fullName,
                      decoration: InputDecoration(labelText: 'Full Name'),
                      onSaved: (value) {
                        if (value != null && value.isNotEmpty) {
                          fullName = value;
                        }
                      },
                    ),
                    TextFormField(
                      initialValue: address,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: InputBorder.none,
                      ),
                      onSaved: (value) {
                        if (value != null && value.isNotEmpty) {
                          address = value;
                        }
                      },
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChangeImage(uid: docId),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(width: 1),
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        color: AppColor.primaryColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    _collectionRef.doc(docId).update({
                      "fullName": fullName,
                      "address": address,
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Update', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> openBanningDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> user,
  ) {
    final _formKey = GlobalKey<FormState>();
    String? status = user['status'];

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update user'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: [
                    DropdownMenuItem(
                      value: 'Activated',
                      child: Text('Activated'),
                    ),
                    DropdownMenuItem(value: 'Banned', child: Text('Banned')),
                  ],
                  onChanged: (value) {
                    status = value;
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    _collectionRef.doc(docId).update({"status": status});
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: AppColor.primaryColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
