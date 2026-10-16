import 'package:codesnap/services/notes_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paid PDF preview exposes exactly ceil(20 percent) of pages', () {
    expect(NotesService.previewPageCount(1), 1);
    expect(NotesService.previewPageCount(5), 1);
    expect(NotesService.previewPageCount(6), 2);
    expect(NotesService.previewPageCount(7), 2);
    expect(NotesService.previewPageCount(10), 2);
    expect(NotesService.previewPageCount(101), 21);
  });

  test('paid PDF needs a completed purchase for full access', () {
    expect(
      NotesService.canAccessFullPdf(
        isFree: false,
        hasCompletedPurchase: false,
      ),
      isFalse,
    );
    expect(
      NotesService.canAccessFullPdf(
        isFree: false,
        hasCompletedPurchase: true,
      ),
      isTrue,
    );
    expect(
      NotesService.canAccessFullPdf(
        isFree: true,
        hasCompletedPurchase: false,
      ),
      isTrue,
    );
  });
}
