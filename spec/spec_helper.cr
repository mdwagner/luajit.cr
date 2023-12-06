require "spec"
require "../src/luajit"

module SpecHelper
  macro assert_stack_size!(state, size)
    {{state}}.size.should eq({{size}})
  end

  class Sprite
    property x : Int32

    def initialize(@x)
    end
  end
end
