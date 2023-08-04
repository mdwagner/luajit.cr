module Luajit
  struct LuaState
    alias Alloc = LibLuaJIT::Alloc
    alias CFunction = LibLuaJIT::CFunction
    alias Function = LuaState -> Int32
    alias Loader = LuaState, Pointer(UInt64) -> String?

    class_getter trackables = [] of Pointer(Void)

    @ptr : Pointer(LibLuaJIT::State)

    # Allocates from default LuaJIT allocator
    def self.default : LuaState
      new(LibLuaJIT.luaL_newstate)
    end

    # Allocates from Crystal GC
    def self.new : LuaState
      proc = Alloc.new do |_, ptr, osize, nsize|
        if nsize == 0
          GC.free(ptr)
          Pointer(Void).null
        else
          GC.realloc(ptr, nsize)
        end
      end
      new(LibLuaJIT.lua_newstate(proc, Pointer(Void).null))
    end

    def initialize(@ptr)
    end

    def to_unsafe
      @ptr
    end

    def version? : Float64?
      if ptr = LibLuaJIT.lua_version(self)
        ptr.value
      end
    end

    def version : Float64
      version?.not_nil!
    end

    def open_library(type : LuaLibrary) : Nil
      case type
      in .base?
        LibLuaJIT.luaopen_base(self)
      in .table?
        LibLuaJIT.luaopen_table(self)
      in .io?
        LibLuaJIT.luaopen_io(self)
      in .os?
        LibLuaJIT.luaopen_os(self)
      in .string?
        LibLuaJIT.luaopen_string(self)
      in .math?
        LibLuaJIT.luaopen_math(self)
      in .debug?
        LibLuaJIT.luaopen_debug(self)
      in .package?
        LibLuaJIT.luaopen_package(self)
      in .bit?
        LibLuaJIT.luaopen_bit(self)
      in .ffi?
        LibLuaJIT.luaopen_ffi(self)
      in .jit?
        LibLuaJIT.luaopen_jit(self)
      in .all?
        LibLuaJIT.luaL_openlibs(self)
      end
    end

    def gc(what : LuaGC, data : Int32) : Int32
      case what
      in .stop?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTOP, data)
      in .restart?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCRESTART, data)
      in .collect?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOLLECT, data)
      in .count?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNT, data)
      in .count_bytes?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCCOUNTB, data)
      in .step?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSTEP, data)
      in .set_pause?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETPAUSE, data)
      in .set_step_multiplier?
        LibLuaJIT.lua_gc(self, LibLuaJIT::LUA_GCSETSTEPMUL, data)
      end
    end

    def at_panic(&cb : CFunction) : CFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    def call(num_args : Int32, num_results : Int32) : Nil
      LibLuaJIT.lua_call(self, num_args, num_results)
    end

    def concat(n : Int32) : Nil
      LibLuaJIT.lua_concat(self, n)
    end

    def c_pcall(&block : Function) : Int32
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(-1)
        Box(typeof(block)).unbox(ud).call(state)
      end
      LibLuaJIT.lua_cpcall(self, proc, box)
    end

    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    def pop(n : Int32) : Nil
      LibxLuaJIT.lua_pop(self, n)
    end

    def set_field(index : Int32, k : String) : Nil
      LibLuaJIT.lua_setfield(self, index, k)
    end

    def set_global(name : String) : Nil
      LibxLuaJIT.lua_setglobal(self, name)
    end

    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    def set_table(index : Int32) : Nil
      LibLuaJIT.lua_settable(self, index)
    end

    def get_field(index : Int32, name : String)
      LibLuaJIT.lua_getfield(self, index, name)
    end

    def get_global(name : String)
      LibxLuaJIT.lua_getglobal(self, name)
    end

    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)))
    end

    def to_string(index : Int32) : String
      LibxLuaJIT.lua_tostring(self, index)
    end

    def to_f(index : Int32) : Float64
      LibLuaJIT.lua_tonumber(self, index)
    end

    def to_pointer(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_topointer(self, index)
    end

    def to_userdata(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_touserdata(self, index)
    end

    def to_userdata(_type : U.class, index : Int32) : Pointer(U) forall U
      to_userdata(index).as(Pointer(U))
    end

    # Creates a new userdata from `object` in Lua, adding it to the stack,
    # and tracks it within Crystal to avoid accidental GC
    def new_userdata(object) : Nil
      LuaState.trackables << Box.box(object) # TODO: untrack on finalize?
      LibLuaJIT.lua_newuserdata(self, sizeof(typeof(object))).as(Pointer(typeof(object))).value = object
    end

    def <<(b : Bool) : self
      LibLuaJIT.lua_pushboolean(self, b)
      self
    end

    def <<(n : Int64) : self
      LibLuaJIT.lua_pushinteger(self, n)
      self
    end

    def <<(n : Int32) : self
      self << n.to_i64
    end

    def <<(ptr : Pointer(Void)) : self
      LibLuaJIT.lua_pushlightuserdata(self, ptr)
      self
    end

    def <<(_x : Nil) : self
      LibLuaJIT.lua_pushnil(self)
      self
    end

    def <<(n : Float64) : self
      LibLuaJIT.lua_pushnumber(self, n)
      self
    end

    def <<(str : String) : self
      LibLuaJIT.lua_pushstring(self, str)
      self
    end

    def <<(chr : Char) : self
      self << chr.to_s
    end

    def <<(sym : Symbol) : self
      self << sym.to_s
    end

    def <<(arr : Array) : self
      LibLuaJIT.lua_createtable(self, arr.size, 0)
      arr.each_with_index do |item, index|
        self << index << item
        LibLuaJIT.lua_settable(self, -3)
      end
      self
    end

    def <<(hash : Hash) : self
      LibLuaJIT.lua_createtable(self, 0, hash.size)
      hash.each do |key, value|
        self << key << value
        LibLuaJIT.lua_settable(self, -3)
      end
      self
    end

    def push_function(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      proc = CFunction.new do |l|
        state = LuaState.new(l)
        ud = state.to_userdata(state.upvalue_at(1))
        Box(typeof(block)).unbox(ud).call(state)
      end
      Luajit::POINTERS << box
      self << box
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    def is?(lua_type : LuaType, index : Int32) : Bool
      case lua_type
      in .bool?
        LibxLuaJIT.lua_isboolean(self, index)
      in .number?
        LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
      in .string?
        LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
      in .function?
        LibxLuaJIT.lua_isfunction(self, index)
      in .c_function?
        LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
      in .userdata?
        LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
      in .light_userdata?
        LibxLuaJIT.lua_islightuserdata(self, index)
      in .thread?
        LibxLuaJIT.lua_isthread(self, index)
      in .table?
        LibxLuaJIT.lua_istable(self, index)
      in LuaType::Nil
        LibxLuaJIT.lua_isnil(self, index)
      in .none?
        LibxLuaJIT.lua_isnone(self, index)
      in .none_or_nil?
        LibxLuaJIT.lua_isnoneornil(self, index)
      end
    end

    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_lessthan(self, index1, index2) == true.to_unsafe
    end

    def insert(index : Int32) : Nil
      LibLuaJIT.lua_insert(self, index)
    end

    def remove(index : Int32) : Nil
      LibLuaJIT.lua_remove(self, index)
    end

    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    def eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_equal(self, index1, index2) == true.to_unsafe
    end

    def next(index : Int32) : Bool
      LibLuaJIT.lua_next(self, index) == true.to_unsafe
    end

    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    def raw_geti(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    def raw_seti(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    def upvalue_at(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    def raise_error
      LibLuaJIT.lua_error(self)
    end

    def raise_error(msg : String)
      LibLuaJIT.luaL_error(self, msg)
    end

    def status
      case result = LibLuaJIT.lua_status(self)
      when LibLuaJIT::LUA_OK
        LuaStatus::Ok
      when LibLuaJIT::LUA_YIELD
        LuaStatus::Yield
      else
        LuaStatus.new(result)
      end
    end

    def load(chunk_name : String, &block : Loader) : Int32
      box = Box(typeof(cb)).box(block)
      proc = LibLuaJIT::Reader.new do |l, data, size|
        state = LuaState.new(l)
        Box(typeof(cb)).unbox(data).call(state, size)
      end
      case LibLuaJIT.lua_load(self, proc, box, chunk_name)
      when LibLuaJIT::LUA_ERRSYNTAX
        raise "Lua syntax error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      end
    end

    def execute(code : String) : Nil
      case LibxLuaJIT.luaL_dostring(self, code)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end

    def execute(path : Path) : Nil
      case LibxLuaJIT.luaL_dofile(self, path)
      when LibLuaJIT::LUA_ERRRUN
        raise "Lua runtime error"
      when LibLuaJIT::LUA_ERRMEM
        raise "Lua memory allocation error"
      when LibLuaJIT::LUA_ERRERR
        raise "Error while running error handler function"
      end
    end

    def raise_function_arg(position : Int32, msg : String)
      LibLuaJIT.luaL_argerror(self, position, msg)
    end

    def call_metamethod(object_index : Int32, method_name : String) : Bool
      LibLuaJIT.luaL_callmeta(self, object_index, method_name) == true.to_unsafe
    end
  end
end
