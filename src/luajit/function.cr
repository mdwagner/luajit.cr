module Luajit
  class Function
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
