require "./spec_helper"

class Sprite
  property x : Int32
  property y : Int32

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

describe Luajit do
  it "works" do
    Luajit.run do |state|
      state.execute <<-LUA
      x = { name = "Michael" }
      LUA

      state.get_global("x")
      state.is_table?(-1).should be_true

      state.get_field(-1, "name")
      state.is_string?(-1).should be_true

      name = state.to_string(-1)
      name.should eq("Michael")
    end
  end

  it "works2" do
    Luajit.run do |state|
      table_idx = state.create_global_table("Sprite")
      metatable_idx = state.new_metatable("Sprite")

      state.create_table_function(table_idx, "new") do |s|
        sprite = Sprite.new
        s.create_userdata(sprite, "Sprite")
        1
      end

      state.create_table_function(table_idx, "move") do |s|
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

      state.create_table_function(table_idx, "draw") do |s|
        s.assert_args_eq(1)
        s.assert_userdata?(1)

        sprite = s.get_userdata(Sprite, 1)
        sprite.draw
        0
      end

      state.define_metatable_property(metatable_idx, "__gc") do
        state.push do |s|
          s.assert_args_eq(1)
          s.assert_userdata?(1)

          sprite = s.get_userdata(Sprite, 1)
          s.destroy_userdata(sprite)
          0
        end
      end

      #state.define_metatable_property(metatable_idx, "__index") do
        #state.push_value(table_idx)
      #end

      state.execute <<-LUA
      local sprite = Sprite.new()
      Sprite.move(sprite, 5, 7)
      Sprite.draw(sprite)
      --sprite:move(5, 7) -- TODO
      --sprite:draw()     -- TODO
      LUA
    end
  end

  #it "ex1" do
    #l = Luajit::LuaState.new
    #l.execute <<-LUA
    #function Pythagoras(a, b)
      #return (a * a) + (b * b), a, b
    #end
    #LUA
    #l.get_global("Pythagoras")
    #if l.is?(:function, -1)
      #l << 3 << 4
      #num_args = 2
      #num_returns = 3
      #Luajit::LibLuaJIT.lua_pcall(l, num_args, num_returns, 0)
      #c = l.to_f(-3)
      #puts "c^2 = #{c}"
      #a = l.to_f(-2)
      #puts "a = #{a}"
      #b = l.to_f(-1)
      #puts "b = #{b}"
    #end
  #end

  #it "ex2" do
    #native_pythagoras = Luajit::LibLuaJIT::CFunction.new do |l|
      #state = Luajit::LuaState.new(l)
      #a = state.to_f(-2)
      #b = state.to_f(-1)
      #csqr = (a * a) + (b * b)
      #state << csqr
      #1
    #end

    #l = Luajit::LuaState.new
    #Luajit::LibxLuaJIT.lua_pushcfunction(l, native_pythagoras)
    #l.set_global("NativePythagoras")
    #l.execute <<-LUA
    #function Pythagoras(a, b)
      #csqr = NativePythagoras(a, b)
      #return csqr, a, b
    #end
    #LUA
    #l.get_global("Pythagoras")
    #if l.is?(:function, -1)
      #l << 3 << 4
      #num_args = 2
      #num_returns = 3
      #Luajit::LibLuaJIT.lua_pcall(l, num_args, num_returns, 0)
      #c = l.to_f(-3)
      #puts "c^2 = #{c}"
      #a = l.to_f(-2)
      #puts "a = #{a}"
      #b = l.to_f(-1)
      #puts "b = #{b}"
    #end
  #end

  #it "bind_class example" do
    #Luajit::LuaState.trackables.size.should eq(0)
    #Luajit::LuaState.run do |l|
      #l.tap do |state|
        #Luajit.bind_class(state, Sprite)
      #end

      #begin
        #l.execute <<-LUA
        #local function get_keys(t)
          #local keys={}
          #for key,_ in pairs(t) do
            #table.insert(keys, key)
          #end
          #return keys
        #end
        #for _, v in ipairs(get_keys(Sprite)) do
          #print(v)
        #end

        #sprite = Sprite.new()
        #sprite:move(5, 7)     -- Sprite.move(sprite, 5, 7)
        #sprite:draw()
        #sprite:move(1, 2)
        #sprite:draw()

        #props = sprite:props()
        #for _, v in ipairs(get_keys(props)) do
          #print(v)
        #end
        #print(props.x)
        #print(props.y)

        #local execute = function()
          #sprite2 = Sprite.new()
          #sprite2:move(3, 3)
          #sprite2:draw()
          #sprite2:move(1, 2)
          #sprite2:draw()
        #end
        #execute()
        #LUA
      #rescue
        #if l.is?(:string, -1)
          #puts l.to_string(-1)
        #else
          #puts "failed"
        #end
      #end
      #Luajit::LuaState.trackables.size.should eq(2)
    #end
    #Luajit::LuaState.trackables.size.should eq(0)
  #end
end
