import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final empresaActivaProvider = StateProvider<String?>((ref) => null);

final empresasDelUsuarioProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('empresas')
      .where('miembros', arrayContains: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

final esAdminEmpresaProvider = Provider.family<bool, String>((ref, empresaId) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> register(String email, String password, String nombre) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(nombre);
    await _db.collection('usuarios').doc(cred.user!.uid).set({
      'nombre': nombre,
      'email': email,
      'creado_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
