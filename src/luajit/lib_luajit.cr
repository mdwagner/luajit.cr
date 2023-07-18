module Luajit
  @[Link(ldflags: "`pkg-config --cflags --libs luajit` -lm -ldl")]
  lib LibLuaJIT
    alias Int = LibC::Int
    alias SizeT = LibC::SizeT
    alias Char = LibC::Char
    alias Double = LibC::Double
    alias Long = LibC::Long

    alias State = Void
    alias CFunction = State* -> Int
    alias Reader = State*, Void*, SizeT* -> Char*
    alias Writer = State*, Void*, SizeT, Void* -> Int
    alias Alloc = Void*, Void*, SizeT, SizeT -> Void*
    alias Number = Double
    alias Integer = Long

    struct Debug
      event : Int
      name, namewhat, what, source : Char*
      currentline, nups, linedefined, lastlinedefined : Int
      short_src : Char[60]
    end

    fun lua_newstate(f : Alloc, ud : Void*) : State*
    fun lua_close(l : State*) : Void
    fun lua_newthread(l : State*) : State*
    fun lua_atpanic(l : State*, panicf : CFunction) : CFunction

    fun luaL_newstate : State*
  end
end
