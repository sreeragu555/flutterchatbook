import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';

class Adddetails extends StatefulWidget {
  @override
  _AdddetailsState createState() => _AdddetailsState();
}

FirebaseAuth user = FirebaseAuth.instance;
String uid = user.currentUser.uid.toString();
String usercollectionid="-1",Name="",imageurl="https://devtalk.blender.org/uploads/default/original/2X/c/cbd0b1a6345a44b58dda0f6a355eb39ce4e8a56a.png";

class _AdddetailsState extends State<Adddetails> {

  @override
  void initState(){
    getUser();
    super.initState();
  }

  Future<void> getUser() async {
    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    // Call the user's CollectionReference to add a new user
    users.where("uid",isEqualTo: uid).get().then((value){
      value.docs.forEach((element) {
        usercollectionid=element.reference.id;
        Name=element["Name"];
        imageurl=element["Profile_pic_url"];
        setState(() {
          name.text=Name;
          imageurl=element["Profile_pic_url"];
          _image=element["Profile_pic_url"];
        });
      });
    });
  }

  @override
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  File _image;
  var imgurl;
  final name = TextEditingController();
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(
        source: ImageSource.gallery, maxHeight: 300, maxWidth: 300);
    _cropImage(pickedFile.path);
  }
  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        maxWidth: 200,
        maxHeight: 200,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        compressFormat: ImageCompressFormat.jpg,
        androidUiSettings:AndroidUiSettings(
          toolbarColor: Colors.blue,
          toolbarTitle: "Crop your image",
        )
    );
    setState(() {
      if (croppedImage != null) {
        _image = File(croppedImage.path) as File;
      } else {
        Fluttertoast.showToast(
          msg: "No image has been selected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    String url = "";
    Reference ref =
        storage.ref().child("uploads/image1" + DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(_image);
    uploadTask.whenComplete(() async {
      url = await ref.getDownloadURL() as String;
      print(url);
      addUser(name.text.toString(), url.toString());
    }).catchError((onError) {
      Fluttertoast.showToast(
        msg: "Something happened!!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      print(onError);
    });
    return url;
  }

  Future<void> addUser(String Name, String imageurl) async {

    CollectionReference users = FirebaseFirestore.instance.collection('Users');
    if(usercollectionid=='-1') {
      List<dynamic>list;
      users.add({'uid': uid, 'Name': Name, 'Profile_pic_url': imageurl,'Chats':FieldValue.arrayUnion(list)}).then(
              (value) {
           // print("User Added");
            EasyLoading.dismiss();
            Navigator.of(context).pop();
            Navigator
                .of(context)
                .pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
          }).catchError((error) {
        EasyLoading.dismiss();
        final snackBar = SnackBar(
          content: Text('Something is wrong!! Please try after sometime'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        print("Failed to add user: $error");
      });
    }
    else{
      users.doc(usercollectionid).update({
      'Name':Name,
        'Profile_pic_url':imageurl
      }).then((value) {
       // print("updated user details");
        EasyLoading.dismiss();
        Navigator.of(context).pop();
        Navigator
            .of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
      }).catchError((error) {
        EasyLoading.dismiss();
        final snackBar = SnackBar(
          content: Text('Something is wrong!! Please try after sometime'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        print("Failed to add user: $error");
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(300.0),
                child: _image != null
                    ? Container(
                        width: 200.0,
                        height: 200.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.fill, image: FileImage(_image))))
                    : Stack(children: <Widget>[
                        Container(
                          width: 300,
                          height: 300,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(300),
                            child: Image.network(
                                imageurl,
                              loadingBuilder:(BuildContext context, Widget child,ImageChunkEvent loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null ?
                                    loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          child: FloatingActionButton(
                            onPressed: () {
                              getImage();
                            },
                            tooltip: 'Pick Image',
                            child: Icon(
                              Icons.add_a_photo,
                            ),
                          ),
                          left: 190,
                          top: 190,
                        ),
                      ])),
            Container(
              margin: EdgeInsets.only(left: 60, right: 60),
              child: TextField(
                controller: name,
                decoration: InputDecoration(hintText: "Name"),
                inputFormatters: [new WhitelistingTextInputFormatter(RegExp("[a-zA-Z ]")),],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: ElevatedButton(
                  onPressed: () {
                    EasyLoading.show(status: 'loading...');
                    imgurl = uploadImageToFirebase(context);
                    // if (imgurl != null) {
                    //   print("We have uploaded the image");
                    // } else
                    //   print("Some error while uploading image");
                  },
                  child: Text("Next")),
            )
          ],
        ),
      ),
    ));
  }
}
