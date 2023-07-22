module Luajit
  module Base
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    def pop(n : Int32) : Nil
      LibLuaJIT.lua_pop(self, n)
    end

    def get_field(index : Int32, name : String)
      LibLuaJIT.lua_getfield(self, index, name)
    end

    def get_global(name : String)
      get_field(LibLuaJIT::LUA_GLOBALSINDEX, name)
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
      String.new(LibLuaJIT.lua_tolstring(self, index, nil))
    end

    def to_f(index : Int32) : Float64
      LibLuajit.lua_tonumber(self, index)
    end

    def to_pointer(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_topointer(self, index)
    end

    def to_userdata(index : Int32) : Pointer(Void)
      LibLuaJIT.lua_touserdata(self, index)
    end

    def <<(b : Bool) : self
      LibLuaJIT.lua_pushboolean(self, b)
      self
    end

    def <<(n : Int64) : self
      LibLuaJIT.lua_pushinteger(self, n)
      self
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
      LibLuaJIT.createtable(self, arr.size, 0)
      arr.each_with_index do |item, index|
        self << index << item
        LibLuaJIT.settable(self, -3)
      end
      self
    end

    def <<(hash : Hash) : self
      LibLuaJIT.createtable(self, 0, hash.size)
      hash.each do |key, value|
        self << key << value
        LibLuaJIT.settable(self, -3)
      end
      self
    end

    def is?(lua_type : LuaType, index : Int32) : Bool
      case lua_type
      in .bool?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TBOOLEAN
      in .number?
        LibLuaJIT.lua_isnumber(self, index) == 1
      in .string?
        LibLuaJIT.lua_isstring(self, index) == 1
      in .function?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TFUNCTION
      in .c_function?
        LibLuaJIT.lua_iscfunction(self, index) == 1
      in .userdata?
        LibLuaJIT.lua_isuserdata(self, index) == 1
      in .light_userdata?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TLIGHTUSERDATA
      in .thread?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTHREAD
      in .table?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTABLE
      in LuaType::Nil
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNIL
      in .none?
        LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNONE
      in .none_or_nil?
        LibLuaJIT.lua_type(self, index) <= 0
      end
    end

    def less_than(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_lessthan(self, index1, index2) == 1
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
  end
end
