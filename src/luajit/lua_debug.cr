module Luajit
  struct LuaDebug
    @debug : LibLuaJIT::Debug

    enum NameType
      Global
      Local
      Method
      Field
      Upvalue
      None
    end

    enum FunctionType
      Lua  # Lua function
      C    # C function
      Main # main park of a chunk
      Tail # function that did a tail call
    end

    protected def initialize(@debug)
    end

    def to_unsafe
      pointerof(@debug)
    end

    def event : Int32
      @debug.event
    end

    # Returns a reasonable name for the given function, otherwise returns `nil`
    def name : String?
      if found_name = @debug.name
        String.new(found_name)
      end
    end

    # Explains `#name` type according to how the function was called
    def name_type : NameType
      begin
        NameType.parse(String.new(@debug.namewhat || Bytes[]))
      rescue ArgumentError
        NameType::None
      end
    end

    def function_type : FunctionType
      begin
        FunctionType.parse(String.new(@debug.what || Bytes[]))
      rescue ArgumentError
        FunctionType::Tail
      end
    end

    # Returns the source as a String or a filename Path
    def source : String | Path
      src = String.new(@debug.source || Bytes[])
      if src.starts_with?('@')
        Path[src.lchop]
      else
        src
      end
    end

    # Returns the current line where the given function is executing, otherwise returns `nil`
    def current_line : Int32?
      unless @debug.currentline == -1
        @debug.currentline
      end
    end

    # Returns the number of upvalues of the function
    def upvalue_count : Int32
      @debug.nups
    end

    # Returns the line number where the definition of the function starts
    def line_defined : Int32
      @debug.linedefined
    end

    # Returns the line number where the definition of the function ends
    def last_line_defined : Int32
      @debug.lastlinedefined
    end

    def inspect(io : IO) : Nil
      io << String.new(@debug.short_src.to_slice)
    end
  end
end
