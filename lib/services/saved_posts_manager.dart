import 'package:flutter/material.dart';
import '../utils/feed_mock_data.dart';
import '../models/book_note.dart';
import '../models/project.dart';
import '../utils/mock_data.dart';

/// ─── Global Saved Posts Manager ──────────────────────────────────────────────
/// Manages the user's saved items across Pics, Videos, Books, and Projects.
class SavedPostsManager {
  SavedPostsManager._();

  static final Set<String> _savedIds = {'p1', 'p2', 'p3'};
  static final Set<String> _savedBookIds = {'python-crash-course', 'javascript-definitive-guide'};
  static final Set<String> _savedProjectIds = {'proj-1', 'proj-2'};
  
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(1);

  static Set<String> get savedIds => _savedIds;
  static Set<String> get savedBookIds => _savedBookIds;
  static Set<String> get savedProjectIds => _savedProjectIds;

  static bool isSaved(String id) => _savedIds.contains(id);
  static bool isBookSaved(String id) => _savedBookIds.contains(id);
  static bool isProjectSaved(String id) => _savedProjectIds.contains(id);

  static bool toggleSave(FeedPost post) {
    final wasSaved = _savedIds.contains(post.id);
    if (wasSaved) {
      _savedIds.remove(post.id);
    } else {
      _savedIds.add(post.id);
    }
    changeNotifier.value++;
    return !wasSaved;
  }

  static bool toggleBookSave(String bookId) {
    final wasSaved = _savedBookIds.contains(bookId);
    if (wasSaved) {
      _savedBookIds.remove(bookId);
    } else {
      _savedBookIds.add(bookId);
    }
    changeNotifier.value++;
    return !wasSaved;
  }

  static bool toggleProjectSave(String projectId) {
    final wasSaved = _savedProjectIds.contains(projectId);
    if (wasSaved) {
      _savedProjectIds.remove(projectId);
    } else {
      _savedProjectIds.add(projectId);
    }
    changeNotifier.value++;
    return !wasSaved;
  }

  static List<FeedPost> getSavedPosts() {
    final allPosts = FeedMockData.getPosts();
    return allPosts.where((p) => _savedIds.contains(p.id)).toList();
  }

  static List<FeedPost> getSavedPics() {
    final allPosts = FeedMockData.getPosts();
    return allPosts.where((p) => _savedIds.contains(p.id) && (p.videoUrl == null || p.videoUrl!.isEmpty)).toList();
  }

  static List<FeedPost> getSavedVideos() {
    final allPosts = FeedMockData.getPosts();
    return allPosts.where((p) => _savedIds.contains(p.id) && (p.videoUrl != null && p.videoUrl!.isNotEmpty)).toList();
  }

  static List<BookNote> getSavedBooks() {
    final allBooks = BookNoteData.getAllBooks();
    return allBooks.where((b) => _savedBookIds.contains(b.id)).toList();
  }

  static List<Project> getSavedProjects() {
    final allProjects = MockData.mockProjects;
    return allProjects.where((p) => _savedProjectIds.contains(p.id)).toList();
  }
}
