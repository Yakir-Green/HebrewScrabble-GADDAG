class GADDAGNode {
  Map<String, GADDAGNode> children = {};
  bool isEndOfWord = false;
}


//- GADDAG is a playful twist: it’s DAG (Directed Acyclic Graph) prefixed by its reverse, GAD, forming GADDAG
//A GADDAG is a specific type of DAG, invented by Steven Gordon for use in Scrabble-playing computer programs. 
//The palindromic nature of the name "GADDAG" is likely a nod to how the data structure allows for building words by moving both forwards and backwards from any given letter
class GADDAG {
  final GADDAGNode root = GADDAGNode();
  static const String delimiter = '+';

  // Use a set for presence checks
  final Set<String> words = {};

  Map<String, String> encodingCache = {};

  // Constructor: avoid shadowing field name
  GADDAG([List<String>? initialWords]) {
    if (initialWords != null) {
      for (var w in initialWords) {
        insertWord(w);
      }
    }
  }

  /// Insert a word into the GADDAG
  void insertWord(String word) {
    // register the original word in the set
    words.add(word);

    // normalize final-letter forms (Hebrew final letters) — replace ף with פ
    word = word.replaceAll('ף', 'פ');
    word = word.replaceAll('ך', 'כ');
    word = word.replaceAll('ם', 'מ');
    word = word.replaceAll('ן', 'נ');
    word = word.replaceAll('ץ', 'צ');

    // register the normalized word in the set
    words.add(word);

    for (int i = 0; i < word.length; i++) {
      String left = word.substring(0, i + 1);
      String right = word.substring(i + 1);

      // Reverse the left part
      String reversedLeft = left.split('').reversed.join('');

      // Build encoding: reversedLeft + delimiter + right
      String encoding = reversedLeft + delimiter + right;

      _insertEncoding(encoding);
      // Cache the encoding
      encodingCache[encoding] = word;
    }
  }

  void _insertEncoding(String encoding) {
    GADDAGNode current = root;
    for (int i = 0; i < encoding.length; i++) {
      String ch = encoding[i];
      current.children.putIfAbsent(ch, () => GADDAGNode());
      current = current.children[ch]!;
    }
    current.isEndOfWord = true;
  }

  /// Check if an encoding exists in the GADDAG
  bool containsEncoding(String encoding) {
    GADDAGNode current = root;
    for (int i = 0; i < encoding.length; i++) {
      String ch = encoding[i];
      if (!current.children.containsKey(ch)) return false;
      current = current.children[ch]!;
    }
    return current.isEndOfWord;
  }

  /// Returns true if the original word is present in the GADDAG (via the set)
  bool containsWord(String word) {
    return words.contains(word);
  }

  GADDAGNode? getNodeForEncoding(String encoding) {
    GADDAGNode current = root;
    for (int i = 0; i < encoding.length; i++) {
      String ch = encoding[i];
      if (!current.children.containsKey(ch)) return null;
      current = current.children[ch]!;
    }
    return current;
  }

  /// Debug: print all encodings stored
  void printEncodings([String prefix = "", GADDAGNode? node]) {
    node ??= root;
    if (node.isEndOfWord) {
      print(prefix);
    }
    for (var entry in node.children.entries) {
      printEncodings(prefix + entry.key, entry.value);
    }
  }
}

void main() {
  List<String> words = ["תפוח", "כלוב"];
  GADDAG gaddag = GADDAG(words);

  print("Stored encodings:");
  gaddag.printEncodings();
}
