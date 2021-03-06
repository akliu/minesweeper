require 'YAML'
#require 'File'

class Tile
  attr_reader :hidden, :flagged

  def initialize(value,hidden = true, flagged = false)
    @value = value
    @hidden = hidden
    @flagged = flagged
  end

  def reveal
    @hidden = false if @hidden == true
  end

  def value
    @value
  end

  def toggle_tile
    @flagged = !@flagged
  end

  def display_value
    if @hidden && @flagged
      "F"
    elsif @hidden
      "_"
    else
      if @value == 9
        "*"
      else
        @value.to_s
      end
    end
  end


end

class Minesweeper
    attr_reader :bomb_limit, :size
  def initialize
    @size
    @bomb_limit
    @board = create_board_size
    seed_bombs(@bomb_limit)
    populate_non_bombs

  end

  def create_board_size
    puts "Select difficulty (E, M, H)"
    settings = ['e', 'm', 'h']
    difficulty = gets.strip.downcase
    until settings.include?(difficulty)
      puts "We did not understand your input."
      puts "Select difficulty (E, M, H)"
      difficulty = gets.strip.downcase
    end
    case difficulty
    when "e"
      @size = 9
      @bomb_limit = 10
    when "m"
      @size = 16
      @bomb_limit = 40
    when "h"
      @size = 20
      @bomb_limit = 80
    end
    Array.new(size) {Array.new(size)}
  end

  def seed_bombs(bomb_limit)
    bomb = 0
    while bomb < bomb_limit
      row = rand(@size-1)
      col = rand(@size-1)
      unless @board[row][col].class == Tile
        @board[row][col] = Tile.new(9)
        bomb += 1
      end
    end
  end

  def populate_non_bombs

    @size.times do |row|
      @size.times do |col|
        if @board[row][col].nil?
          adjacent_coords = get_adjacent_coords([row,col])
          adjacent_bombs = calculate_adjacent_bombs(adjacent_coords)
          @board[row][col] = Tile.new(adjacent_bombs)
        end
      end
    end

  end

  def calculate_adjacent_bombs(coords)
    bomb_count = 0
    coords.each do |pos|
      row,col = pos
      bomb_count += 1 if !@board[row][col].nil? && @board[row][col].value == 9
    end
    bomb_count
  end

  def in_boundary?(pos)
    pos.all? {|coord| (0..(@size -1)).include?(coord) }
  end

  def get_adjacent_coords(pos)
    adjacent_coords = []
    (-1 .. 1).each do |row|
      (-1 .. 1).each do |col|
        adjacent_coords << [(pos[0] + row), (pos[1] + col)] unless row == 0 &&
                                                                    col == 0
      end
    end
    adjacent_coords.select {|pos| in_boundary?(pos)}
  end

  def guess_reveal(pos)
    row,col = pos
    if @board[row][col].value == 9 && !@board[row][col].flagged
      @board[row][col].reveal
    elsif @board[row][col].flagged
      puts "This coordinate is flagged, please unflag first"
      sleep(2)
    else
      recurse_reveal(pos)
    end
  end

  def recurse_reveal(pos)
    row,col = pos
    current_pos  = @board[row][col]
    current_pos.reveal unless current_pos.value == 9 || current_pos.flagged
    if current_pos.value == 0
      get_adjacent_coords(pos).each do |position|
        recurse_reveal(position) if @board[position[0]][position[1]].hidden
      end
    end
  end

  def debug_render
    @board.each do |row|
      p row.map {|tile| tile.value}
    end
  end

  def render
    @board.each do |row|
      p row.map {|tile| " " +  tile.display_value + " "}.join
    end
  end

  def toggle_flag(pos)
    row,col = pos
    curr_pos = @board[row][col]
    curr_pos.toggle_tile if curr_pos.hidden
  end

  def won?
    #@board.flatten.none? {|tile| tile.hidden || tile.value == 9 }
    @board.flatten.none? {|tile| tile.value != 9 ? tile.hidden : !tile.flagged}
    # @board.flatten.none? do |tile|
    #   if tile.value != 9 #tile is not a bomb
    #     tile.hidden #none should be hidden
    #   else #tile is a bomb
    #     !tile.flagged #none should be not flagged
    #   end
    # end
    # @board.flatten.each do |tile|
    #   return false if tile.hidden && tile.value != 9
    # end
    # true
  end

  def lost?
    @board.flatten.any? {|tile| tile.value == 9 && !tile.hidden}
    # @board.flatten.each do |tile|
    #   return true if tile.value == 9 && !tile.hidden
    # end
    # false
  end

  def over?
    won? || lost?
  end
end

class Game
  attr_reader :board
  @@top_ten_score_board = Array.new(3) {Array.new}

  def initialize(board)
    @board = board
    @start_time = 0
  end

  def show_board
    system "clear"
    p elapsed_time
    @board.render
  end

  def display_message
    if board.won?
      puts "You won in #{elapsed_time} seconds"
      p top_score_control
    elsif board.lost?
      puts "You lost!"
    end
  end

  def start_timer
    @start_time = Time.now
  end

  def elapsed_time
    Time.now - @start_time
  end

  def play
    start_timer
    until board.over?
      show_board
      play_turn
    end
    show_board
    display_message
  end



  def top_score_control
    total_time = elapsed_time
    puts "Please enter name"
    name = gets.strip.capitalize
    difficulty = @board.size
    case difficulty
    when difficulty == 9
      @@top_ten_score_board[0].push([total_time => name])
      @@top_ten_score_board[0].sort! {|a,b| a[0] <=> b[0] }
    when difficulty == 16
      @@top_ten_score_board[1].push([total_time => name])
      @@top_ten_score_board[1].sort! {|a,b| a[0] <=> b[0] }
    when difficulty == 20
      @@top_ten_score_board[2].push([total_time => name])
      @@top_ten_score_board[2].sort! {|a,b| a[0] <=> b[0] }

    end
  end


  def play_turn
    #get an input
    row,col,type = get_move
    if type == "s"
      save_game
      Kernel.abort("Goodbye!")
    end

    until @board.in_boundary?([row,col])
      puts "Invalid coordinates, pleases choose again!"
      row,col,type = get_move
    end
    #execute input
    if type == "r"
      @board.guess_reveal([row,col])
    elsif type == "f"
      @board.toggle_flag([row,col])
    end
  end

  def get_move
    puts "Please enter R for reveal or F for flag or S for save game"
    type = gets.chomp.downcase
    until type == "r" ||  type == "f" || type == "s"
      puts "We did not understand your input."
      puts "Please enter R for reveal or F for flag or S for save game"
      type = gets.chomp.downcase
    end
    puts "Please choose a row"
    row = gets.chomp.to_i
    puts "Please choose a col"
    col = gets.chomp.to_i
    [row, col, type]
  end

  def save_game
    puts "Save file name"
    file = gets.chomp
    File.open(file, "w") { |f| f.puts self.to_yaml}
    #Filename(file,self.to_yaml)
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV[0]
    YAML.load_file(ARGV.shift).play
  else
    a = Minesweeper.new
    game = Game.new(a)
    game.play
  end
end
