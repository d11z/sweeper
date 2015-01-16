/*
 * sweeper
 * Deniz Basegmez
 * 12/22/14
 *
 * a simple minesweeper clone
 * [left click]         reveal cell
 * [right click]        flag cell
 * [shift + left click] chord
 */

int GRIDWIDTH  = 20; // width of board
int GRIDHEIGHT = 16; // height of board
int MINECOUNT  = 30; // number of mines to place
int CELLSIZE   = 32; // tied to image sizes, don't change

// image resources
PImage imgNormal, imgRevealed, imgMine, imgFlag;

// custom font
PFont font;

Board board;

void setup() {

  // set window size to fit board
  size(CELLSIZE * GRIDWIDTH, CELLSIZE * GRIDHEIGHT);

  // initialize board
  board = new Board(GRIDWIDTH, GRIDHEIGHT, MINECOUNT);

  // load images & fonts
  imgNormal   = loadImage("cell.png");
  imgRevealed = loadImage("cell_down.png");
  imgMine     = loadImage("mine.png");
  imgFlag     = loadImage("flag.png");
  font        = loadFont("font.vlw");

  // set drawing options
  textAlign(CENTER, CENTER);
  textFont(font, 18);
  noStroke();
}

void draw() {
  board.drawBoard(mouseX, mouseY, mousePressed);
}

void mouseClicked() {
  if (board.gameRunning()) {
    if (mouseButton == LEFT) {
      if (keyPressed == true &&
          key        == CODED &&
          keyCode    == SHIFT) { // shift left click
        board.shiftClick(cellUnderMouse());
      } else { // left click
        board.click(cellUnderMouse());
      }
    } else { // right click
      board.rightClick(cellUnderMouse());
    }
  } else { // game is not running, restart game
    board.newGame();
  }
}

// converts mouseX & mouseY => col & row and return the cell under the mouse
Cell cellUnderMouse() {
  int row = mouseY / CELLSIZE;
  int col = mouseX / CELLSIZE;

  return board.cell(row, col);
}

// displays a message with a background color
void messageBox(String message, color c) {

  // fill screen with transparent overlay
  fill(c);
  rect(0, 0, width, height);

  // print message in middle of screen
  fill(255);
  text(message, width / 2, height / 2);
}

// used in Board, contains all information about a specific cell on the board
class Cell {
  boolean mine     = false; // is the cell a mine?
  boolean revealed = false; // is the cell revealed?
  boolean flagged  = false; // is the cell flagged?
  int row, col;             // position on board
  int adjMines = 0;         // number of adjacent mines

  Cell(int row, int col) {
    this.row = row;
    this.col = col;
  }

  // getter for revealed
  boolean isRevealed() {
    return revealed;
  }

  // getter for flagged
  boolean isFlagged() {
    return flagged;
  }

  // getter for mine
  boolean isMine() {
    return mine;
  }

  // getter for adjMines
  int adjMines() {
    return adjMines;
  }

  // setter that toggles flagged
  void toggleFlagged() {
    flagged = !flagged;
  }

  // setter that reveals cell
  void reveal() {
    revealed = true;
  }

  // setter that makes the cell a mine
  void setMine() {
    mine = true;
  }

  // setter for adjMines
  void setAdjMines(int n) {
    adjMines = n;
  }

  // reset the Cell
  void reset() {
    mine     = false;
    revealed = false;
    flagged  = false;
    adjMines = 0;
  }

  // array of colors to color number of adjacent cells text based on number
  color[] colors = { color(0   , 0   , 255) ,  // blue
                     color(0   , 200 , 0  ) ,  // green
                     color(255 , 0   , 0  ) ,  // red
                     color(0   , 0   , 150) ,  // dark blue
                     color(165 , 40  , 40 ) ,  // brown
                     color(0   , 255 , 255) ,  // cyan
                     color(0   , 0   , 0  ) ,  // black
                     color(75  , 75  , 75 ) }; // gray

  // draws the cell on screen
  void drawCell(boolean isShowingMines) {
    pushMatrix();
    translate(col * CELLSIZE, row * CELLSIZE);

    // draw inset tile if revealed
    if (revealed) {
      image(imgRevealed, 0, 0);

      // print number of mines in middle of non-zero cells
      if (adjMines > 0) {

        // set color based on number of mines
        fill(colors[adjMines - 1]);
        text(adjMines, CELLSIZE / 2, CELLSIZE / 2);
      }
    } else {

      // draw normal tile
      image(imgNormal, 0, 0);

      // draw flag
      if (flagged) {
        image(imgFlag, 0, 0);
      }
    }

    // reveal mines
    if (isShowingMines && mine) {
      image(imgMine, 0, 0);
    }

    popMatrix();
  }
}

// contains all information for a minesweeper game
class Board {
  Cell[][] cells;      // 2D array of Cells, row-based
  int boardWidth;      // width of cell grid
  int boardHeight;     // height of cell grid
  int mines;           // # of mines on board
  int flags;           // # of flagged cells
  int startMillis = 0; // value of millis() at the start of game
  float time = 0;      // time elapsed since start of game
  boolean firstClick = true;  // has the user made the first move?
  boolean gameOver   = false; // is the game over?
  boolean gameWon    = false; // has the user won?

  Board(int boardWidth, int boardHeight, int mines) {
    this.cells       = new Cell[boardHeight][boardWidth];
    this.boardWidth  = boardWidth;
    this.boardHeight = boardHeight;
    this.mines       = mines;

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col] = new Cell(row, col);
      }
    }
  }

  // getter for width of cell grid
  int boardWidth() {
    return boardWidth;
  }

  // getter for height of cell grid
  int boardHeight() {
    return boardHeight;
  }

  // returns true if game isn't over
  boolean gameRunning() {
    return !(gameOver || gameWon);
  }

  // returns the cell at row, col
  Cell cell(int row, int col) {
    return cells[row][col];
  }

  // randomly disperse mines on board
  void placeMines(Cell clickedCell) {
    Cell cell;
    int count = 0;

    while(count < mines) {

      // pick a random grid spot
      cell = cells[(int)random(boardHeight)][(int)random(boardWidth)];

      // if it's not already a mine and not the provided cell, set a mine
      if (!cell.isMine() && cell != clickedCell) {
        cell.setMine();
        count++;
      }
    }

    calculateMines();
  }

  // calculate and store mine counts of each cell
  void calculateMines() {
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        int adjCount = 0;

        for (Cell cell : neighbors(cells[row][col])) {
          if (cell.isMine()) {
            adjCount++;
          }
        }

        cells[row][col].setAdjMines(adjCount);
      }
    }
  }

  // reveals a cell, places mines if it's the first click
  void click(Cell cell) {
    if (cell.isMine()) {
      gameOver = true;
    } else {

      if (firstClick) {
        placeMines(cell);
        firstClick = false;
        startMillis = millis();
      }

      revealCell(cell);

      if (won()) {
        gameWon = true;
      }
    }
  }

  // flag a cell
  void rightClick(Cell cell) {
    cell.toggleFlagged();

    flags += cell.isFlagged() ? 1 : -1;
  }

  // "chord" click a cell
  void shiftClick(Cell cell) {
    if (cell.isRevealed()) {

      // count how many adjacent flags there are
      int flaggedCount = 0;

      for (Cell neighbor : neighbors(cell)) {
        if (neighbor.isFlagged()) {
          flaggedCount++;
        }
      }

      // if equal to adjMines of that cell, reveal adjacent non-flag cells
      if (flaggedCount == cell.adjMines()) {
        for (Cell neighbor : neighbors(cell)) {
          if (!neighbor.isFlagged() && !neighbor.isRevealed()) {
            click(neighbor);
          }
        }
      }
    }
  }

  // return true if all non-mine cells are revealed
  boolean won() {

    // iterate over each cell on board
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        if (!cells[row][col].isRevealed() && !cells[row][col].isMine()) {

          // return false when a non-revealed non-mine is detected
          return false;
        }
      }
    }

    return true;
  }

  // reveal a cell and it's connected zeros
  void revealCell(Cell cell) {
    if (!cell.isRevealed()) {
      cell.reveal();

      if (cell.adjMines() == 0) {
        for (Cell zero : findConnectedZeros(cell)) {
          zero.reveal();
          for (Cell edge : neighbors(zero)) {
            edge.reveal();
          }
        }
      }
    }
  }

  // reset the board
  void newGame() {

    // reset each cell
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col].reset();
      }
    }

    // reset board variables
    firstClick = true;
    gameOver   = false;
    gameWon    = false;
    time = 0;
    flags = 0;
  }

  // array of direction differences for finding 8 adjacent cells
  int[][] directions = {{ -1, -1 }, { -1, 0 }, { -1, 1 },
                         { 0 , -1 },            { 0 , 1 },
                         { 1 , -1 }, { 1 , 0 }, { 1 , 1 }};

  // return an array of adjacent cells of a given cell
  ArrayList<Cell> neighbors(Cell cell) {
    ArrayList<Cell> result = new ArrayList<Cell>();

    for (int[] direction : directions) {

      // add each direction difference to cell coordinates
      int neighborRow = cell.row + direction[1];
      int neighborCol = cell.col + direction[0];

      // check if in bounds
      if (neighborRow >= 0 && neighborRow < boardHeight) {
        if (neighborCol >= 0 && neighborCol < boardWidth) {
          result.add(cells[neighborRow][neighborCol]);
        }
      }
    }

    return result;
  }

  // return all continuous zeros given a zero
  ArrayList<Cell> findConnectedZeros(Cell zero) {
    Cell curCell;

    // resulting array of connected zeros
    ArrayList<Cell> zeros = new ArrayList<Cell>();

    // queue of cells to be traversed
    ArrayList<Cell> queue = new ArrayList<Cell>();

    // add the clicked cell to the queue
    queue.add(zero);

    while (queue.size() > 0) {

      // pop the first cell from the queue and use it as the current cell
      curCell = queue.get(0);
      queue.remove(0);

      zeros.add(curCell);

      // for all adjacent zeros of the current cell
      for (Cell neighbor : neighbors(curCell)) {
        if (neighbor.adjMines() == 0) {
          if (!zeros.contains(neighbor) && !queue.contains(neighbor)) {

            // add each zero to the queue if not already in zeros or queue
            queue.add(neighbor);
          }
        }
      }
    }

    return zeros;
  }

  String timeEmoji = "\u23F0";
  String bombEmoji = "\uD83D\uDCA3";

  // draw the board, passing mouseX, mouseY, and mousePressed
  void drawBoard(int mx, int my, boolean pressed) {
    if (!firstClick && gameRunning()) {
      time = (millis() - startMillis) * 0.001;
    }

    // sets the title of the window to reflect time remaining and bombs left 
    frame.setTitle(timeEmoji + ": " + String.format("%.3f ", time) +
                   bombEmoji + ": " + (mines - flags));

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {

        // draw each cell, revealing mines if game is over
        cells[row][col].drawCell(!gameRunning());

        if ((int) (my / CELLSIZE) == row &&
            (int) (mx / CELLSIZE) == col &&
            !cells[row][col].isRevealed()) {

          // highlight cell under mouse
          fill(255, 50);

          if (pressed) {

            // darken if mouse pressed
            fill(0, 30);
          }

          // draw highlight/darken overlay
          rect(col * CELLSIZE, row * CELLSIZE, CELLSIZE, CELLSIZE);
        }
      }
    }

    if (gameOver) {
      messageBox("Game over!\nClick to start a new game.", color(255, 0, 0, 100));
    }

    if (gameWon) {
      messageBox("You win!\nClick to start a new game.", color(50, 100));
    }
  }
}

