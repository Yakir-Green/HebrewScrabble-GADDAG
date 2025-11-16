Map<String, int> letterValues = {
  'א': 1,
  'ב': 3,
  'ג': 3,
  'ד': 2,
  'ה': 1,
  'ו': 1,
  'ז': 10,
  'ח': 4,
  'ט': 4,
  'י': 1,
  'כ': 2,
  'ל': 1,
  'מ': 2,
  'נ': 1,
  'ס': 6,
  'ע': 1,
  'פ': 4,
  'צ': 8,
  'ק': 5,
  'ר': 1,
  'ש': 3,
  'ת': 1
};

class LetterBag {
  late final List<String> _letters;
  static final LetterBag _instance = LetterBag._internal();

  factory LetterBag() {
    return _instance;
  }

  LetterBag._internal() {
    _letters = _createInitialBag();
    _letters.shuffle();
  }

  List<String> _createInitialBag() {
    return [
      'א','א','א','א','א','א','א','א','א',
      'ב','ב',
      'ג','ג',
      'ד','ד','ד','ד',
      'ה','ה','ה','ה','ה','ה',
      'ו','ו','ו','ו','ו','ו',
      'ז',
      'ח','ח',
      'ט','ט',
      'י','י','י','י','י','י','י','י','י',
      'כ','כ','כ',
      'ל','ל','ל','ל',
      'מ','מ','מ',
      'נ','נ','נ','נ',
      'ס',
      'ע','ע','ע','ע',
      'פ','פ','פ',
      'צ','צ',
      'ק',
      'ר','ר','ר','ר',
      'ש','ש','ש',
      'ת','ת','ת','ת','ת','ת'
    ];
  }

  List<String> drawLetters(int count) {
    List<String> drawn = [];
    for (int i = 0; i < count && _letters.isNotEmpty; i++) {
      drawn.add(_letters.removeAt(0));
    }
    return drawn;
  }

  bool get isEmpty => _letters.isEmpty;

  int get remainingLetters => _letters.length;
}


class Rack 
{
  List<String> letters = [];
  final int size;
  final LetterBag _letterBag = LetterBag();

  Rack(this.size)
  {
    fill();
  }

  void fill()
  {
    int lettersToDraw = size - letters.length;
    if (lettersToDraw > 0) {
      letters.addAll(_letterBag.drawLetters(lettersToDraw));
    }
  }
}