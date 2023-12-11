require "spec"
require "../src/luajit"

module SpecHelper
  macro assert_stack_size!(state, size)
    {{state}}.size.should eq({{size}})
  end

  class Sprite
    include Luajit::LuaBinding

    property x : Int32

    @[LuaClass(name: "new")]
    def self._new(state : LuaState) : Int32
      _self = new(1000)
      box = Box(Sprite).box(_self)
      state.track(box)
      state.create_userdata(box, Luajit.metatable(SpecHelper::Sprite))
      1
    end

    @[LuaInstance(name: "x")]
    def self._x(state : LuaState) : Int32
      ud_ptr = state.get_userdata(1, Luajit.metatable(SpecHelper::Sprite))
      _self = Box(Sprite).unbox(ud_ptr)
      state.push(_self.x)
      1
    end

    def initialize(@x)
    end
  end

  @[Luajit::Config(global: "Sprite")]
  class Sprite2
    include Luajit::LuaBinding

    property x : Int32

    def_lua self.new do
      _self = new(1000)
      box = Box(Sprite2).box(_self)
      __state.track(box)
      __state.create_userdata(box, Luajit.metatable(SpecHelper::Sprite2))
      1
    end

    def_lua x do
      ud_ptr = __state.get_userdata(1, Luajit.metatable(SpecHelper::Sprite2))
      _self = Box(Sprite2).unbox(ud_ptr)
      __state.push(_self.x)
      1
    end

    def initialize(@x)
    end
  end
end
