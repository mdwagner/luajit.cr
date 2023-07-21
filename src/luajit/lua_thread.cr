module Luajit
  class LuaThread
    getter state : LibLuajit::State*

    def initialize(@state)
    end
  end
end
