class Ruby2048

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

  def move(type)
    generate() if collapse(type) && hasSpace()
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

  def collapse(type)
    rowWise = MOVES[type][0]
    direction = MOVES[type][1]

    boardCopy = @board.transpose.transpose
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

    if @board.flatten != boardCopy.flatten
      @board = boardCopy
      true
    else
      false
    end
  end

  def generate
    i = nil; j = nil

    while i.nil? || !@board[i][j].nil?
      i = rand(4); j = rand(4)
    end

    @board[i][j] = 2
  end

  def play!
    runGame() do
      getmove()
    end
  end

  def runGame(&block)
    showBoard()

    while check().nil?
      move(block.call())
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
      # AI logic goes here
      sleep(0.03)
      MOVES.keys.sample
    end
  end

  def showBoard
    clear()

    @board.each do |row|
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

  def hasSpace
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

Ruby2048.new.play!