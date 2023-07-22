module Luajit
  class Coroutine
    include Base

    # :nodoc:
    @ptr : Pointer(LibLuaJIT::State)

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end
  end
end
