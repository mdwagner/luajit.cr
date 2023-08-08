class Sprite
  property x : Int32
  property y : Int32

  @[Luajit::Function(name: "new")]
  def self.lua_new(state : Luajit::LuaState) : Int32
    sprite = Sprite.new
    index = state.new_userdata(sprite)
    state.attach_metatable(sprite, index)
    1
  end

  @[Luajit::Function(name: "move")]
  def self.lua_move(state : Luajit::LuaState) : Int32
    sprite = state.to_userdata(Sprite, -3).value
    a = state.to_f(-2)
    b = state.to_f(-1)
    sprite.move(a.to_i, b.to_i)
    0
  end

  @[Luajit::Function(name: "draw")]
  def self.lua_draw(state : Luajit::LuaState) : Int32
    sprite = state.to_userdata(Sprite, -1).value
    sprite.draw
    0
  end

  @[Luajit::Function(name: "props")]
  def self.lua_properties(state : Luajit::LuaState) : Int32
    sprite = state.to_userdata(Sprite, -1).value
    state << {
      "x" => sprite.x,
      "y" => sprite.y,
    }
    1
  end

  def initialize(@x = 0, @y = 0)
  end

  def move(a : Int32, b : Int32)
    self.x += a
    self.y += b
  end

  def draw
    puts "sprite: x = #{x}, y = #{y}"
  end
end
