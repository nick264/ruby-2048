class Ruby2048
  attr_accessor :board

  MOVES = {
    up: [false,true,["w","\e[A"]],
    down: [false,false,['s',"\e[B"]],
    left: [true,true,['a',"\e[D"]],
    right: [true,false,['d',"\e[C"]],
  }

  def initialize
    @board = 4.times.map{ 4.times.map{ nil } }
    @board[rand(4)][rand(4)] = 2 while @board.flatten.select{ |x| x == 2 }.size < 2
  end

  def executeMove(move,board=@board)
    collapsedBoard = collapseBoard(move,board)
    if ( board != collapsedBoard ) && hasSpace(collapsedBoard)
      generate(collapsedBoard)
    else
      collapsedBoard
    end
  end

  def check()
    return true if @board.flatten.index(2048)
    return nil if hasSpace()

    # check whether board is collapsable at all
    [ @board, @board.transpose ].each do |board|
      board.each do |row|
        return nil if row[0..-2].zip(row[1..-1]).map{ |x,y| x == y }.any?
      end
    end

    return false
  end

  def collapse(move)
    collapsedBoard = collapseBoard(move,@board)
    if @board.flatten != collapsedBoard.flatten
      @board = collapsedBoard
      true
    else
      false
    end
  end

  def collapseBoard(move,board)
    rowWise = MOVES[move][0]
    direction = MOVES[move][1]

    boardCopy = board.transpose.transpose
    boardCopy = boardCopy.transpose if !rowWise

    (0..3).each do |i|
      row = boardCopy[i]

      row.compact!
      row.reverse! if !direction

      collapsedRow = []
      prev = nil
      row.each do |elem|
        if elem != prev
          collapsedRow << elem
          prev = elem
        else
          collapsedRow = collapsedRow[0..-2] + [ elem * 2 ]
          prev = nil
        end
      end

      row = collapsedRow + (4 - collapsedRow.size).times.map{ nil }

      row.reverse! if !direction

      boardCopy[i] = row
    end

    boardCopy = boardCopy.transpose if !rowWise

    boardCopy
  end

  def generate(board)
    i = nil; j = nil

    while i.nil? || !board[i][j].nil?
      i = rand(4); j = rand(4)
    end

    board[i][j] = 2
    board
  end

  def play!
    runGame() do
      getmove()
    end
  end

  def runGame(&block)
    showBoard()

    while check().nil?
      @board = executeMove(block.call())
      showBoard()
    end

    if check()
      puts "YOU WIN!!!!!"
    else
      puts "GAME OVER, MAN!"
    end
  end

  def playAI!
    runGame() do
      sleep(0.03)
      winningMove(3)[0]
    end
  end

  def winningMove(depth=3,board=@board)
    # Recursively calculates branching possibilities for various moves and random potential board states (i.e. the '2' could appear anywhere)
    # Scores the board state in the terminal node on each path
    # Averages the scores by first move, and picks the move with the highest average

    # POTENTIAL IMPROVEMENTS:
    # 1. can be much faster!  currently takes ~4 minutes to run through a single game
    # 2. should try more random possibilities (currently 4), or even better, enumerate some/all the possibilities to avoid repeats
    # 3. should probably capture the risk better.  e.g. take a move with a worse average sometimes if it has sufficiently lower variance
    # 4. it might be good to boost the value of being on an 'edge' of the board.  or being adjacent to numbers that are similar
    #  i.e. better to be on an e  dge and two moves away than internal and two moves away.  i think?
    #     e.g. - 128 256 512          -  -  256 512               
    #          -  -   -   -    >>     -  -  128  -         
    #                 ......                 ......         


    # returns array:
    # [ WINNING_MOVE, SCORE_OF_BOARD_STATE_AT_TERMINAL_DEPTH ]
    possibilityCount = 4

    scores_by_move = []
    MOVES.each_key do |move|
      newBoard = executeMove(move,board)

      if newBoard == board
        # a move is invalid if it doesn't move the game forward
        # incorporate depth to make sure we choose to move the game forward now even if it's hopeless
        scores_by_move << [ move, -1e10 - depth ] 
      else
        possibilities = [newBoard] + (possibilityCount - 1).times.map{ executeMove(move,board) }
        if depth == 1
          scores_by_move << [ move, possibilities.map{ |b| scoreState(b) }.inject{ |x,y| x + y } / possibilityCount ]
        else
          scores_by_move << [ move, possibilities.map{ |b| winningMove(depth - 1,b)[1] }.inject{ |x,y| x + y } / possibilityCount ]
        end
      end

      # puts "DEPTH=#{depth}"
      # puts move.inspect
      # puts scoreState(newBoard)
      # showBoard(newBoard,false)
    end

    scores_by_move.max_by(&:last)
  end

  def scoreState(board)
    # Score is a function of magnitude of numbers, and also strongly prefers numbers to be close to corners, especially big ones
    corners = [[0,0],[0,3],[3,0],[3,3]]
    scores_by_corner = []

    corners.each do |corner|
      score = 0
      board.each_with_index do |row,i|
        row.each_with_index do |elem,j|
          corner_distance = (i-corner[0]).abs + (j-corner[1]).abs
          # factor of 5: prefer to collapse two numbers rather than leave separated and equidistant from corner
          score += -corner_distance * elem.to_i * 5 
        end
      end

      scores_by_corner << score
    end

    scores_by_corner.max # we don't care which corner we optimize for
  end

  def showBoard(board=@board,clear=true)
    clear() if clear

    board.each do |row|
      row.each do |elem|
        print "#{(elem || '.').to_s.colorize}\t"
      end

      print "\n"
    end

    print "\n\n"
  end

  def clear
    system("cls") || system("clear") || puts("\e[H\e[2J")
  end

  def getmove
    require 'io/console'

    valid_moves = {}

    while valid_moves.empty?
      key = STDIN.getch
      2.times.each{ key += STDIN.getch } if key == "\e"

      ( puts "Exiting..."; exit(0) ) if key == 'q'
      valid_moves = MOVES.select{ |k,v| v[2].include?(key) }
    end
    
    valid_moves.keys[0]
  end

  def hasSpace(board=@board)
    !@board.flatten.select(&:nil?).empty?
  end
end


class String
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def yellow;         "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
  def colorize
    map = {
      '2' => self.green,
      '4' => self.red,
      '8' => self.blue,
      '16' => self.yellow,
      '32' => self.magenta,
      '64' => self.gray,
      '128' => self.cyan,
      '256' => self.green,
      '512' => self.magenta,
      '1024' => self.red,
      '2048' => self.yellow
    }[self] || self
  end
end

if ARGV[0] == 'auto'
  Ruby2048.new.playAI!
else
  Ruby2048.new.play!
end