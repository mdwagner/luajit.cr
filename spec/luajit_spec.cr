require "./spec_helper"

module Luajit
  annotation LuaMethod
  end
end

macro def_lua_method(name, &)
  @[Luajit::LuaMethod]
  def self.{{name.id}}(state : Luajit::LuaState) : Int32
    {{yield}}
  end
end

class Sprite
  property x : Int32
  property y : Int32

  #@[Luajit::LuaMethod]
  #def self.__new(state : Luajit::LuaState) : Int32
    #state.new_userdata(Sprite).value = Sprite.new
    #1
  #end

  def_lua_method __new do
    state.new_userdata(Sprite).value = Sprite.new
    1
  end

  #@[Luajit::LuaMethod]
  #def self.__move(state : Luajit::LuaState) : Int32
    #_self = state.to_userdata(Sprite, -3).value
    #a = state.to_f(-2)
    #b = state.to_f(-1)
    #_self.move(a.to_i, b.to_i)
    #0
  #end

  def_lua_method __move do
    _self = state.to_userdata(Sprite, -3).value
    a = state.to_f(-2)
    b = state.to_f(-1)
    _self.move(a.to_i, b.to_i)
    0
  end

  #@[Luajit::LuaMethod]
  #def self.__get(state : Luajit::LuaState) : Int32
    #_self = state.to_userdata(Sprite, -1).value
    #pp _self
    #0
  #end

  def_lua_method __get do
    _self = state.to_userdata(Sprite, -1).value
    pp _self
    0
  end

  def initialize(@x = 0, @y = 0)
  end

  def move(a : Int32, b : Int32)
    self.x += a
    self.y += b
  end
end

macro lua_bind(lua_state, klass)
  {% begin %}
  {% libx = parse_type("Luajit::LibxLuaJIT").resolve %}
  {% _klass = klass.resolve %}
  {% klass_method_annos = _klass.class.methods.select(&.annotation(Luajit::LuaMethod)) %}
    {% for klass_method in klass_method_annos %}
      {{libx}}.lua_pushcfunction({{lua_state}}, ->(_l : Luajit::LibLuaJIT::State*) : Int32 {
        state = Luajit::LuaState.new(_l)
        {{_klass}}.{{klass_method.name.id}}(state)
      })
      {{lua_state}}.set_global({{klass.stringify + klass_method.name.stringify}})
    {% end %}
  {% end %}
end

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

  it "ex3" do
    {% begin %}
    {% methods = Sprite.methods.reject { |m| m.name == "initialize" } %}
    {% methods = methods.select { |m| m.visibility == :public } %}
    {% move_method = methods.find { |m| m.name == "move" } %}
    #\% puts move_method %}
      {% for arg in move_method.args %}
        #\% puts "name: #{arg.internal_name}"%}
        #\% puts "type?: #{arg.restriction}"%}
      {% end %}
    {% end %}
  end

  it "ex4" do
    l = Luajit::LuaState.new
    l.open_library(:all)
    lua_bind(l, Sprite)
    l.execute <<-LUA
    sprite = Sprite__new()
    Sprite__move(sprite, 10, 6)
    Sprite__get(sprite)
    Sprite__move(sprite, 1, 8)
    Sprite__get(sprite)
    LUA
  end
end
