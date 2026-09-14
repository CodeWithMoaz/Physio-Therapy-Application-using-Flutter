import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiotherapy/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  Future<bool> createOrUpdateItem(
      String itemId, String itemType, Map<String, dynamic> itemData) async {
    try {
      Map<String, dynamic> data = Map<String, dynamic>.from(itemData);
      data['id'] = itemId;
      data['updated_at'] = FieldValue.serverTimestamp();

      if (!itemData.containsKey('created_at')) {
        data['created_at'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(itemType)
          .doc(itemId)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error creating/updating item: $e');
      return false;
    }
  }

  Future<bool> ensureUserDocumentExists() async {
    if (currentUserId == null) return false;

    try {
      DocumentReference userRef =
          _firestore.collection('users').doc(currentUserId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        final user = _auth.currentUser!;
        await userRef.set({
          'id': currentUserId,
          'fullName': user.displayName ?? 'User',
          'email': user.email ?? '',
          'role': 'user',
          'gender': '',
          'dob': Timestamp.now(),
          'weight': 0.0,
          'height': 0.0,
          'profileImage': user.photoURL,
          'enrolledPrograms': {},
          'created_at': Timestamp.now(),
        });
        print('Created new user document for user: $currentUserId');
      }
      return true;
    } catch (e) {
      print('Error ensuring user document exists: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(String itemId, String itemType) async {
    if (currentUserId == null) return false;

    try {
      bool userExists = await ensureUserDocumentExists();
      if (!userExists) {
        print('Failed to ensure user document exists');
        return false;
      }

      DocumentReference userRef =
          _firestore.collection('users').doc(currentUserId);

      return await _firestore.runTransaction<bool>((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          print('User document does not exist, cannot toggle favorite');
          return false;
        }

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> favoritesData =
            userData['favorites'] as Map<String, dynamic>? ?? {};

        List<String> favorites =
            List<String>.from(favoritesData[itemType] ?? []);

        bool isFavorite = favorites.contains(itemId);

        if (!isFavorite) {
          DocumentSnapshot itemDoc = await transaction
              .get(_firestore.collection(itemType).doc(itemId));

          if (!itemDoc.exists) {
            print('Item $itemId does not exist in $itemType collection.');
          }
        }

        if (isFavorite) {
          favorites.remove(itemId);
        } else {
          favorites.add(itemId);
        }

        favoritesData[itemType] = favorites;

        transaction.update(userRef, {'favorites': favoritesData});

        return !isFavorite;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(String name, String? profileImage) async {
    if (currentUserId == null) return false;

    try {
      Map<String, dynamic> updateData = {'name': name};
      if (profileImage != null) {
        updateData['profileImage'] = profileImage;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
}
