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

int GRIDWIDTH  = 20;
int GRIDHEIGHT = 16;
int MINES      = 50;
int CELLSIZE   = 32;  // tied to image sizes, don't change

PImage imgNormal, imgRevealed, imgMine, imgFlag;
PFont font;
Board board;

void setup() {

  // set window size to fit board
  size(CELLSIZE * GRIDWIDTH, CELLSIZE * GRIDHEIGHT);

  // initialize board
  board = new Board(GRIDWIDTH, GRIDHEIGHT, MINES);

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
          keyCode    == SHIFT) {

        // shift left click
        board.shiftClick(cellUnderMouse());
      } else {

        // left click
        board.click(cellUnderMouse());
      }
    } else {

      // right click
      board.rightClick(cellUnderMouse());
    }
  } else {
    board.newGame();
  }
}

// converts mouseX & mouseY => col & row and return the cell under the mouse
Cell cellUnderMouse() {
  int row = mouseY / CELLSIZE;
  int col = mouseX / CELLSIZE;

  return board.cell(row, col);
}

// displays a message with a background color c
void messageBox(String message, color c) {
  fill(c);
  rect(0, 0, width, height);
  fill(255);
  text(message, width / 2, height / 2);
}

class Cell {
  boolean mine     = false;
  boolean revealed = false;
  boolean flagged  = false;
  int x, y;
  int adjMines = 0; // number of adjacent mines

  Cell(int x, int y) {
    this.x = x;
    this.y = y;
  }

  boolean isRevealed() {
    return revealed;
  }

  boolean isFlagged() {
    return flagged;
  }

  boolean isMine() {
    return mine;
  }

  int adjMines() {
    return adjMines;
  }

  void toggleFlagged() {
    flagged = !flagged;
  }

  void reveal() {
    revealed = true;
  }

  void setMine() {
    mine = true;
  }

  void setAdjMines(int n) {
    adjMines = n;
  }

  void reset() {
    mine     = false;
    revealed = false;
    flagged  = false;
    adjMines = 0;
  }

  color[] colors = { color(0   , 0   , 255) ,  // blue
                     color(0   , 200 , 0  ) ,  // green
                     color(255 , 0   , 0  ) ,  // red
                     color(0   , 0   , 150) ,  // dark blue
                     color(165 , 40  , 40 ) ,  // brown
                     color(0   , 255 , 255) ,  // cyan
                     color(0   , 0   , 0  ) ,  // black
                     color(75  , 75  , 75 ) }; // gray

  void drawCell(int row, int col, boolean isShowingMines) {
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

class Board {
  Cell[][] cells;
  int boardWidth, boardHeight, mines, flags;
  boolean firstClick     = true;
  boolean gameOver       = false;
  boolean gameWon        = false;
  boolean isShowingMines = false;
  int startMillis = 0;
  float time = 0;

  Board(int boardWidth, int boardHeight, int mines) {
    this.cells       = new Cell[boardHeight][boardWidth];
    this.boardWidth  = boardWidth;
    this.boardHeight = boardHeight;
    this.mines       = mines;

    // create grid of cells
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col] = new Cell(col, row);
      }
    }
  }

  int boardWidth() {
    return boardWidth;
  }

  int boardHeight() {
    return boardHeight;
  }

  boolean gameRunning() {
    return !(gameOver || gameWon);
  }

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
        cells[row][col].setAdjMines(countMines(neighbors(cells[row][col])));
      }
    }
  }

  // reveal a cell if game isn't over, place mines after first click
  // if game is over, restart game
  void click(Cell cell) {
    if (cell.isMine()) {
      gameOver = true;
      isShowingMines = true;
    } else {

      if (firstClick) {
        placeMines(cell);
        firstClick = false;
        startMillis = millis();
      }

      revealCell(cell);

      if (won()) {
        isShowingMines = true;
        gameWon = true;
      }
    }
  }

  // flag a cell
  void rightClick(Cell cell) {
    cell.toggleFlagged();

    flags += cell.isFlagged() ? 1 : -1;
  }

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
    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        cells[row][col].reset();
      }
    }

    isShowingMines = false;
    firstClick     = true;
    gameOver       = false;
    gameWon        = false;
    time = 0;
    flags = 0;
  }

  // counts the number of mines in an array of cells
  int countMines(ArrayList<Cell> cells) {
    int count = 0;

    for (Cell cell : cells) {
      if (cell.isMine()) {
        count++;
      }
    }

    return count;
  }

  int[][] directions = {{ -1, -1 }, { -1, 0 }, { -1, 1 },
                        { 0 , -1 }, { 0 , 1 },
                        { 1 , -1 }, { 1 , 0 }, { 1 , 1 }};

  // return an array of adjacent cells of a given cell
  ArrayList<Cell> neighbors(Cell cell) {
    ArrayList<Cell> result = new ArrayList<Cell>();

    for (int[] direction : directions) {
      int neighborRow = cell.y + direction[1];
      int neighborCol = cell.x + direction[0];

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

  // draw the board, passing mouseX, mouseY, and mousePressed
  void drawBoard(int mx, int my, boolean pressed) {
    if (!firstClick && gameRunning()) {
      time = (millis() - startMillis) * 0.001;
    }

    frame.setTitle("⏰: " + String.format("%.3f", time) + " 💣: " + (mines - flags));

    for (int row = 0; row < boardHeight; row++) {
      for (int col = 0; col < boardWidth; col++) {
        // draw each cell
        cells[row][col].drawCell(row, col, isShowingMines);

        if ((int) (my / CELLSIZE) == row &&
            (int) (mx / CELLSIZE) == col &&
            !cells[row][col].isRevealed()) {

          // highlight cell under mouse
          fill(255, 50);

          if (pressed) {

            // darken if mouse is pressed
            fill(0, 30);
          }

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

