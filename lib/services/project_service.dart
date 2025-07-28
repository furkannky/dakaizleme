import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Project>> getProjects() {
    return _db.collection('projects').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Project.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<Project?> getProjectById(String id) async {
    final doc = await _db.collection('projects').doc(id).get();
    if (doc.exists) {
      return Project.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> addProject(Project project) {
    return _db.collection('projects').add(project.toFirestore());
  }

  Future<void> updateProject(Project project) {
    return _db.collection('projects').doc(project.id).update(project.toFirestore());
  }

  Future<void> deleteProject(String id) {
    return _db.collection('projects').doc(id).delete();
  }
}