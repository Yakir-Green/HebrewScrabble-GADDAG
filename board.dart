import 'gaddag.dart';

class Tile 
{
  String letter;
  int bonusMultiplier;
  Set<String> validLetters = {};

  Tile(this.letter, [this.bonusMultiplier = 1]);
}

class Board 
{
  final int size;
  List<List<Tile>> tiles = [];
  bool isBoardEmpty = true;
  Set<(int,int)> anchors = {};

  List<String> wordsOnBoard = [];

  Board(this.size)
  {
    tiles = List.generate(size, (_) => List.generate(size, (_) => Tile('~')));
  }

  Board copy()
  {
    Board copiedBoard = Board(size);
    copiedBoard.tiles = tiles.map((row) => row.map((tile) => Tile(tile.letter, tile.bonusMultiplier)).toList()).toList();
    copiedBoard.isBoardEmpty = isBoardEmpty;
    copiedBoard.anchors = Set.from(anchors);
    return copiedBoard;
  }

  bool isTileInBounds((int, int) pos)
  {
    var (row, col) = pos;
    return (row >= 0 && row < size) && (col >= 0 && col < size);
  }

  bool isWordInBounds(String word, (int, int) pos, bool isHorizontal)
  {
    var (row, col) = pos;

    //Check bounds
    int availableSpace = isHorizontal ? size - col : size - row;
    if(availableSpace <= 0)
    {
      return false;
    }

    return true;
  }

  bool isTileFilled((int, int) pos)
  {
    if(!isTileInBounds(pos)) return false;
    
    var (row, col) = pos;
    return tiles[row][col].letter != '~' && tiles[row][col].letter != '*';
  }

  bool isTileEmpty((int, int) pos)
  {
    return !isTileFilled(pos);
  }

  Tile getTile((int, int) pos)
  {
    var (row, col) = pos;
    return tiles[row][col];
  }

  insertString((int, int) pos, String string, bool isHorizontal)
  {
    wordsOnBoard.add(string);
    if(!isWordInBounds(string, pos, isHorizontal))
    {
      return;
    }
    
    if(isBoardEmpty)
    {
      isBoardEmpty = false;
      // First word must be on center tile for a real game, but we'll allow anywhere for now.
    }

    var (row, col) = pos;
    for(int i = 0; i < string.length; i++)
    {
      if(isHorizontal)
      {
        tiles[row][col - i] = Tile(string[i]);
      }
      else
      {
        tiles[row + i][col] = Tile(string[i]);
      }
    }
    _updateAnchors(pos, string.length, isHorizontal);
  }

  (String originalWord, (int, int) startPos) getOriginalWordAndStartPosFromEncoding(
    GADDAG dictionary,
    (int, int) anchor,
    String encoding,
    bool isHorizontal,
  ) {
    var (anchorRow, anchorCol) = anchor;
    // Find the delimiter position
    int startWordIndex = encoding.indexOf('+') - 1;

    (int, int) startPos;

    if (isHorizontal) {
      startPos = (anchorRow, anchorCol + startWordIndex);
    } else {
      startPos = (anchorRow - startWordIndex, anchorCol);
    }

    String originalWord = dictionary.encodingCache[encoding] ?? '';
    return (originalWord, startPos);
  }



  _updateAnchors((int, int) pos, int length, bool isHorizontal) {
    var (row, col) = pos;

    int startRow = row - 1;
    int endRow = isHorizontal ? row + 1 : row + length;

    int startCol =isHorizontal ? col - length: col - 1;
    int endCol = isHorizontal ? col + 1 : col + length;

    for (int r = startRow; r <= endRow; r++) {
      for (int c = startCol; c <= endCol; c++) {
        updateAnchorStatus((r, c));
      }
    }
  }

  up((int, int) pos)
  {
    var (row,  col) = pos;
    return (row -1, col);
  }

  down((int, int) pos)
  {
    var (row,  col) = pos;
    return (row + 1, col);
  }

  right((int, int) pos)
  {
    var (row,  col) = pos;
    return (row, col + 1);
  }

  left((int, int) pos)
  {
    var (row,  col) = pos;
    return (row, col - 1);
  }

  before((int, int) pos, bool isHorizontal)
  {
    return isHorizontal ? right(pos) : up(pos);
  }

  after((int, int) pos, bool isHorizontal)
  {
    return isHorizontal ? left(pos) : down(pos);
  }

  bool isAnchor((int, int) pos)
  {
    return anchors.contains(pos);
  }

  void updateAnchorStatus((int, int) pos)
  {
    var (row, col) = pos;
    if(!isTileInBounds(pos) || isTileFilled(pos))
    {
      if (anchors.remove(pos) && isTileInBounds(pos) && !isTileFilled(pos)) {
        tiles[row][col] = Tile('~');
      }
      return;
    }

    if(isTileFilled(up(pos)) || isTileFilled(down(pos)) || isTileFilled(left(pos)) || isTileFilled(right(pos)))
    {
      if (anchors.add(pos)) {
        tiles[row][col] = Tile('*');
      }
    }
    else
    {
      if (anchors.remove(pos)) {
        tiles[row][col] = Tile('~');
      }
    }
  }

  List<String> getAdjacentWords((int, int) startPos, String word, bool isHorizontal)
  {
    List<String> adjacentWords = [];
    var (row, col) = startPos;

    for(int i = 0; i < word.length; i++)
    {
      String adjacentWord = '';
      if(isHorizontal)
      {
        // Check vertical
        int r = row;
        // Move up to find the start of the word
        while(isTileInBounds((r - 1, col)) && isTileFilled((r - 1, col)))
        {
          r--;
        }
        // Collect the word
        while(isTileInBounds((r, col)) && (isTileFilled((r, col)) || r == row))
        {
          if(r == row)
          {
            adjacentWord += word[i];
          }
          else
          {
          adjacentWord += getTile((r, col)).letter;
          }
          r++;
        }
      }
      else
      {
        // Check horizontal
        int c = col;
        // Move right to find the start of the word
        while(isTileInBounds((row, c + 1)) && isTileFilled((row, c + 1)))
        {
          c++;
        }
        // Collect the word
        while(isTileInBounds((row, c)) && (isTileFilled((row, c)) || c == col))
        {
          if(c == col)
          {
            adjacentWord += word[i];
          }
          else
          {
            adjacentWord += getTile((row, c)).letter;
          }
          c--;
        }
      }

      if(adjacentWord.length > 1)
      {
        String formedWord = (adjacentWord).split('').reversed.join();
        if(wordsOnBoard.contains(formedWord) == false)
        {
          adjacentWords.add(formedWord);
          // wordsOnBoard.add(formedWord);
        }
      }

      // Move to next position in the main word
      if(isHorizontal)
      {
        col--;
      }
      else
      {
        row++;
      }
    }

    return adjacentWords;

  }

  @override
  String toString() {
    String boardString = '';
    for (var row in tiles) {
      for (var tile in row) {
        boardString += tile.letter + ' ';
      }
      boardString += '\n';
    }
    return boardString;
  }

  printToLog()
  {
    print(toString());
  }
}