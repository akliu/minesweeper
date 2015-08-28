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

  def display_value
    if @hidden && @flagged
      "F"
    elsif @hidden
      "|_|"
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

  def initialize(size = 9, bomb_limit = 10)
    @size = size
    @board = Array.new(size) {Array.new(size)}
    seed_bombs(bomb_limit)
    populate_non_bombs
    nil
  end

  def []=(pos, val)
    row,col = pos
    @board[row][col] = val
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
      bomb_count += 1 if !@board[row][col].nil? && @board[row][col].to_s == 9
    end
    bomb_count
  end

  def in_boundary(pos)
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
    adjacent_coords.select {|pos| in_boundary(pos)}
  end

  def guess_reveal(pos)
    row,col = pos
    if @board[row][col].value == 9
      @board[row][col].reveal
    else
      recurse_reveal(pos)
    end
  end

  def recurse_reveal(pos)
    row,col = pos
    current_pos  = @board[row][col]
    current_pos.reveal unless current_pos.value == 9
    if current_pos.value == 0
      get_adjacent_coords(pos).each do |position|
        p position
        p @board[position[0]][position[1]].hidden
        recurse_reveal(position) if @board[position[0]][position[1]].hidden
      end
    end
  end

  def debug_render
    @board.each do |row|
      p row.map {|tile| tile.value}
    end
    nil
  end

  def render
    @board.each do |row|
      p row.map {|tile| tile.display_value}
    end
    nil
  end

  def won?
    @board.flatten.all? do |tile|
      if tile.value == 9
        return true if tile.flagged
      else
        return true if !tile.hidden
      end
      false
    end
  end

  def lost?
    @board.flatten.any? do |tile|
      if tile.value == 9
        return true if !tile.hidden
      end
      false
    end
  end

  def over?
    won? || lost?
  end
end

class Game
  attr_reader :board

  def initialize(board, player)
    @board = board
    @player = player
  end

  def play

    until board.over?
      play_turn
    end

  end

  def play_turn
    #get an input

    #execute input

  end
end
