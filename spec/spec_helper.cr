require "spec"
require "../src/luajit"

module SpecHelper
  macro assert_stack_size!(state, size)
    {{state}}.size.should eq({{size}})
  end

  class Sprite
    include Luajit::LuaBinding

    def_class_method "new" do |state|
      _self = new(1000)
      Luajit::LuaBinding.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit::LuaBinding.userdata_value(state, self)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end

  class Sprite2
    include Luajit::LuaBinding

    global_name "Sprite"

    def_class_method "new" do |state|
      _self = new(5000)
      Luajit::LuaBinding.setup_userdata(state, _self, self)
      1
    end

    def_instance_method "x" do |state|
      _self = Luajit::LuaBinding.userdata_value(state, self)
      state.push(_self.x)
      1
    end

    property x : Int32

    def initialize(@x)
    end
  end
end
