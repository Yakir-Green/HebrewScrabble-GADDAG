import 'board.dart';
import 'gaddag.dart';
import 'fileManager.dart';
import 'rack.dart';

class Solution {
  final String word;
  final (int,int) startPos;
  final List<String> adjacentWords;
  late final int score;
  final bool isHorizontal;

  Solution(this.word, this.startPos, this.isHorizontal, this.adjacentWords)
  {
    score = _calculateScore();
  } 

  int _calculateScore() {
    int _score = 0;

    // Score for the main word
    for (int i = 0; i < word.length; i++) {
      _score += letterValues[word[i]] ?? 0;
    }

    // Score for adjacent words
    for (String adjWord in adjacentWords) {
      for (int i = 0; i < adjWord.length; i++) {
        _score += letterValues[adjWord[i]] ?? 0;
      }
    }

    return _score;
  }

  @override
  String toString() {
    return 'Solution(word: $word, startPos: $startPos, score: $score, isHorizontal: $isHorizontal, adjacentWords: $adjacentWords)';
  }
}

Set<Solution> assembleAllPossibleSolutions(GADDAG dictionary, Rack rack, Board board)
{
  Set<Solution> result = {};

  // Helper function to get cross-check letters for an anchor position
  Set<String> _crossCheck((int, int) pos, bool isHorizontal)
  {
    Set<String> validLetters = {'א','ב','ג','ד','ה','ו','ז','ח','ט','י','כ','ל','מ','נ','ס','ע','פ','צ','ק','ר','ש','ת'};

    //Horizontal cross-check
    String lettersBefore = '';
    String lettersAfter = '';

    (int, int) currentPos = pos;

    while(board.isTileFilled(board.after(currentPos, isHorizontal)))
    {
      lettersBefore += board.getTile(board.after(currentPos, isHorizontal)).letter;
      currentPos = board.after(currentPos, isHorizontal);
    }

    currentPos = pos;
    while(board.isTileFilled(board.before(currentPos, isHorizontal)))
    {
      lettersAfter += board.getTile(board.before(currentPos, isHorizontal)).letter;
      currentPos = board.before(currentPos, isHorizontal);
    }

    if(lettersBefore.isEmpty && lettersAfter.isEmpty)
    {
      // No cross-check needed
      return validLetters;
    }

    for(String letter in rack.letters)
    {
      String formedWord = lettersAfter + letter + lettersBefore;
      if(dictionary.words.contains(formedWord))
      {
        continue;
      }
      else
      {
        validLetters.remove(letter);
      }
    }

    return validLetters;
  }


  _findAllPossibleWordsForAnchor(String string, GADDAGNode currentNode, bool arrivedDelimiter, (int,int) currentPos, (int, int) anchorPos, bool isHorizontal)
  {

    //*****FOUND A SOLUTION*******/
    if(currentNode.isEndOfWord)
    {
      var (String originalWord, (int,int) startPos) = board.getOriginalWordAndStartPosFromEncoding(
        dictionary,
        anchorPos,
        string,
        isHorizontal,
      );

      if(originalWord == 'במאי' && startPos == (2,3))
      {
        print('debug');
      }

      List<String> adjacentWords = board.getAdjacentWords(startPos, originalWord, isHorizontal);
      result.add(Solution(originalWord, startPos, isHorizontal, adjacentWords));
    }
    //****************************/

    if(board.isTileInBounds(currentPos) == false)
    {
      return;
    }

    if(board.isTileFilled(currentPos))
    {
      String boardLetter = board.getTile(currentPos).letter;
      if(currentNode.children.containsKey(boardLetter))
      {
        if(arrivedDelimiter)
        {
          _findAllPossibleWordsForAnchor(string + boardLetter, currentNode.children[boardLetter]!, arrivedDelimiter, board.after(currentPos, isHorizontal), anchorPos, isHorizontal);
        }
        else
        {
           _findAllPossibleWordsForAnchor(string + boardLetter, currentNode.children[boardLetter]!, arrivedDelimiter, board.before(currentPos, isHorizontal), anchorPos, isHorizontal);
        }
      }
      return;
    }

    for(String letter in currentNode.children.keys)
    {
      if(rack.letters.contains(letter) && board.getTile(currentPos).validLetters.contains(letter)) // _crossCheck(currentPos, !isHorizontal).contains(letter))
      {
        rack.letters.remove(letter);

        if(arrivedDelimiter)
        {
          _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, arrivedDelimiter, board.after(currentPos, isHorizontal), anchorPos, isHorizontal);
        }
        else
        {
           _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, arrivedDelimiter, board.before(currentPos, isHorizontal), anchorPos, isHorizontal);
        }

        rack.letters.add(letter);
      }
      else if(letter == '+')
      {
        _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, true, board.after(anchorPos, isHorizontal), anchorPos, isHorizontal);
      }
    }
  }

for (final isHorizontal in [true, false]) {
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        (int, int) pos = (row, col);
        Set<String> validLetters = _crossCheck(pos, !isHorizontal);
        board.tiles[row][col].validLetters = validLetters;
      }
    }

    for (final anchor in board.anchors) {
      _findAllPossibleWordsForAnchor(
        '',
        dictionary.root,
        false,
        anchor,
        anchor,
        isHorizontal,
      );
    }
  }

  return result;
}


Solution? findBestSolution(Set<Solution> solutions)
{
  if(solutions.isEmpty)
  {
    return null;
  }

  Solution? bestSolution;
  for(Solution solution in solutions)
  {
    if(bestSolution == null || solution.score > bestSolution.score)
    {
      bestSolution = solution;
    }
  }
  return bestSolution!;
}

void main() async {
  final stopwatch = Stopwatch()..start();


  var board = Board(7);
  board.insertString((2,2), 'מת', false);
  
  print("Board after 'מת':");
  board.tiles.forEach(print);


  board.insertString((3,3), 'כתר',true);
    print("Board after 'כתר':");
  board.printToLog();

  print("Anchors: ${board.anchors}");

  // Load words from a file
  final string = await readStringFromFileAsync('Data/MinimizedGADDAG.json');
  var dictionary = GADDAG.fromJson(string);

  print('Time to reach this line: ${stopwatch.elapsedMilliseconds}ms');

  print('number of nodes in GADDAG: ${dictionary.nodeCount}');

  Rack rack = Rack(7);
  // rack.letters = ['ב', 'א', 'ר', 'א', 'מ', 'י', 'א'];
  print('Rack letters: ${rack.letters}');

  Set<Solution> solutions = assembleAllPossibleSolutions(dictionary, rack, board);

  print('Time to reach this line: ${stopwatch.elapsedMilliseconds}ms');
  // print(solutions);
  print('nubmer of solutions found: ${solutions.length}');

  Solution? bestSolution = findBestSolution(solutions);
  print("Best solution: $bestSolution");

  List<String> result = board.getAdjacentWords((1,0), bestSolution!.word, false);
  print('adjacent words: $result');

  if (bestSolution != null) {
    // board.insertEncodingString(dictionary, bestSolution.anchor, bestSolution.encoding, bestSolution.isHorizontal);
    board.insertString(bestSolution.startPos, bestSolution.word, bestSolution.isHorizontal);
    print("Board after inserting solution:");
    print(board.toString());
  }

    stopwatch.stop();
    print('Total time: ${stopwatch.elapsedMilliseconds}ms');
}