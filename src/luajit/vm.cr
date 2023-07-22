#module Luajit
  #class VM
    ## :nodoc:
    #alias State = LibLuajit::State
    ## `Pointer(State) -> Int32`
    #alias CFunction = LibLuajit::CFunction

    #@state : State*

    #def initialize(state : State*? = nil)
      #@state = state || LibLuajit.luaL_newstate
    #end

    #def execute(code : String)
      #result = LibLuajit.luaL_loadstring(@state, code)
      #return pcall(0, true, 0) if result == 0
      #result
    #end

    #def execute(path : Path)
      #result = LibLuajit.luaL_loadfile(@state, path.to_s)
      #return pcall(0, true, 0) if result == 0
      #result
    #end

    #def open_libs : Nil
      #LibLuajit.luaL_openlibs(@state)
    #end

    #def to_unsafe
      #@state
    #end

    ## :nodoc:
    #def finalize
      #LibLuajit.lua_close(@state)
    #end

    #def size : Int32
      #LibLuajit.lua_gettop(@state)
    #end

    #def pop(n : Int32) : Nil
      #LibLuajit.lua_pop(@state, n)
    #end

    #def get_field(index : Int32, name : String)
      #LibLuajit.lua_getfield(@state, index, name)
    #end

    #def get_global(name : String)
      #get_field(LibLuajit::LUA_GLOBALSINDEX, name)
    #end

    #def to_boolean(index : Int32) : Bool
      #LibLuajit.lua_toboolean(@state, index) == true.to_unsafe
    #end

    #def to_c_function(index : Int32) : CFunction
      #LibLuajit.lua_tocfunction(@state, index)
    #end

    #def to_i64(index : Int32) : Int64
      #LibLuajit.lua_tointeger(@state, index)
    #end

    #def to_string(index : Int32, size : UInt64) : String
      #String.new(LibLuajit.lua_tolstring(@state, index, pointerof(size)))
    #end

    #def to_string(index : Int32) : String
      #String.new(LibLuajit.lua_tolstring(@state, index, nil))
    #end

    #def to_f(index : Int32) : Int64
      #LibLuajit.lua_tonumber(@state, index)
    #end

    #def to_pointer?(index : Int32) : Void*?
      #if ptr = LibLuajit.lua_topointer(@state, index)
        #ptr
      #end
    #end

    #def to_pointer(index : Int32) : Void*
      #to_pointer?.not_nil!
    #end

    ## def to_thread?(index : Int32) : LuaThread?
    ## if ptr = LibLuajit.lua_tothread(@state, index)
    ## LuaThread.new(ptr)
    ## end
    ## end

    ## def to_thread(index : Int32) : LuaThread
    ## to_thread?.not_nil!
    ## end

    #def to_userdata?(index : Int32) : Void*?
      #if ptr = LibLuajit.lua_touserdata(@state, index)
        #ptr
      #end
    #end

    #def to_userdata(index : Int32) : Void*
      #to_userdata?.not_nil!
    #end

    #def <<(b : Bool) : self
      #LibLuajit.lua_pushboolean(@state, b)
      #self
    #end

    #def <<(n : Int64) : self
      #LibLuajit.lua_pushinteger(@state, n)
      #self
    #end

    #def <<(ptr : Void*) : self
      #LibLuajit.lua_pushlightuserdata(@state, ptr)
      #self
    #end

    #def <<(_x : Nil) : self
      #LibLuajit.lua_pushnil(@state)
      #self
    #end

    #def <<(n : Float64) : self
      #LibLuajit.lua_pushnumber(@state, n)
      #self
    #end

    #def <<(str : String) : self
      #LibLuajit.lua_pushstring(@state, str)
      #self
    #end

    #def <<(chr : Char) : self
      #self << chr.to_s
      #self
    #end

    #def <<(sym : Symbol) : self
      #self << sym.to_s
      #self
    #end

    ## def <<(thread : LuaThread) : self
    ## if LibLuajit.lua_pushthread(thread.state) == 1
    ## raise "LuaThread should not be main thread"
    ## end
    ## self
    ## end

    #def <<(arr : Array) : self
      #LibLuajit.createtable(@state, arr.size, 0)
      #arr.each_with_index do |item, index|
        #self << index << item
        #LibLuajit.settable(@state, -3)
      #end
      #self
    #end

    #def <<(hash : Hash) : self
      #LibLuajit.createtable(@state, 0, hash.size)
      #hash.each do |key, value|
        #self << key << value
        #LibLuajit.settable(@state, -3)
      #end
      #self
    #end

    #def push_existing(index : Int32) : Nil
      #LibLuajit.lua_pushvalue(@state, index)
    #end

    #def is?(lua_type : LuaType, index : Int32) : Bool
      #case lua_type
      #in .bool?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TBOOLEAN
      #in .number?
        #LibLuajit.lua_isnumber(@state, index) == 1
      #in .string?
        #LibLuajit.lua_isstring(@state, index) == 1
      #in .function?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TFUNCTION
      #in .c_function?
        #LibLuajit.lua_iscfunction(@state, index) == 1
      #in .userdata?
        #LibLuajit.lua_isuserdata(@state, index) == 1
      #in .light_userdata?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TLIGHTUSERDATA
      #in .thread?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TTHREAD
      #in .table?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TTABLE
      #in LuaType::Nil
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TNIL
      #in .none?
        #LibLuajit.lua_type(@state, index) == LibLuajit::LUA_TNONE
      #in .none_or_nil?
        #LibLuajit.lua_type(@state, index) <= 0
      #end
    #end

    #def gc(what : LuaGC, data : Int32) : Int32
      #case what
      #in .stop?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCSTOP, data)
      #in .restart?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCRESTART, data)
      #in .collect?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCCOLLECT, data)
      #in .count?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCCOUNT, data)
      #in .count_bytes?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCCOUNTB, data)
      #in .step?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCSTEP, data)
      #in .set_pause?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCSETPAUSE, data)
      #in .set_step_multiplier?
        #LibLuajit.lua_gc(LibLuajit::LUA_GCSETSTEPMUL, data)
      #end
    #end

    #def less_than(index1 : Int32, index2 : Int32) : Bool
      #LibLuajit.lua_lessthan(@state, index1, index2) == 1
    #end

    #def insert(index : Int32) : Nil
      #LibLuajit.lua_insert(@state, index)
    #end

    #def remove(index : Int32) : Nil
      #LibLuajit.lua_remove(@state, index)
    #end

    #def replace(index : Int32) : Nil
      #LibLuajit.lua_replace(@state, index)
    #end

    #def eq(index1 : Int32, index2 : Int32) : Bool
      #LibLuajit.lua_equal(@state, index1, index2) == true.to_unsafe
    #end

    #def next(index : Int32) : Bool
      #LibLuajit.lua_next(@state, index) == true.to_unsafe
    #end

    #def item_size(index : Int32) : UInt64
      #LibLuajit.lua_objlen(@state, index)
    #end

    #def pcall(num_args : Int32, num_results : Int32 | Bool, err_func_idx : Int32) : Nil
      #err = case num_results
            #in Int32
              #LibLuajit.lua_pcall(@state, num_args, num_results, err_func_idx)
            #in Bool
              #LibLuajit.lua_pcall(@state, num_args, LibLuajit::LUA_MULTRET, err_func_idx)
            #end

      #case err
      #when LibLuajit::LUA_ERRRUN
        #raise "Runtime error"
      #when LibLuajit::LUA_ERRMEM
        #raise "Memory allocation error"
      #when LibLuajit::LUA_ERRERR
        #raise "Error while running err handler function"
      #end
    #end

    #macro upvalueindex(i)
      #(Luajit::LibLuajit::LUA_GLOBALSINDEX - {{ i }})
    #end
  #end
#end
