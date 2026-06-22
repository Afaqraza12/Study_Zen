import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Stream to listen to auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: '664193026681-s8dndrv07cs6u1hb9niuc1nigo3ejlpc.apps.googleusercontent.com',
      );
      
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore, if not create them
        bool exists = await _firestoreService.checkUserExists(user.uid);
        if (!exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'Student',
            email: user.email ?? '',
            photoUrl: user.photoURL ?? '',
            subjects: [],
            level: 1,
            xp: 0,
            streak: 0,
            pomodoroSessions: 0,
            lastLogin: DateTime.now(),
            joinedDate: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
        } else {
          // Update last login
          await _firestoreService.updateLastLogin(user.uid);
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
