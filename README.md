# Dart Scrabble Solver with GADDAG - For the Hebrew Language!

This project is a Dart-based implementation of the core logic for a Scrabble-playing program. It leverages a highly efficient data structure known as a GADDAG to find the optimal move given a board state and a rack of tiles.

## The GADDAG Data Structure

The heart of this solver is the **GADDAG** (Go-Any-Direction-Directed-Acyclic-Graph). A GADDAG is a specialized data structure derived from a trie, designed for extremely fast word lookups in games like Scrabble.

Unlike a standard trie where words are stored from beginning to end, a GADDAG stores every possible "split" of a word. For a word like "WORD", it would store paths for:
- `D+ROW`
- `R+OWD`
- `O+WDR`
- `W+ORD`

The `+` is a special delimiter. This structure allows the graph to be traversed starting from any letter within the word and moving in either direction (left or right of the starting letter). This is crucial for Scrabble, where new words can be formed by adding letters before, after, or on both sides of existing tiles on the board.

### Theoretical Foundation

The use of GADDAGs for Scrabble was pioneered in two influential papers:

1.  [**"The World's Fastest Scrabble Program"**](https://www.cs.cmu.edu/afs/cs/academic/class/15451-s06/www/lectures/scrabble.pdf) by Andrew W. Appel and Guy J. Jacobson. This paper first introduced the use of 'Dawg' as a superior alternative to traditional dictionary structures for move generation, significantly reducing the search space.

2.  [**"A Faster Scrabble Move Generation Algorithm"**](https://users.cs.northwestern.edu/~robby/uc-courses/22001-2008-winter/faster-scrabble-gordon.pdf) by Steven A. Gordon. This paper builds upon the original concept, presenting a refined algorithm for traversing the GADDAG to generate all possible moves from a given "anchor" square on the board. The solver in this project is heavily inspired by the anchor-based move generation strategy described by Gordon.

## Hebrew Language Support

This implementation was specifically developed with the Hebrew language in mind. It includes logic to handle the nuances of Hebrew Scrabble:

- **Letter Normalization**: The GADDAG construction process automatically normalizes Hebrew words by converting final-form letters (Sofit) to their standard equivalents (e.g., `ם` to `מ`, `ף` to `פ`). This ensures that words are correctly recognized regardless of the letter form used.
- **Dictionary**: The GADDAG is built using a Hebrew word list located at `Data/HebrewDictionary.txt`.

## Project Structure

-   **[gaddag.dart](gaddag.dart)**: Contains the implementation of the `GADDAG` and `GADDAGNode` classes. It handles:
    -   Building a GADDAG from a word list.
    -   Minimizing the GADDAG by merging identical subgraphs to save memory.
    -   Serializing the GADDAG to and from a JSON format for quick loading.

-   **[solver.dart](solver.dart)**: Implements the move generation logic. The `assembleAllPossibleSolutions` function iterates through all anchor squares on the board and uses the GADDAG to find every valid word that can be formed.

-   **[board.dart](board.dart)**: A class representing the Scrabble board. It manages tile placement, identifies anchor squares (empty squares adjacent to existing tiles), and handles game state.

-   **[fileManager.dart](fileManager.dart)**: A simple utility for asynchronous file reading and writing.

## How It Works

1.  **Preprocessing**: The `main` function in `gaddag.dart` reads a plain text dictionary (`Data/HebrewDictionary.txt`), constructs a full GADDAG, minimizes it, and saves the result to `Data/MinimizedGADDAG.json`. This is a one-time step that creates a compact and fast-loading representation of the dictionary.

2.  **Solving**: The `main` function in `solver.dart` simulates a game. It loads the pre-processed GADDAG from the JSON file, sets up an initial board, and then uses `assembleAllPossibleSolutions` to find all possible moves from the player's rack. It then identifies and displays the best possible solution.

## How to Run

1.  **Generate the GADDAG file**:
    This will process the dictionary and create the `MinimizedGADDAG.json` file.
    ```sh
    dart run gaddag.dart
    ```

2.  **Run the solver**:
    This will load the generated GADDAG, set up a sample board, and find the best move.
    ```sh
    dart run solver.dart
    ```
