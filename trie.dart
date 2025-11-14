// ignore_for_file: file_names, avoid_print
class Node<T> {
  Map<T, Node<T>> children = {};
  bool isEndOfWord = false;

  Node([bool? isEndOfWord])
  {
    if(isEndOfWord != null) {
      this.isEndOfWord = isEndOfWord;
    }
  }
}

class Trie<T> {
  Node<T> root = Node(false);
}

class DictionaryTrie extends Trie<String>
{
  DictionaryTrie([List<String>? words])
  {
    if(words != null && words.isNotEmpty)
    {
      for (String word in words) {
        Node<String> currentNode = root;
        for(String letter in word.split(''))
        {
          if(currentNode.children.containsKey(letter) == false)
          {
            currentNode.children[letter] = Node(false);
          }
          currentNode = currentNode.children[letter]!;
        } 
        currentNode.isEndOfWord = true;
      }
    }
  }

  bool lookUp(String word) {
    Node<String> currentNode = root;
    for(String letter in word.split(''))
    {
      if(currentNode.children.containsKey(letter) == false)
      {
        return false;
      }
      currentNode = currentNode.children[letter]!;
    } 
    return currentNode.isEndOfWord;
  }
}






