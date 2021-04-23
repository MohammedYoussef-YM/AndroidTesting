import 'package:cloud_firestore/cloud_firestore.dart';

extension FirebaseFirestorX on FirebaseFirestore {
  CollectionReference usersListRef(String userId) =>
      collection("Lists").doc(userId).collection("userList");
}
