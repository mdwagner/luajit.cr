require "./spec_helper"

describe Luajit do
  it "works" do
    l = Luajit::LuaState.new
    l.execute <<-LUA
    x = { name = "Michael" }
    LUA

    l.get_global("x")
    l.is?(:table, -1).should be_true

    l.get_field(-1, "name")
    l.is?(:string, -1).should be_true

    name = l.to_string(-1)
    name.should eq("Michael")
  end

  it "ex1" do
    l = Luajit::LuaState.new
    l.execute <<-LUA
    function Pythagoras(a, b)
      return (a * a) + (b * b), a, b
    end
    LUA
    l.get_global("Pythagoras")
    if l.is?(:function, -1)
      l << 3 << 4
      num_args = 2
      num_returns = 3
      Luajit::LibLuaJIT.lua_pcall(l, num_args, num_returns, 0)
      c = l.to_f(-3)
      puts "c^2 = #{c}"
      a = l.to_f(-2)
      puts "a = #{a}"
      b = l.to_f(-1)
      puts "b = #{b}"
    end
  end

  it "ex2" do
    native_pythagoras = Luajit::LibLuaJIT::CFunction.new do |l|
      state = Luajit::LuaState.new(l)
      a = state.to_f(-2)
      b = state.to_f(-1)
      csqr = (a * a) + (b * b)
      state << csqr
      1
    end

    l = Luajit::LuaState.new
    Luajit::LibxLuaJIT.lua_pushcfunction(l, native_pythagoras)
    l.set_global("NativePythagoras")
    l.execute <<-LUA
    function Pythagoras(a, b)
      csqr = NativePythagoras(a, b)
      return csqr, a, b
    end
    LUA
    l.get_global("Pythagoras")
    if l.is?(:function, -1)
      l << 3 << 4
      num_args = 2
      num_returns = 3
      Luajit::LibLuaJIT.lua_pcall(l, num_args, num_returns, 0)
      c = l.to_f(-3)
      puts "c^2 = #{c}"
      a = l.to_f(-2)
      puts "a = #{a}"
      b = l.to_f(-1)
      puts "b = #{b}"
    end
  end

  it "lua_bind example" do
    l = Luajit::LuaState.new
    l.open_library(:all)
    Luajit.lua_bind(l, Sprite)
    l.execute <<-LUA
    sprite = lua_new()
    lua_get(sprite)
    move(sprite, 10, 6)
    lua_get(sprite)
    move(sprite, 1, 8)
    lua_get(sprite)
    LUA
  end
end
