/*
 * sweeper
 * Deniz Basegmez
 * 12/22/14
 */

int GRIDSIZE = 20;
int MINES    = 50;
int CELLSIZE = 32;  // tied to image sizes, don't change
PImage imgNormal, imgRevealed, imgMine, imgFlag;
PFont font;
Board board;

void setup() {
  size(CELLSIZE * GRIDSIZE, CELLSIZE * GRIDSIZE);
  board = new Board(GRIDSIZE, MINES);
  loadResources();
  textAlign(CENTER, CENTER);
  textFont(font, 18);
  noStroke();
}

void loadResources() {
  imgNormal   = loadImage("cell.png");
  imgRevealed = loadImage("cell_down.png");
  imgMine     = loadImage("mine.png");
  imgFlag     = loadImage("flag.png");
  font        = loadFont("font.vlw");
}

void draw() {
  background(50);
  board.drawBoard(mouseX, mouseY);
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    board.click();
  } else {
    board.rightClick();
  }
}

void messageBox(String message, color c) {
  fill(c);
  rect(0, 0, width, height);
  fill(255);
  text(message, width / 2, height / 2);
}

class Cell {
  int x, y;
  int nMines = 0;
  boolean isMine       = false;
  boolean isRevealed   = false;
  boolean isFlagged    = false;
  boolean isPressed    = false;

  Cell(int x, int y) {
    this.x = x;
    this.y = y;
  }

  // getters
  boolean isPressed() {
    return isPressed;
  }

  boolean isRevealed() {
    return isRevealed;
  }

  boolean isFlagged() {
    return isFlagged;
  }

  boolean isMine() {
    return isMine;
  }

  int nMines() {
    return nMines;
  }

  // setters
  void toggleFlagged() {
    isFlagged = !isFlagged;
  }

  void reveal() {
    isRevealed = true;
  }

  void setMine() {
    isMine = true;
  }

  void setNMines(int n) {
    nMines = n;
  }

  void reset() {
    isMine = false;
    isRevealed = false;
    isFlagged = false;
    nMines = 0;
  }

  // highlights the cell to indicate the mouse is over it / pressing it
  void highlight() {
    pushMatrix();
    translate(x * CELLSIZE, y * CELLSIZE);

    if (mousePressed) {
      fill(0, 30);
    } else {
      fill(255, 50);
    }

    rect(0, 0, CELLSIZE, CELLSIZE);
    popMatrix();
  }

  color[] colors = { color(0   , 0   , 255) ,   // blue
                     color(0   , 200 , 0)   ,   // green
                     color(255 , 0   , 0)   ,   // red
                     color(0   , 0   , 150) ,   // dark blue
                     color(165 , 40  , 40)  ,   // brown
                     color(0   , 255 , 255) ,   // cyan
                     color(0   , 0   , 0  ) ,   // black
                     color(75  , 75  , 75) };   // gray

  void drawCell(boolean isShowingMines) {
    pushMatrix();
    translate(x * CELLSIZE, y * CELLSIZE);

    // draw inset tile if revealed
    if (isRevealed) {
      image(imgRevealed, 0, 0);
      fill(0, 0, 255);

      // print number of mines in middle of non-zero cells
      if (nMines > 0) {

        // set color based on number of mines
        fill(colors[nMines - 1]);
        text(nMines, CELLSIZE / 2, CELLSIZE / 2);
      }
    } else {
      // draw normal tile
      image(imgNormal, 0, 0);

      // draw flag
      if (isFlagged) {
        image(imgFlag, 0, 0);
      }
    }

    // reveal mines
    if (isShowingMines && isMine) {
      image(imgMine, 0, 0);
    }

    popMatrix();
  }
}

class Board {
  Cell[][] cells;
  int boardSize, mineCount;
  boolean firstClick     = true;
  boolean gameOver       = false;
  boolean gameWon        = false;
  boolean isShowingMines = false;

  Board(int boardSize, int mineCount) {
    this.cells = new Cell[boardSize][boardSize];
    this.boardSize = boardSize;
    this.mineCount = mineCount;

    // create grid of cells
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cells[row][col] = new Cell(col, row);
      }
    }
  }

  // randomly disperse mines on board
  void placeMines(Cell clickedCell) {
    Cell cell;
    int mines = 0;

    while(mines < mineCount) {
      // pick a random grid spot
      cell = cells[(int)random(boardSize)][(int)random(boardSize)];

      // if it's not already a mine and not the provided cell, set a mine
      if (!cell.isMine() && cell != clickedCell) {
        cell.setMine();
        mines++;
      }
    }

    calculateMines();
  }

  // calculate and store mine counts of each cell
  void calculateMines() {
    Cell cell;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cell = cells[row][col];
        cell.setNMines(countMines(neighbors(cell)));
      }
    }
  }

  // reveal a cell if game isn't over, place mines after first click
  void click() {
    if (!gameOver && !gameWon) {
      Cell clickedCell = cellUnderMouse();

      if (clickedCell.isMine()) {
        gameOver = true;
        isShowingMines = true;
      } else {

        if (firstClick) {
          placeMines(clickedCell);
          firstClick = false;
        }

        if (won()) {
          isShowingMines = true;
          gameWon = true;
        }

        revealCell(clickedCell);
      }
    } else {
      newGame();
    }
  }

  // flag a cell
  void rightClick() {
    cellUnderMouse().toggleFlagged();
  }

  // returns true if all non-mine cells are revealed
  boolean won() {

    // go through each cell on board
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (!cells[row][col].isRevealed() && !cells[row][col].isMine()) {

          // returns false when a non-revealed non-mine is detected
          return false;
        }
      }
    }

    return true;
  }

  // returns all continuous zeros given a zero
  ArrayList<Cell> findConnectedZeros(Cell zero) {
    Cell curCell;

    // array of connected zeros
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
        if (neighbor.nMines() == 0) {
          if (!zeros.contains(neighbor) && !queue.contains(neighbor)) {

            // add each zero to the queue if not already in zeros or queue
            queue.add(neighbor);
          }
        }
      }
    }

    return zeros;
  }

  // reveal a cell and it's connected zeros
  void revealCell(Cell cell) {
    if (!cell.isRevealed()) {
      cell.reveal();

      if (cell.nMines() == 0) {
        ArrayList<Cell> edges = new ArrayList<Cell>();
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
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cells[row][col].reset();
        isShowingMines = false;
        firstClick = true;
        gameOver = false;
        gameWon = false;
      }
    }
  }

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

  // return an array of the 8 adjacent cells of a given cell
  ArrayList<Cell> neighbors(Cell cell) {
    ArrayList<Cell> result = new ArrayList<Cell>();

    for (int[] direction : directions) {
      int neighborCol = cell.x + direction[0];
      int neighborRow = cell.y + direction[1];

      if (neighborCol >= 0 && neighborCol < boardSize) {
        if (neighborRow >= 0 && neighborRow < boardSize) {
          result.add(cells[neighborRow][neighborCol]);
        }
      }
    }

    return result;
  }

  int mouseRow, mouseCol;

  // returns the cell currently underneath the mouse
  Cell cellUnderMouse() {
    return cells[mouseRow][mouseCol];
  }

  void drawBoard(int mx, int my) {
    mouseRow = my / CELLSIZE;
    mouseCol = mx / CELLSIZE;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cells[row][col].drawCell(isShowingMines);
      }
    }

    if (!gameOver && !gameWon) {
      cellUnderMouse().highlight();
    }

    if (gameOver) {
      messageBox("Game over!\nClick to start a new game.", color(255, 0, 0, 100));
    }

    if (gameWon) {
      messageBox("You win!\nClick to start a new game.", color(50, 100));
    }
  }
}
