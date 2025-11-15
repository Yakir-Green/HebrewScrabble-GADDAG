import 'dart:collection';
import 'dart:convert';
import 'fileManager.dart';

/// A node in the GADDAG data structure.
class GADDAGNode {
  /// A map of child characters to their corresponding nodes.
  final Map<String, GADDAGNode> children = {};

  /// A flag indicating if this node represents the end of a valid word path.
  bool isEndOfWord = false;

  /// Default unnamed constructor.
  GADDAGNode();

  /// Creates a GADDAGNode from a JSON map.
  GADDAGNode.fromJson(Map<String, dynamic> json)
      : isEndOfWord = json['e'] as bool;

  /// Converts a GADDAGNode to a JSON map.
  Map<String, dynamic> toJson(Map<GADDAGNode, int> nodeIds) {
    final Map<String, int> childIds = {};
    children.forEach((char, node) {
      childIds[char] = nodeIds[node]!;
    });
    return {'e': isEndOfWord, 'c': childIds};
  }

  /// Adds a child node for a given character.
  GADDAGNode addChild(String char) {
    return children.putIfAbsent(char, () => GADDAGNode());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GADDAGNode) return false;

    if (isEndOfWord != other.isEndOfWord) return false;
    if (children.length != other.children.length) return false;

    for (final key in children.keys) {
      if (!other.children.containsKey(key) || children[key] != other.children[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    // This simple hash is sufficient for the minimization logic which relies on
    // structural equality checks, but a more robust hash could be implemented
    // by combining the hash codes of children.
    return isEndOfWord.hashCode ^ children.length.hashCode;
  }
}

/// A GADDAG (Go-Any-Direction-Directed-Acyclic-Graph) is a data structure
/// for storing a dictionary of words for efficient lookups, particularly in
/// word games like Scrabble. This implementation is minimized, meaning
/// identical sub-trees are merged to save space.
class GADDAG {
  /// The root node of the GADDAG.
  late final GADDAGNode root;

  /// A special character used to denote the "turn" in the word path.
  static const String breakChar = '+';

  Map<String, String> encodingCache = {};

  Set<String> words = {};

  int nodeCount = 1;

  /// Constructs a minimized GADDAG from a list of words.
  GADDAG(List<String> words) {
    final tempRoot = GADDAGNode();
    for (final word in words) {
      _addWord(tempRoot, word);
    }
    root = _minimize(tempRoot);
  }

  /// Constructs a GADDAG from a JSON string.
  GADDAG.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    final List<dynamic> nodeList = data['nodes'];
    final List<GADDAGNode> nodes =
        nodeList.map((nodeData) => GADDAGNode.fromJson(nodeData)).toList();

    for (int i = 0; i < nodeList.length; i++) {
      final Map<String, dynamic> nodeData = nodeList[i];
      final GADDAGNode node = nodes[i];
      if (nodeData['c'] != null) {
        (nodeData['c'] as Map<String, dynamic>).forEach((char, childId) {
          node.children[char] = nodes[childId as int];
        });
      }
    }

    root = nodes[data['rootId'] as int];
    words = (data['words'] as List<dynamic>).map((e) => e.toString()).toSet();
    encodingCache = (data['encodingCache'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value.toString()));
    nodeCount = nodes.length;
  }

  /// Serializes the GADDAG to a JSON string.
  String toJson() {
    final Map<GADDAGNode, int> nodeIds = {};
    final List<GADDAGNode> nodeQueue = [];
    final List<Map<String, dynamic>> serializedNodes = [];

    nodeIds[root] = 0;
    nodeQueue.add(root);
    int head = 0;

    while (head < nodeQueue.length) {
      final currentNode = nodeQueue[head];

      // Ensure all children are in the queue and have an ID before serializing the current node.
      currentNode.children.forEach((char, childNode) {
        if (!nodeIds.containsKey(childNode)) {
          nodeIds[childNode] = nodeQueue.length;
          nodeQueue.add(childNode);
        }
      });

      serializedNodes.add(currentNode.toJson(nodeIds));
      head++;
    }

    return jsonEncode({
      'rootId': nodeIds[root],
      'nodes': serializedNodes,
      'words': words.toList(),
      'encodingCache': encodingCache,
    });
  }

  /// Adds a single word to a temporary, unminimized GADDAG.
  void _addWord(GADDAGNode rootNode, String word) {
    // Store the word in the set of words.
    words.add(word);

    word = word.replaceAll('ף', 'פ');
    word = word.replaceAll('ך', 'כ');
    word = word.replaceAll('ם', 'מ');
    word = word.replaceAll('ן', 'נ');
    word = word.replaceAll('ץ', 'צ');

    // register the normalized word in the set
    words.add(word);

    // Add all paths representing the word and its rotations.
    for (int i = 1; i <= word.length; i++) {
      final prefix = word.substring(0, i);
      final suffix = word.substring(i);


      String reversedPrefix = prefix.split('').reversed.join('');

      // Build encoding: reversedLeft + delimiter + right
      final String encoding = reversedPrefix + breakChar + suffix;
      
      // The path is the prefix, followed by the break character,
      // followed by the reversed suffix.
      
      _addPath(rootNode, encoding);

      // Cache the encoding for later retrieval.
      encodingCache[encoding] = word;
    }
  }

  /// Adds a string path to a node, creating child nodes as needed.
  void _addPath(GADDAGNode node, String path) {
    GADDAGNode currentNode = node;
    for (int i = 0; i < path.length; i++) {
      currentNode = currentNode.addChild(path[i]);
    }
    currentNode.isEndOfWord = true;
  }

  /// Recursively minimizes the GADDAG starting from a given node.
  /// It uses a post-order traversal (depth-first) to ensure that a node's
  /// children are minimized before the node itself is processed.
  GADDAGNode _minimize(GADDAGNode node, [HashMap<int, List<GADDAGNode>>? registry]) {
    registry ??= HashMap<int, List<GADDAGNode>>();

    // Minimize all children first (post-order traversal).
    final minimizedChildren = <String, GADDAGNode>{};
    node.children.forEach((char, childNode) {
      minimizedChildren[char] = _minimize(childNode, registry);
    });
    node.children.clear();
    node.children.addAll(minimizedChildren);

    final nodeHash = node.hashCode;
    final potentialMatches = registry[nodeHash];

    // Look for an existing, equivalent node in the registry.
    if (potentialMatches != null) {
      for (final existingNode in potentialMatches) {
        if (node == existingNode) {
          // Found an identical node, return the canonical instance.
          return existingNode;
        }
      }
    }

    // No equivalent node found. Add this node to the registry as the
    // canonical instance for its structure.
    registry.putIfAbsent(nodeHash, () => []).add(node);
    nodeCount++;
    return node;
  }
}

void main() async
{
    // Load words from a file
  final words = await loadWordsFromFileAsync('Data/HebrewDictionary.txt');
  var dictionary = GADDAG(words);

  // save the GADDAG to a file
  final gaddagJson = dictionary.toJson();
  await writeStringToFileAsync('Data/MinimizedGADDAG.json', gaddagJson);
  
}