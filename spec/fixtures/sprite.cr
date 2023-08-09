class Sprite
  property x : Int32
  property y : Int32

  # Sprite.new()
  @[Luajit::Function(name: "new")]
  def self.lua_new(state : Luajit::LuaState) : Int32
    state.assert_nargs_eq(0)

    sprite = new
    index = state.new_userdata(sprite)
    state.attach_metatable(sprite, index)
    1
  end

  # Sprite.move(self, <1:number>, <2:number>)
  @[Luajit::Function(name: "move")]
  def self.lua_move(state : Luajit::LuaState) : Int32
    state.assert_nargs(3)
    state.assert_userdata_type(self, 1)
    state.assert_lua_type(:number, 2)
    state.assert_lua_type(:number, 3)

    sprite = state.to_userdata(self, 1).value
    a = state.to_f(2)
    b = state.to_f(3)
    sprite.move(a.to_i, b.to_i)
    0
  end

  # Sprite.draw(self)
  @[Luajit::Function(name: "draw")]
  def self.lua_draw(state : Luajit::LuaState) : Int32
    state.assert_nargs(1)
    state.assert_userdata_type(self, 1)

    sprite = state.to_userdata(self, 1).value
    sprite.draw
    0
  end

  # Sprite.props(self)
  @[Luajit::Function(name: "props")]
  def self.lua_properties(state : Luajit::LuaState) : Int32
    state.assert_nargs(1)
    state.assert_userdata_type(self, 1)

    sprite = state.to_userdata(self, 1).value
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
    puts "sprite(#{object_id}): x = #{x}, y = #{y}"
  end
end
