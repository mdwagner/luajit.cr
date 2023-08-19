class Sprite
  property x : Int32
  property y : Int32

  def self.lua_def(l : Luajit::LuaState) : Luajit::Builder
    l.builder
      .global_table("Sprite", attach_meta: true)
      .create_lifecycle(Sprite) { Sprite.new }
      .default_index
      .method("move") do |s|
        s.assert_args_eq(3)
        s.assert_userdata?(1)
        s.assert_number?(2)
        s.assert_number?(3)

        sprite = s.get_userdata(Sprite, 1)
        x = s.to_f(2)
        y = s.to_f(3)
        sprite.move(x.to_i, y.to_i)
        0
      end
      .method("draw") do |s|
        s.assert_args_eq(1)
        s.assert_userdata?(1)

        sprite = s.get_userdata(Sprite, 1)
        sprite.draw
        0
      end
  end

  def initialize(@x = 0, @y = 0)
  end

  def move(x : Int32, y : Int32)
    self.x += x
    self.y += y
  end

  def draw
    puts "sprite(#{object_id}): x = #{x}, y = #{y}"
  end
end
