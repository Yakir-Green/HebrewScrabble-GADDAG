import 'board.dart';
import 'gaddag.dart';
import 'fileManager.dart';

class Solution {
  String encoding;
  (int,int) anchor;
  int score;
  bool isHorizontal;

  Solution(this.encoding, this.anchor, this.isHorizontal) : score = encoding.length; // Placeholder scoring

  @override
  String toString() {
    return 'Solution(encoding: $encoding, anchor: $anchor, score: $score, isHorizontal: $isHorizontal)';
  }
}

Set<Solution> assembleAllPossibleSolutions(GADDAG dictionary, List<String> rack, Board board)
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
      lettersBefore += board.getTile(board.after(currentPos, isHorizontal));
      currentPos = board.after(currentPos, isHorizontal);
    }

    currentPos = pos;
    while(board.isTileFilled(board.before(currentPos, isHorizontal)))
    {
      lettersAfter += board.getTile(board.before(currentPos, isHorizontal));
      currentPos = board.before(currentPos, isHorizontal);
    }

    if(lettersBefore.isEmpty && lettersAfter.isEmpty)
    {
      // No cross-check needed
      return validLetters;
    }

    for(String letter in rack)
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

    if(currentNode.isEndOfWord)
    {
      result.add(Solution(string, anchorPos, isHorizontal));
    }

    if(board.isTileInBounds(currentPos) == false)
    {
      return;
    }

    if(board.isTileFilled(currentPos))
    {
      String boardLetter = board.getTile(currentPos);
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
      if(rack.contains(letter) && _crossCheck(currentPos, !isHorizontal).contains(letter))
      {
        rack.remove(letter);

        if(arrivedDelimiter)
        {
          _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, arrivedDelimiter, board.after(currentPos, isHorizontal), anchorPos, isHorizontal);
        }
        else
        {
           _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, arrivedDelimiter, board.before(currentPos, isHorizontal), anchorPos, isHorizontal);
        }

        rack.add(letter);
      }
      else if(letter == '+')
      {
        _findAllPossibleWordsForAnchor(string + letter, currentNode.children[letter]!, true, board.after(anchorPos, isHorizontal), anchorPos, isHorizontal);
      }
    }
  }

    board.anchors.forEach((anchor) {
      {
        _findAllPossibleWordsForAnchor(
          '',
          dictionary.root,
          false,
          anchor,
          anchor,
          true,
        );
      }
    });

    board.anchors.forEach((anchor) {
      {
        _findAllPossibleWordsForAnchor(
          '',
          dictionary.root,
          false,
          anchor,
          anchor,
          false,
        );
      }
    });

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
  board.tiles.forEach(print);

  print("Anchors: ${board.anchors}");

  // Load words from a file
  final string = await readStringFromFileAsync('Data/MinimizedGADDAG.json');
  var dictionary = GADDAG.fromJson(string);
  // var dictionary = GADDAG(['שלום', 'תולס', 'מלא', 'מרס', 'תור', 'תול', 'מת', 'כתר', 'שלם', 'לום', 'מלוא', 'סמר', 'ארם']);

  print('Time to reach this line: ${stopwatch.elapsedMilliseconds}ms');

  print('number of nodes in GADDAG: ${dictionary.nodeCount}');

  Set<Solution> solutions = assembleAllPossibleSolutions(dictionary, ['ח', 'ת', 'ו', 'ל','ס', 'ר','א','מ','ל','א'], board);

  print('Time to reach this line: ${stopwatch.elapsedMilliseconds}ms');
  // print(solutions);
  print('nubmer of solutions found: ${solutions.length}');

  Solution? bestSolution = findBestSolution(solutions);
  print("Best solution: $bestSolution");

  if (bestSolution != null) {
    board.insertEncodingString(dictionary, bestSolution.anchor, bestSolution.encoding, bestSolution.isHorizontal);
    print("Board after inserting solution:");
    board.tiles.forEach(print);
  }

    stopwatch.stop();
    print('Total time: ${stopwatch.elapsedMilliseconds}ms');
}