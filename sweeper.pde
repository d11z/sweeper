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
boolean isShowingMines = false;
int[][] directions = {{ -1, -1 }, { -1, 0 }, { -1, 1 },
                      { 0 , -1 }, { 0 , 1 },
                      { 1 , -1 }, { 1 , 0 }, { 1 , 1 }};

void setup() {
  size(CELLSIZE * GRIDSIZE, CELLSIZE * GRIDSIZE);
  board = new Board(GRIDSIZE, MINES);

  // load resources
  imgNormal   = loadImage("cell.png");
  imgRevealed = loadImage("cell_down.png");
  imgMine     = loadImage("mine.png");
  imgFlag     = loadImage("flag.png");
  font        = loadFont("font.vlw");

  textFont(font, 18);
  noStroke();
}

void draw() {
  background(50);
  board.drawBoard();
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
  textAlign(CENTER);
  text(message, width / 2, height / 2);
}

class Cell {
  int x, y;
  int nMines = 0;
  boolean isMine;
  boolean isRevealed;
  boolean isFlagged = false;
  boolean isUnderMouse;
  boolean isPressed;

  Cell(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void drawCell() {
    isUnderMouse = mouseX > x * CELLSIZE &&
                   mouseX <= (x + 1) * CELLSIZE &&
                   mouseY > y * CELLSIZE &&
                   mouseY <= (y + 1) * CELLSIZE;
    isPressed = isShowingMines ? false : mousePressed && isUnderMouse;

    pushMatrix();
    translate(x * CELLSIZE, y * CELLSIZE);

    if (isRevealed) {
      image(imgRevealed, 0, 0);
      fill(0, 0, 255);
      if (nMines > 0) {
        switch(nMines) {
          case 1:
            fill(0, 0, 255);
            break;
          case 2:
            fill(0, 200, 0);
            break;
          case 3:
            fill(255, 0, 0);
            break;
          case 4:
            fill(0, 0, 150);
            break;
          case 5:
            fill(165, 42, 42);
            break;
          case 6:
            fill(0, 255, 255);
            break;
          case 7:
            fill(0);
            break;
          case 8:
            fill(75);
            break;
        }
        text(nMines, 12, 22);
      }
    } else {
      image(imgNormal, 0, 0);
      if (isFlagged) {
        image(imgFlag, 0, 0);
      }
    }

    if (isShowingMines && isMine) {
      image(imgMine, 0, 0);
    }

    if (isPressed) {
      fill(0, 20);
      rect(0, 0, CELLSIZE, CELLSIZE);
    }

    if (isUnderMouse) {
      fill(255, 50);
      rect(0, 0, CELLSIZE, CELLSIZE);
    }

    popMatrix();
  }
}

class Board {
  Cell[][] cells;
  int boardSize;
  int mineCount;
  boolean gameOver   = false;
  boolean gameWon    = false;
  boolean firstClick = true;

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
      cell = cells[(int)random(boardSize)][(int)random(boardSize)];

      if (cell == clickedCell) {
        continue;
      }

      if (!cell.isMine) {
        cell.isMine = true;
        mines++;
      }
    }

    calculateMines();
  }

  // flag a cell
  void rightClick() {
    Cell clickedCell;
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (cells[row][col].isPressed) {
          clickedCell = cells[row][col];
          clickedCell.isFlagged = !clickedCell.isFlagged;
        }
      }
    }
  }

  // reveal a cell if game isn't over, place mines after first click
  void click() {
    if (!gameOver && !gameWon) {
      Cell clickedCell;
      for (int row = 0; row < boardSize; row++) {
        for (int col = 0; col < boardSize; col++) {
          if (cells[row][col].isPressed) {
            clickedCell = cells[row][col];

            if (firstClick) {
              placeMines(clickedCell);
              firstClick = false;
            }

            revealCell(clickedCell);

            if (won()) {
              isShowingMines = true;
              gameWon = true;
            }

            break;
          }
        }
      }
    } else {
      newGame();
    }
  }

  // returns true if all non-mine cells are revealed
  boolean won() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (!cells[row][col].isRevealed && !cells[row][col].isMine) {
          return false;
        }
      }
    }

    return true;
  }

  // calculate and store mine counts of each cell
  void calculateMines() {
    Cell cell;

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cell = cells[row][col];
        cell.nMines = countMines(neighbors(cell));
      }
    }
  }

  // find adjacent cells with a mine count of zero of a given cell
  ArrayList<Cell> findConnectedZeroes(Cell cell) {
    Cell curCell;
    ArrayList<Cell> zeroes = new ArrayList<Cell>();
    ArrayList<Cell> queue = new ArrayList<Cell>();

    queue.add(cell);

    while (queue.size() != 0) {
      curCell = queue.get(0);
      queue.remove(0);
      zeroes.add(curCell);

      for (Cell neighbor : neighbors(curCell)) {
        if (neighbor.nMines == 0) {
          if (!zeroes.contains(neighbor) && !queue.contains(neighbor)) {
            queue.add(neighbor);
          }
        }
      }
    }

    return zeroes;
  }

  // reveal a cell (and connected zeroes), end game if cell is mine 
  void revealCell(Cell cell) {
    cell.isRevealed = true;

    if (cell.isMine) {
      isShowingMines = true;
      gameOver = true;
    } else {
      if (cell.nMines == 0) {
        for (Cell zero : findConnectedZeroes(cell)) {
          zero.isRevealed = true;
          for (Cell neighbor : neighbors(zero)) {
            neighbor.isRevealed = true;
          }
        }
      }
    }
  }

  // reset the board
  void newGame() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cells[row][col].isRevealed = false;
        cells[row][col].isMine = false;
        cells[row][col].isFlagged = false;
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
      count += cell.isMine ? 1 : 0;
    }

    return count;
  }

  // return an array of the 8 adjacent cells of a given cell
  ArrayList<Cell> neighbors(Cell cell) {
    ArrayList<Cell> result = new ArrayList<Cell>(8);

    for (int[] direction : directions) {
      int dx = cell.x + direction[0];
      int dy = cell.y + direction[1];

      if (dx >= 0 && dx < boardSize) {
        if (dy >= 0 && dy < boardSize) {
          result.add(cells[dy][dx]);
        }
      }
    }

    return result;
  }

  void drawBoard() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        cells[row][col].drawCell();
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
