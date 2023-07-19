module Luajit
  @[Link(ldflags: "`pkg-config --cflags --libs luajit` -lm -ldl")]
  lib LibLuaJIT
    alias Int = LibC::Int
    alias SizeT = LibC::SizeT
    alias Char = LibC::Char
    alias Double = LibC::Double
    alias Long = LibC::Long

    struct Debug
      event : Int
      name, namewhat, what, source : Char*
      currentline, nups, linedefined, lastlinedefined : Int
      short_src : Char[60]
    end

    alias State = Void
    alias CFunction = State* -> Int
    alias Reader = State*, Void*, SizeT* -> Char*
    alias Writer = State*, Void*, SizeT, Void* -> Int
    alias Alloc = Void*, Void*, SizeT, SizeT -> Void*
    alias Number = Double
    alias Integer = Long
    alias Hook = State*, Debug* -> Void

    fun lua_atpanic(l : State*, panicf : CFunction) : CFunction
    fun lua_call(l : State*, nargs : Int, nresults : Int) : Void
    fun lua_checkstack(l : State*, extra : Int) : Int
    fun lua_close(l : State*) : Void
    fun lua_concat(l : State*, n : Int) : Void
    fun lua_cpcall(l : State*, func : CFunction, ud : Void*) : Int
    fun lua_createtable(l : State*, narr : Int, nrec : Int) : Void
    fun lua_dump(l : State*, writer : Writer, data : Void*) : Int
    fun lua_equal(l : State*, index1 : Int, index2 : Int) : Int
    fun lua_error(l : State*) : Int
    fun lua_gc(l : State*, what : Int, data : Int) : Int
    fun lua_getallocf(l : State*, ud : Void**) : Alloc
    fun lua_getfenv(l : State*, index : Int) : Void
    fun lua_getfield(l : State*, index : Int, k : Char*) : Void
    fun lua_getmetatable(l : State*, index : Int) : Int
    fun lua_gettable(l : State*, index : Int) : Void
    fun lua_gettop(l : State*) : Int
    fun lua_insert(l : State*, index : Int) : Void
    fun lua_isboolean(l : State*, index : Int) : Int
    fun lua_iscfunction(l : State*, index : Int) : Int
    fun lua_isfunction(l : State*, index : Int) : Int

    fun lua_newstate(f : Alloc, ud : Void*) : State*
    fun lua_newthread(l : State*) : State*
    fun lua_pcall(l : State*, nargs : Int, nresults : Int, errfunc : Int) : Int
    fun lua_getstack(l : State*, level : Int, ar : Debug*) : Int
    fun lua_getinfo(l : State*, what : Char*, ar : Debug*) : Int
    fun lua_getlocal(l : State*, ar : Debug*, n : Int) : Char*
    fun lua_setlocal(l : State*, ar : Debug*, n : Int) : Char*

    fun luaL_newstate : State*
    fun luaL_openlibs(l : State*) : Void
    fun luaL_loadstring(l : State*, s : Char*) : Int
  end
end
