import 'gaddag.dart';

enum LanguageDirection {
  RTL(-1),
  LTR(1);
  final int value;
  const LanguageDirection(this.value);
}

class Board 
{
  final int size;
  List<List<String>> tiles = [];
  bool isBoardEmpty = true;
  Set<(int,int)> anchors = {};
  int isRTL = LanguageDirection.RTL.value;

  Board(this.size)
  {
    tiles = List.generate(size, (_) => List.generate(size, (_) => '~'));
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
    return tiles[row][col] != '~' && tiles[row][col] != '*';
  }

  bool isTileEmpty((int, int) pos)
  {
    return !isTileFilled(pos);
  }

  String getTile((int, int) pos)
  {
    var (row, col) = pos;
    return tiles[row][col];
  }

  insertString((int, int) pos, String string, bool isHorizontal)
  {
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
        tiles[row][col + (i * isRTL)] = string[i];
      }
      else
      {
        tiles[row + i][col] = string[i];
      }
    }
    _updateAnchors(pos, string.length, isHorizontal);
  }

  insertEncodingString(
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
    if (originalWord.isNotEmpty) {
      insertString(startPos, originalWord, isHorizontal);
    }
  }

  _updateAnchors((int, int) pos, int length, bool isHorizontal) {
    var (row, col) = pos;

    int startRow = row - 1;
    int endRow = isHorizontal ? row + 1 : row + length;

    int startCol = col - 1;
    int endCol = isHorizontal ? col + length : col + 1;

    if(isHorizontal && isRTL == -1) {
      startCol = col - length;
      endCol = col + 1;
    }

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
        tiles[row][col] = '~';
      }
      return;
    }

    if(isTileFilled(up(pos)) || isTileFilled(down(pos)) || isTileFilled(left(pos)) || isTileFilled(right(pos)))
    {
      if (anchors.add(pos)) {
        tiles[row][col] = '*';
      }
    }
    else
    {
      if (anchors.remove(pos)) {
        tiles[row][col] = '~';
      }
    }
  }

  Board copy()
  {
    Board copiedBoard = Board(size);
    copiedBoard.tiles = tiles.map((row) => List<String>.from(row)).toList();
    copiedBoard.isBoardEmpty = isBoardEmpty;
    copiedBoard.anchors = Set.from(anchors);
    return copiedBoard;
  }
}