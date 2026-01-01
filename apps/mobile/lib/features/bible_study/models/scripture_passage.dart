/// Represents a Scripture passage with book, chapter, and verse range
class ScripturePassage {
  final String id;
  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String text;
  final String? version;

  const ScripturePassage({
    required this.id,
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.text,
    this.version = 'ESV',
  });

  /// Returns formatted reference like "John 3:16-17"
  String get reference {
    if (startVerse == endVerse) {
      return '$book $chapter:$startVerse';
    }
    return '$book $chapter:$startVerse-$endVerse';
  }
}
