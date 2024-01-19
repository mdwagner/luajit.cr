module Luajit
  struct LuaState
    alias Function = LuaState -> Int32

    enum ThreadStatus
      Main
      Coroutine
    end

    # :nodoc:
    MT_NAME = "luajit_cr::__LuaState__"

    # :nodoc:
    #
    # Returns the pointer address of *state*
    def self.pointer_address(state : LuaState) : String
      state.to_unsafe.address.to_s
    end

    # :nodoc:
    #
    # Sets the *state* pointer address inside it's own registry
    #
    # Used with `#get_registry_address` for tracking whether a LuaState
    # instance or thread is part of a parent LuaState instance
    #
    # Raises `LuaError`
    def self.set_registry_address(state : LuaState) : Nil
      state.push(pointer_address(state))
      state.set_registry(MT_NAME)
    end

    # Creates a new `LuaState` and attaches a default `#at_panic` handler
    def self.create : LuaState
      state = new(LibLuaJIT.luaL_newstate)
      set_at_panic_handler(state)
      set_registry_address(state)
      state
    end

    # Destroys *state* and gives tracked values back to Crystal
    def self.destroy(state : LuaState) : Nil
      begin
        Trackable.remove(pointer_address(state))
      ensure
        state.close
      end
    end

    getter to_unsafe : Pointer(LibLuaJIT::State)

    def initialize(@to_unsafe)
    end

    # :nodoc:
    #
    # Returns the LuaState pointer address inside the registry
    #
    # Works across the main thread and child threads
    #
    # Raises `LuaError`
    def get_registry_address : String
      get_registry(MT_NAME)
      to_string(-1).tap do
        pop(1)
      end
    end

    # Returns the version number of this core
    def version : Float64
      LibLuaJIT.lua_version(self).value
    end

    # Opens standard Lua library *type*
    def open_library(type : LuaLibrary) : Nil
      {% begin %}
      case type
      {% for t in LuaLibrary.constants.map(&.underscore) %}
        {% if t == "all" %}
        in .all?
          LibLuaJIT.luaL_openlibs(self)
        {% else %}
        in .{{t.id}}?
          LibLuaJIT.luaopen_{{t.id}}(self)
        {% end %}
      {% end %}
      end
      {% end %}
    end

    # Returns `true` if value at the given *index* has type boolean
    def is_bool?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TBOOLEAN
    end

    # Returns `true` if value at the given *index* is a number or a string convertible to a number
    def is_number?(index : Int32) : Bool
      LibLuaJIT.lua_isnumber(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a string or a number (which is always convertible to a string)
    def is_string?(index : Int32) : Bool
      LibLuaJIT.lua_isstring(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a function (either C or Lua)
    def is_function?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TFUNCTION
    end

    # Returns `true` if value at the given *index* is a C function
    def is_c_function?(index : Int32) : Bool
      LibLuaJIT.lua_iscfunction(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a userdata (either full or light)
    def is_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_isuserdata(self, index) == true.to_unsafe
    end

    # Returns `true` if value at the given *index* is a light userdata
    def is_light_userdata?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TLIGHTUSERDATA
    end

    # Returns `true` if value at the given *index* is a thread
    def is_thread?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTHREAD
    end

    # Returns `true` if value at the given *index* is a table
    def is_table?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TTABLE
    end

    # Returns `true` if value at the given *index* is nil
    def is_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNIL
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack)
    def is_none?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) == LibLuaJIT::LUA_TNONE
    end

    # Returns `true` if value at the given *index* is not valid (refers to an element outside the current stack) or is nil
    def is_none_or_nil?(index : Int32) : Bool
      LibLuaJIT.lua_type(self, index) <= 0
    end

    # Returns the type of the value at the given *index*
    def get_type(index : Int32) : LuaType
      LuaType.new(LibLuaJIT.lua_type(self, index))
    end

    # Returns the name of the *lua_type* value
    def type_name(lua_type : LuaType) : String
      String.new(LibLuaJIT.lua_typename(self, lua_type.value) || Bytes[])
    end

    # Returns the name of the type of the value at the given *index*
    def type_name_at(index : Int32) : String
      String.new(LibLuaJIT.lua_typename(self, LibLuaJIT.lua_type(self, index)) || Bytes[])
    end

    # Returns `true` if the two values in indices *index1* and *index2* are equal
    #
    # Follows the semantics of the Lua `==` operator (i.e. may call metamethods)
    #
    # Raises `LuaError` if operation fails
    def eq(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push_fn__eq
      insert(-3)
      pcall(2, 1) do |status|
        raise LuaError.pcall_handler(self, status, "lua_equal")
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Returns `true` if the two values in indices *index1* and *index2* are primitively equal
    #
    # Does not call metamethods
    def raw_eq(index1 : Int32, index2 : Int32) : Bool
      LibLuaJIT.lua_rawequal(self, index1, index2) == true.to_unsafe
    end

    # Returns `true` if the value at *index1* is smaller than the value at *index2*
    #
    # Follows the semantics of the Lua `<` operator (i.e. may call metamethods)
    #
    # Raises `LuaError` if operation fails
    def less_than(index1 : Int32, index2 : Int32) : Bool
      index1 = abs_index(index1)
      index2 = abs_index(index2)
      push_value(index1)
      push_value(index2)
      push_fn__less_than
      insert(-3)
      pcall(2, 1) do |status|
        raise LuaError.pcall_handler(self, status, "lua_lessthan")
      end
      to_boolean(-1).tap do
        pop(1)
      end
    end

    # Converts the Lua value at *index* to `Float64`
    #
    # The value must be a number or a string convertible to a number, otherwise returns 0
    def to_f64(index : Int32) : Float64
      LibLuaJIT.lua_tonumber(self, index)
    end

    # :ditto:
    def to_f(index : Int32) : Float64
      to_f64(index)
    end

    # Same as `#to_f64` but returns a `Float32`
    def to_f32(index : Int32) : Float32
      to_f64(index).to_f32
    end

    # Converts the Lua value at *index* to `Int64`
    #
    # The value must be a number or a string convertible to a number, otherwise returns 0
    #
    # If the number is not an integer, it is truncated in some non-specific way
    def to_i64(index : Int32) : Int64
      LibLuaJIT.lua_tointeger(self, index)
    end

    # Same as `#to_i64` but returns a `Int32`
    def to_i32(index : Int32) : Int32
      to_i64(index).to_i
    end

    # :ditto:
    def to_i(index : Int32) : Int32
      to_i32(index)
    end

    # Converts the Lua value at *index* to `Bool`
    #
    # Returns `true` for any Lua value different than `false` or `nil`
    #
    # Returns `false` when called with a non-valid index
    def to_boolean(index : Int32) : Bool
      LibLuaJIT.lua_toboolean(self, index) == true.to_unsafe
    end

    # Converts the Lua value at *index* to a C string
    #
    # The Lua value must be a string or a number, otherwise returns "".
    #
    # If the value is a number, it also _changes the actual value in the stack
    # to a string_.
    def to_string(index : Int32, size : UInt64) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, pointerof(size)) || Bytes[])
    end

    # :ditto:
    def to_string(index : Int32) : String
      String.new(LibLuaJIT.lua_tolstring(self, index, nil) || Bytes[])
    end

    # Returns the "length" of the value at *index*
    #
    # For strings, this is the string length.
    # For tables, this is the result of the length operator ('#').
    # For userdata, this is the size of the block of memory allocated
    # for the userdata.
    # For other values, it is 0.
    def size_at(index : Int32) : UInt64
      LibLuaJIT.lua_objlen(self, index)
    end

    # Converts a value at *index* to a C function, otherwise returns `nil`
    def to_c_function?(index : Int32) : LuaCFunction?
      proc = LibLuaJIT.lua_tocfunction(self, index)
      if proc.pointer
        proc
      end
    end

    # Same as `#to_c_function?`, but assumes value is not `nil`
    def to_c_function!(index : Int32) : LuaCFunction
      to_c_function?(index).not_nil!
    end

    # If the value at *index* is a full userdata, returns its block address
    #
    # If the value is a light userdata, returns its pointer
    #
    # Otherwise returns `nil`
    def to_userdata?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_touserdata(self, index)
        ptr
      end
    end

    # Same as `#to_userdata?`, but assumes value is not `nil`
    def to_userdata!(index : Int32) : Pointer(Void)
      to_userdata?(index).not_nil!
    end

    # Converts the value at *index* to a Lua thread, otherwise returns `nil`
    def to_thread?(index : Int32) : LuaState?
      if ptr = LibLuaJIT.lua_tothread(self, index)
        LuaState.new(ptr)
      end
    end

    # Same as `#to_thread?`, but assumes value is not `nil`
    def to_thread!(index : Int32) : LuaState
      to_thread?(index).not_nil!
    end

    # Converts the value at *index* to a `Pointer`
    #
    # The value can be a userdata, a table, a thread, or a function; otherwise, returns `nil`.
    #
    # Different objects will give different pointers.
    # There is no way to convert the pointer back to its original value.
    def to_pointer?(index : Int32) : Pointer(Void)?
      if ptr = LibLuaJIT.lua_topointer(self, index)
        ptr
      end
    end

    # Same as `#to_pointer?`, but assumes value is not `nil`
    def to_pointer!(index : Int32) : Pointer(Void)
      to_pointer?(index).not_nil!
    end

    # Returns the index of the top element in the stack
    #
    # Because indices start at 1, this result is equal to the number of
    # elements in the stack (and so 0 means an empty stack).
    def size : Int32
      LibLuaJIT.lua_gettop(self)
    end

    # Accepts any acceptable *index*, or 0, and sets the stack top
    # to this index
    #
    # If the new top is larger than the old one, then the new
    # elements are filled with `nil`.
    #
    # If index is 0, then all stack elements are removed.
    def set_top(index : Int32) : Nil
      LibLuaJIT.lua_settop(self, index)
    end

    # Pops *n* elements from the stack
    def pop(n : Int32) : Nil
      set_top(-(n) - 1)
    end

    # Pushes a copy of the element at *index* onto the stack
    def push_value(index : Int32) : Nil
      LibLuaJIT.lua_pushvalue(self, index)
    end

    # Removes the element at *index*, shifting down elements above to fill gap
    #
    # WARNING: Cannot be called with a pseudo-index, because a pseudo-index
    # is not an actual stack position.
    def remove(index : Int32) : Nil
      LibLuaJIT.lua_remove(self, index)
    end

    # Moves the top element into *index*, shifting elements above to open space
    #
    # WARNING: Cannot be called with a pseudo-index, because a pseudo-index
    # is not an actual stack position.
    def insert(index : Int32) : Nil
      LibLuaJIT.lua_insert(self, index)
    end

    # Moves the top element into the given position (and pops it),
    # without shifting any element (therefore replacing the value
    # at the given position)
    def replace(index : Int32) : Nil
      LibLuaJIT.lua_replace(self, index)
    end

    # Exchange values between different threads of the same global state
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_xmove
    def xmove(from : LuaState, to : LuaState, n : Int32) : Nil
      LibLuaJIT.lua_xmove(from, to, n)
    end

    # Yields a coroutine
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_yield
    def co_yield(nresults : Int32) : Int32
      LibLuaJIT.lua_yield(self, nresults)
    end

    # Starts and resumes a coroutine in a given thread
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_resume
    def co_resume(narg : Int32) : Int32
      LibLuaJIT.lua_resume(self, narg)
    end

    # Returns the status of `self`
    def status : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_status(self))
    end

    # Get information about the interpreter runtime stack
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_getstack
    def get_stack(level : Int32) : LuaDebug?
      if LibLuaJIT.lua_getstack(self, level, out ar) == true.to_unsafe
        ar
      end
    end

    # Returns information about a specific function or function invocation
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_getinfo
    def get_info(what : String, ar : LuaDebug) : LuaDebug?
      if LibLuaJIT.lua_getinfo(self, what, pointerof(ar)) != 0
        ar
      end
    end

    # Gets information about a local variable of *ar*
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_getlocal
    def get_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_getlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # Sets the value of a local variable of *ar*
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_setlocal
    def set_local(ar : LuaDebug, n : Int32 = 1) : String?
      if ptr = LibLuaJIT.lua_setlocal(self, pointerof(ar), n)
        String.new(ptr)
      end
    end

    # Gets information about a closure's upvalue
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_getupvalue
    def get_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_getupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Produces upvalue indices
    def upvalue(index : Int32) : Int32
      LibLuaJIT::LUA_GLOBALSINDEX - index
    end

    # Sets the value of a closure's upvalue
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_setupvalue
    def set_upvalue(fn_index : Int32, n : Int32) : String?
      if ptr = LibLuaJIT.lua_setupvalue(self, fn_index, n)
        String.new(ptr)
      end
    end

    # Sets the debugging hook function
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_sethook
    def set_hook(f : LuaHook, mask : Int32, count : Int32) : Nil
      LibLuaJIT.lua_sethook(self, f, mask, count)
    end

    # Returns the current hook function
    def get_hook : LuaHook
      LibLuaJIT.lua_gethook(self)
    end

    # Returns the current hook mask
    def get_hook_mask : Int32
      LibLuaJIT.lua_gethookmask(self)
    end

    # Returns the current hook count
    def get_hook_count : Int32
      LibLuaJIT.lua_gethookcount(self)
    end

    # :nodoc:
    #
    # TODO: debugging
    def print_stack(uniq_value : String? = nil) : Nil
      puts "####{uniq_value || ""}"
      total = size
      if total == 0
        puts "# [0]"
      else
        count = -1
        total.downto(1) do |index|
          puts "# (#{count}) [#{index}]: #{get_type(index)}"
          count -= 1
        end
      end
      puts "###"
      puts
    end

    # Returns `LuaGC` wrapper
    def gc : LuaGC
      LuaGC.new(self)
    end

    # Pushes onto the stack the value t[k], where t is the value at *index*,
    # and k is the value at the top of the stack
    #
    # Pops the key from the stack (putting the resulting value in its place).
    #
    # As in Lua, this function may trigger a metamethod for the "index" event
    #
    # Raises `LuaError` if operation fails
    def get_table(index : Int32) : Nil
      push_value(index)
      insert(-2)
      push_fn__get_table
      insert(-3)
      pcall(2, 1) do |status|
        raise LuaError.pcall_handler(self, status, "lua_gettable")
      end
    end

    # Pushes onto the stack the value t[k], where t is the value at *index*,
    # and k is the *name* of the field
    #
    # As in Lua, this function may trigger a metamethod for the "index" event.
    #
    # Raises `LuaError` if operation fails
    def get_field(index : Int32, name : String) : Nil
      return get_global(name) if index == LibLuaJIT::LUA_GLOBALSINDEX
      return get_registry(name) if index == LibLuaJIT::LUA_REGISTRYINDEX
      return get_environment(name) if index == LibLuaJIT::LUA_ENVIRONINDEX

      push_value(index)
      push_fn__get_field
      insert(-2)
      push(name)
      pcall(2, 1) do |status|
        raise LuaError.pcall_handler(self, status, "lua_getfield")
      end
    end

    # Pushes onto the stack the value of the global *name*
    #
    # Raises `LuaError` if operation fails
    def get_global(name : String) : Nil
      push_fn__get_global
      push(name)
      pcall(1, 1) do |status|
        raise LuaError.default_handler(self, status)
      end
    end

    # Pushes onto the stack the value of the registry *name*
    #
    # Raises `LuaError` if operation fails
    def get_registry(name : String) : Nil
      push_fn__get_registry
      push(name)
      pcall(1, 1) do |status|
        raise LuaError.default_handler(self, status)
      end
    end

    # Pushes onto the stack the metatable associated with *tname*
    # in the registry
    #
    # Raises `LuaError` if operation fails
    #
    # See `#new_metatable`
    def get_metatable(tname : String) : Nil
      begin
        get_registry(tname)
      rescue err : LuaError
        raise LuaError.new("Failed to get metatable", err)
      end
    end

    # Pushes onto the stack the value of the environment *name*
    #
    # Raises `LuaError` if operation fails
    def get_environment(name : String) : Nil
      push_fn__get_environment
      push(name)
      pcall(1, 1) do |status|
        raise LuaError.default_handler(self, status)
      end
    end

    # Similar to `#get_table`, but does a raw access (i.e., without metamethods)
    def raw_get(index : Int32) : Nil
      LibLuaJIT.lua_rawget(self, index)
    end

    # Pushes onto the stack the value t[n], where t is the value at *index*,
    # and *n* is an array-like index
    #
    # The access is raw; that is, it does not invoke metamethods.
    def raw_get_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawgeti(self, index, n)
    end

    # Creates a new empty table and pushes it onto the stack
    #
    # *narr* represents pre-allocated array elements
    #
    # *nrec* represents pre-allocated non-array elements
    #
    # Pre-allocation is useful when you know exactly how many elements
    # the table will have.
    def create_table(narr : Int32, nrec : Int32) : Nil
      LibLuaJIT.lua_createtable(self, narr, nrec)
    end

    # Creates a new empty table and pushes it onto the stack
    def new_table : Nil
      create_table(0, 0)
    end

    # Allocates a new block of memory with the given *size*,
    # pushes onto the stack a new full userdata with the block address,
    # and returns this address.
    #
    # Userdata represent C values in Lua.
    # A full userdata represents a block of memory.
    # It is an object (like a table): you must create it,
    # it can have its own metatable, and you can detect when
    # it is being collected.
    # A full userdata is only equal to itself (under raw equality).
    #
    # When Lua collects a full userdata with a gc metamethod, Lua calls the
    # metamethod and marks the userdata as finalized. When this userdata
    # is collected again then Lua frees its corresponding memory.
    def new_userdata(size : UInt64) : Pointer(Void)
      LibLuaJIT.lua_newuserdata(self, size)
    end

    # :ditto:
    def new_userdata(size : Int32) : Pointer(Void)
      new_userdata(size.to_u64)
    end

    # Creates a full userdata with a type *tname*, and returns
    # a pointer with the address of *ptr*
    #
    # See `#get_userdata`
    def create_userdata(ptr : Pointer(Void), tname : String) : Pointer(UInt64)
      new_userdata(sizeof(UInt64)).as(Pointer(UInt64)).tap do |ud_ptr|
        ud_ptr.value = ptr.address
        attach_metatable(-1, tname)
      end
    end

    # Pushes onto the stack the metatable of the value at *index*
    #
    # If *index* is not valid, or value does not have a metatable,
    # returns `false`.
    def get_metatable(index : Int32) : Bool
      LibLuaJIT.lua_getmetatable(self, index) != 0
    end

    # Pushes onto the stack the environment table of the value at *index*
    def get_fenv(index : Int32) : Nil
      LibLuaJIT.lua_getfenv(self, index)
    end

    # Calls a function in protected mode
    #
    # https://www.lua.org/manual/5.1/manual.html#lua_pcall
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0) : LuaStatus
      pcall(nargs, nresults, errfunc) { }
    end

    # Same as `#pcall`, but yields `LuaStatus` on failure
    def pcall(nargs : Int32, nresults : Int32, errfunc : Int32 = 0, & : LuaStatus ->) : LuaStatus
      LuaStatus.new(LibLuaJIT.lua_pcall(self, nargs, nresults, errfunc)).tap do |status|
        unless status.ok?
          yield status
        end
      end
    end

    # Calls the C function *block* in protected mode
    #
    # All values returned by *block* are discarded.
    #
    # NOTE: Adopted from Lua 5.3, because LuaJIT's version has some
    # inconsistencies when dealing with error handling that made it
    # hard to work with.
    def c_pcall(&block : Function) : LuaStatus
      push(block)
      pcall(0, 0)
    end

    # Loads and runs the given *str*
    def execute(str : String) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadstring(self, str))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
    end

    # Loads and runs the given *str*
    #
    # Raises `LuaError` if operation fails
    def execute!(str : String) : Nil
      status = execute(str)
      raise LuaError.default_handler(self, status) unless status.ok?
    end

    # Loads and runs the given *path*
    def execute(path : Path) : LuaStatus
      status = LuaStatus.new(LibLuaJIT.luaL_loadfile(self, path.to_s))
      return pcall(0, LibLuaJIT::LUA_MULTRET) if status.ok?
      status
    end

    # Loads and runs the given *path*
    #
    # Raises `LuaError` if operation fails
    def execute!(path : Path) : Nil
      status = execute(path)
      raise LuaError.default_handler(self, status) unless status.ok?
    end

    # Pops a key from the stack, and pushes a key-value pair from the
    # table at *index* (the "next" pair after the given key).
    #
    # If there are no more elements in the table, then returns `false` (and pushes nothing).
    #
    # While traversing a table, do not call `#to_string` directly on a key,
    # unless you know that the key is actually a string. Recall that
    # `#to_string` changes the value at the given index; this confuses
    # the next call to `#next`.
    #
    # Raises `LuaError` if operation fails
    #
    # A typical traversal looks like this:
    # ```
    # # table is in the stack at index 't'
    # state.push(nil)
    # while state.next(t)
    #   # uses 'key' (at index -2) and 'value' (at index -1)
    #   puts "#{state.type_name_at(-2)} - #{state.type_name_at(-1)}"
    #   # removes 'value'; keeps 'key' for next iteration
    #   state.pop(1)
    # end
    # ```
    def next(index : Int32) : Bool
      push_value(index)
      insert(-2)
      push_fn__next
      insert(-3)
      pcall(2, 3) do |status|
        raise LuaError.pcall_handler(self, status, "lua_next")
      end
      to_boolean(-1).tap do |result|
        pop(1)
        pop(2) unless result
      end
    end

    # Concatenates the *n* values at the top of the stack, pops them,
    # and leaves the result at the top
    #
    # If *n* == 1, does nothing
    #
    # If *n* == 0, pushes empty string
    #
    # Raises `LuaError` if operation fails
    def concat(n : Int32) : Nil
      push("") if n < 1
      return if n < 2
      push_fn__concat
      insert(-(n) - 1)
      pcall(n, 1) do |status|
        raise LuaError.pcall_handler(self, status, "lua_concat")
      end
    end

    # Pushes a `nil` value onto the stack
    def push(_x : Nil) : Nil
      LibLuaJIT.lua_pushnil(self)
    end

    # Pushes a `Float64` onto the stack
    def push(x : Float64) : Nil
      LibLuaJIT.lua_pushnumber(self, x)
    end

    # Pushes a `Float32` converted to a `Float64` onto the stack
    def push(x : Float32) : Nil
      push(x.to_f64)
    end

    # Pushes an `Int64` onto the stack
    def push(x : Int64) : Nil
      LibLuaJIT.lua_pushinteger(self, x)
    end

    # Pushes an `Int32` converted to an `Int64` onto the stack
    def push(x : Int32) : Nil
      push(x.to_i64)
    end

    # Pushes a `String` onto the stack
    def push(x : String) : Nil
      LibLuaJIT.lua_pushstring(self, x)
    end

    # Pushes a `Char` converted to a `String` onto the stack
    def push(x : Char) : Nil
      push(x.to_s)
    end

    # Pushes a `Symbol` converted to a `String` onto the stack
    def push(x : Symbol) : Nil
      push(x.to_s)
    end

    # Pushes a C function onto the stack
    def push(x : LuaCFunction) : Nil
      LibLuaJIT.lua_pushcclosure(self, x, 0)
    end

    # Pushes a C closure onto the stack
    def push(x : Function) : Nil
      push_fn_closure do |state|
        x.call(state)
      end
    end

    # Pushes a boolean onto the stack
    def push(x : Bool) : Nil
      LibLuaJIT.lua_pushboolean(self, x)
    end

    # Pushes a light userdata onto the stack
    #
    # A light userdata is equivalent to a `Pointer`
    def push(x : Pointer(Void)) : Nil
      LibLuaJIT.lua_pushlightuserdata(self, x)
    end

    def push(x : Array) : Nil
      create_table(x.size, 0)
      x.each_with_index do |item, index|
        push(index + 1)
        push(item)
        set_table(-3)
      end
    end

    def push(x : Hash) : Nil
      create_table(0, x.size)
      x.each do |key, value|
        push(key)
        push(value)
        set_table(-3)
      end
    end

    # Pushes a C function onto the stack
    def push_fn(&block : LuaCFunction) : Nil
      push(block)
    end

    # Pushes a C closure onto the stack
    def push_fn_closure(&block : Function) : Nil
      box = Box(typeof(block)).box(block)
      track(box)
      proc = LuaCFunction.new do |l|
        state = LuaState.new(l)
        begin
          Box(typeof(block)).unbox(state.to_userdata!(state.upvalue(1))).call(state)
        rescue err
          LibLuaJIT.luaL_error(state, err.inspect)
        end
      end
      push(box)
      LibLuaJIT.lua_pushcclosure(self, proc, 1)
    end

    # Pushes thread represented by *x* onto the stack, returns `ThreadStatus`
    def push_thread(x : LuaState) : ThreadStatus
      if LibLuaJIT.lua_pushthread(x) == 1
        ThreadStatus::Main
      else
        ThreadStatus::Coroutine
      end
    end

    # Does the equivalent to t[k] = v, where t is the value at *index*,
    # v is the value at top of stack, and k the value just behind v
    #
    # Pops both key and value from the stack.
    #
    # Raises `LuaError` if operation fails
    def set_table(index : Int32) : Nil
      push_value(index)
      insert(-3)
      push_fn__set_table
      insert(-4)
      pcall(3, 0) do |status|
        raise LuaError.pcall_handler(self, status, "lua_settable")
      end
    end

    # Does the equivalent to t[k] = v, where t is the value at *index*,
    # *k* is the key, and v is the value at top of stack.
    #
    # Pops the value from the stack.
    #
    # Raises `LuaError` if operation fails
    def set_field(index : Int32, k : String) : Nil
      return set_global(k) if index == LibLuaJIT::LUA_GLOBALSINDEX
      return set_registry(k) if index == LibLuaJIT::LUA_REGISTRYINDEX
      return set_environment(k) if index == LibLuaJIT::LUA_ENVIRONINDEX

      push_value(index)
      insert(-2)
      push_fn__set_field
      insert(-3)
      push(k)
      pcall(3, 0) do |status|
        raise LuaError.pcall_handler(self, status, "lua_setfield")
      end
    end

    # Pops a value from the stack and sets it as the new value of global *name*
    #
    # Raises `LuaError` if operation fails
    def set_global(name : String) : Nil
      push_fn__set_global
      insert(-2)
      push(name)
      pcall(2, 0) do |status|
        raise LuaError.pcall_handler(self, status, "lua_setglobal")
      end
    end

    # Pops a value from the stack and sets it as the new value of registry *name*
    #
    # Raises `LuaError` if operation fails
    def set_registry(name : String) : Nil
      push_fn__set_registry
      insert(-2)
      push(name)
      pcall(2, 0) do |status|
        raise LuaError.default_handler(self, status)
      end
    end

    # Pops a value from the stack and sets it as the new value of environment *name*
    #
    # Raises `LuaError` if operation fails
    def set_environment(name : String) : Nil
      push_fn__set_environment
      insert(-2)
      push(name)
      pcall(2, 0) do |status|
        raise LuaError.default_handler(self, status)
      end
    end

    # Registers a global function
    #
    # Raises `LuaError` if operation fails
    def register_fn_global(name : String, &block : Function) : Nil
      push(block)
      begin
        set_global(name)
      rescue err : LuaError
        raise LuaError.new("Failed to register global function", err)
      end
    end

    # Registers a named function to table at the top of the stack
    #
    # Raises `LuaError` if operation fails
    def register_fn(name : String, &block : Function) : Nil
      assert_table!(-1)
      push(name)
      push(block)
      begin
        set_table(-3)
      rescue err : LuaError
        raise LuaError.new("Failed to register function", err)
      end
    end

    # Opens a library with *name* and registers all functions in *regs*
    def register(name : String, regs = [] of LuaReg) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, name, libs)
    end

    # Registers all functions in *regs* to table at the top of the stack
    def register(regs : Array(LuaReg)) : Nil
      libs = [] of LibLuaJIT::Reg
      regs.each do |reg|
        libs << LibLuaJIT::Reg.new(name: reg.name, func: reg.function.pointer)
      end
      libs << LibLuaJIT::Reg.new(name: Pointer(UInt8).null, func: Pointer(Void).null)
      LibLuaJIT.luaL_register(self, Pointer(UInt8).null, libs)
    end

    # Similar to `#set_table`, but does a raw assignment (i.e., without metamethods)
    def raw_set(index : Int32) : Nil
      LibLuaJIT.lua_rawset(self, index)
    end

    # Does the equivalent of t[n] = v, where t is the value at *index*,
    # v is the value at the top of the stack, and *n* is an array-like index
    #
    # Pops the value from the stack.
    #
    # The assignment is raw; that is, it does not invoke metamethods.
    def raw_set_index(index : Int32, n : Int32) : Nil
      LibLuaJIT.lua_rawseti(self, index, n)
    end

    # Pops a table from the stack and sets it as the new metatable for the
    # value at *index*
    def set_metatable(index : Int32) : Int32
      LibLuaJIT.lua_setmetatable(self, index)
    end

    # Pops a table from the stack and sets it as the new environment
    # for the value at *index*
    #
    # If the value at *index* is neither a function, nor a thread,
    # nor a userdata, returns 0. Otherwise returns 1.
    def set_fenv(index : Int32) : Int32
      LibLuaJIT.lua_setfenv(self, index)
    end

    # Creates a new table to be used as a metatable for userdata,
    # adds it to the registry with key *tname*, and returns `true`
    #
    # If the registry already has the key *tname*, returns `false`.
    #
    # In both cases pushes onto the stack the final value associated
    # with *tname* in the registry.
    def new_metatable(tname : String) : Bool
      LibLuaJIT.luaL_newmetatable(self, tname) != 0
    end

    # Pushes onto the stack the field *e* from the metatable of the
    # object at index *obj*
    #
    # If the object does not have a metatable, or if the metatable does not
    # have this field, returns `false` and pushes nothing.
    def get_metafield(obj : Int32, e : String) : Bool
      LibLuaJIT.luaL_getmetafield(self, obj, e) != 0
    end

    # Calls a metamethod
    #
    # If object at index *obj* has a metatable with field *event*, this
    # method calls this field and passes the object as its only argument.
    # In this case, returns `true` and pushes onto the stack the value
    # returned by the call. Otherwise, returns `false` and pushes nothing
    # onto the stack.
    def call_metamethod(obj : Int32, event : String) : Bool
      obj = abs_index(obj)
      if get_metafield(obj, event)
        push_value(obj)
        pcall(1, 1)
        true
      else
        false
      end
    end

    # Converts *index* into an equivalent absolute index
    def abs_index(index : Int32) : Int32
      if index > 0 || is_pseudo?(index)
        index
      else
        size + index + 1
      end
    end

    # Returns `true` if *index* is a pseudo-index
    def is_pseudo?(index : Int32) : Bool
      index <= LibLuaJIT::LUA_REGISTRYINDEX
    end

    # Destroys all objects and frees all dynamic memory
    def close : Nil
      LibLuaJIT.lua_close(self)
    end

    # Creates a new thread, represented as a new `LuaState`, and pushes it
    # onto the stack
    #
    # Shares all global objects (such as tables), but has independent stack.
    def new_thread : LuaState
      LuaState.new(LibLuaJIT.lua_newthread(self))
    end

    # https://www.lua.org/manual/5.1/manual.html#lua_atpanic
    def at_panic(cb : LuaCFunction) : LuaCFunction
      LibLuaJIT.lua_atpanic(self, cb)
    end

    # :ditto:
    def at_panic(&block : LuaCFunction) : LuaCFunction
      at_panic(block)
    end

    # Raises `LuaError` at *pos* with *reason*
    def raise_arg_error!(pos : Int32, reason : String) : NoReturn
      raise LuaError.new("bad argument ##{pos} (#{reason})")
    end

    # Raises `LuaError` at *pos* with expected *type*
    def raise_type_error!(pos : Int32, type : String) : NoReturn
      raise_arg_error!(pos, "'#{type}' expected, got '#{type_name_at(pos)}'")
    end

    # Raises `LuaError` unless there is a value at *index*
    def assert_any!(index : Int32) : Nil
      if is_none?(index)
        raise_arg_error!(index, "value expected")
      end
    end

    # Raises `LuaError` unless the value at *index* is a string with *size*
    def assert_string!(index : Int32, size : UInt64) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, pointerof(size))
        raise_type_error!(index, type_name(:string))
      end
    end

    # Raises `LuaError` unless the value at *index* is a string
    def assert_string!(index : Int32) : Nil
      unless LibLuaJIT.lua_tolstring(self, index, nil)
        raise_type_error!(index, type_name(:string))
      end
    end

    # Raises `LuaError` unless the value at *index* is a number
    def assert_number!(index : Int32) : Nil
      if to_f64(index) == 0 && !is_number?(index) # avoid extra test when not 0
        raise_type_error!(index, type_name(:number))
      end
    end

    # :ditto:
    def assert_integer!(index : Int32) : Nil
      assert_number!(index)
    end

    # Raises `LuaError` unless the value at *index* is *type*
    def assert_type!(index : Int32, type : LuaType) : Nil
      unless get_type(index) == type
        raise_type_error!(index, type_name(type))
      end
    end

    # Raises `LuaError` unless the value at *index* is nil
    def assert_nil!(index : Int32) : Nil
      assert_type!(index, :nil)
    end

    # Raises `LuaError` unless the value at *index* is a boolean
    def assert_bool!(index : Int32) : Nil
      assert_type!(index, :boolean)
    end

    # Raises `LuaError` unless the value at *index* is a light userdata
    def assert_light_userdata!(index : Int32) : Nil
      assert_type!(index, :light_userdata)
    end

    # Raises `LuaError` unless the value at *index* is a table
    def assert_table!(index : Int32) : Nil
      assert_type!(index, :table)
    end

    # Raises `LuaError` unless the value at *index* is a function
    def assert_function!(index : Int32) : Nil
      assert_type!(index, :function)
    end

    # Raises `LuaError` unless the value at *index* is a thread
    def assert_thread!(index : Int32) : Nil
      assert_type!(index, :thread)
    end

    # Raises `LuaError` unless the value at *index* is userdata
    def assert_userdata!(index : Int32) : Nil
      assert_type!(index, :userdata)
    end

    # Checks whether the value at *index* is a userdata of type *tname*
    # and returns it
    #
    # Raises `LuaError` unless *tname* matches
    def check_userdata!(index : Int32, tname : String) : Pointer(Void)
      if ptr = to_userdata?(index) # value is a userdata?
        if get_metatable(index)    # does it have a metatable?
          get_metatable(tname)     # get correct metatable
          if raw_eq(-1, -2)        # does it have correct mt?
            pop(2)                 # remove both metatables
            return ptr
          end
        end
      end
      raise_type_error!(index, tname) # else error
    end

    # Attaches a metatable to value at *index* with name *tname* if
    # a metatable exists, otherwise returns `false`
    #
    # Raises `LuaError` if operation fails
    def attach_metatable(index : Int32, tname : String) : Bool
      begin
        index = abs_index(index)
        get_metatable(tname)
        if is_table?(-1)
          set_metatable(index)
          true
        else
          pop(1)
          false
        end
      rescue err : LuaError
        raise LuaError.new("Failed to attach metatable", err)
      end
    end

    # Retrieves a full userdata at *index* with name *tname* and returns it
    #
    # NOTE: Can only be used if the userdata was originally created from
    # `#create_userdata`.
    #
    # Raises `LuaError` if operation fails
    def get_userdata(index : Int32, tname : String) : Pointer(Void)
      begin
        ud_ptr = check_userdata!(index, tname).as(Pointer(UInt64))
        Pointer(Void).new(ud_ptr.value)
      rescue err : LuaError
        raise LuaError.new("Failed to get userdata", err)
      end
    end

    # https://www.lua.org/manual/5.1/manual.html#luaL_ref
    def ref(index : Int32) : Int32
      LibLuaJIT.luaL_ref(self, index)
    end

    # https://www.lua.org/manual/5.1/manual.html#luaL_unref
    def unref(index : Int32, ref : Int32) : Nil
      LibLuaJIT.luaL_unref(self, index, ref)
    end

    # Creates a `LuaRef` for object at top of stack
    #
    # Raises `LuaError` if value at top of stack is `nil`
    #
    # Raises `LuaError` if ref cannot be created
    def create_ref : LuaRef
      type = get_type(-1)
      ref_id = ref(LibLuaJIT::LUA_REGISTRYINDEX)
      case ref_id
      when LibLuaJIT::LUA_REFNIL
        raise LuaError.new("value at top of stack was 'nil'")
      when LibLuaJIT::LUA_NOREF
        raise LuaError.new("ref cannot be created")
      end
      LuaRef.new(ref_id, type)
    end

    # Releases *r* so that it can be collected
    def remove_ref(r : LuaRef) : Nil
      unref(LibLuaJIT::LUA_REGISTRYINDEX, r.ref)
    end

    # Same as `#remove_ref`, but only if *any* is a `LuaRef`
    def remove_ref(any : LuaAny) : Nil
      if r = any.as_ref?
        remove_ref(r)
      end
    end

    # Releases any `LuaRef` inside *hash*
    def remove_refs(hash : Hash(String | Float64, LuaAny)) : Nil
      hash.values.each do |any|
        remove_ref(any)
      end
    end

    # Retrieves ref value for *r*
    def get_ref_value(r : LuaRef) : Nil
      raw_get_index(LibLuaJIT::LUA_REGISTRYINDEX, r.ref)
    end

    # Convert *r* value to `Hash`
    def ref_to_h(r : LuaRef) : Hash(String | Float64, LuaAny)
      get_ref_value(r)
      to_h(-1)
    end

    # Add pointer to be tracked by Crystal
    def track(ptr : Pointer(Void)) : Nil
      Trackable.track(get_registry_address, ptr)
    end

    # Remove pointer tracked by Crystal
    def untrack(ptr : Pointer(Void)) : Nil
      Trackable.untrack(get_registry_address, ptr)
    end

    # Converts value at *index* to `LuaAny`, otherwise returns `nil`
    def to_any?(index : Int32) : LuaAny?
      case type = get_type(index)
      when .number?
        LuaAny.new(to_f(index))
      when .boolean?
        LuaAny.new(to_boolean(index))
      when .string?
        LuaAny.new(to_string(index))
      when .light_userdata?, .function?, .userdata?, .thread?, .table?
        push_value(index)
        LuaAny.new(create_ref)
      else
        nil
      end
    end

    # Converts value at *index* to `Hash`
    def to_h(index : Int32) : Hash(String | Float64, LuaAny)
      push_value(index)
      LuaTableIterator.new(self).to_h.tap do
        pop(1)
      end
    end

    # Converts value at *index* to `Array`
    def to_a(index : Int32) : Array(LuaAny)
      hash = to_h(index)
      total = hash.keys.count { |k| k.is_a?(Float64) && k > 0 && k % 1 == 0 }
      Array(LuaAny).new(total).tap do |arr|
        total.times do |n|
          i = n + 1
          if value = hash[i]?
            arr << value
          else
            break
          end
        end
      end
    end

    private macro push_fn__eq
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %state.push(LibLuaJIT.lua_equal(%state, -2, -1) == true.to_unsafe)
        1
      end
    end

    private macro push_fn__less_than
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %state.push(LibLuaJIT.lua_lessthan(%state, -2, -1) == true.to_unsafe)
        1
      end
    end

    private macro push_fn__get_table
      push_fn do |%lua_state|
        LibLuaJIT.lua_gettable(%lua_state, -2)
        1
      end
    end

    private macro push_fn__get_field
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        %state.pop(1)
        LibLuaJIT.lua_getfield(%state, -1, %key)
        1
      end
    end

    private macro push_fn__get_global
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        LibLuaJIT.lua_getfield(%state, LibLuaJIT::LUA_GLOBALSINDEX, %key)
        1
      end
    end

    private macro push_fn__get_registry
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        LibLuaJIT.lua_getfield(%state, LibLuaJIT::LUA_REGISTRYINDEX, %key)
        1
      end
    end

    private macro push_fn__get_environment
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        LibLuaJIT.lua_getfield(%state, LibLuaJIT::LUA_ENVIRONINDEX, %key)
        1
      end
    end

    private macro push_fn__next
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %result = LibLuaJIT.lua_next(%state, -2)
        if %result != 0
          %state.push(true)
        else
          %state.push(nil)
          %state.push(nil)
          %state.push(false)
        end
        3
      end
    end

    private macro push_fn__concat
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %size = %state.size
        LibLuaJIT.lua_concat(%lua_state, %size)
        1
      end
    end

    private macro push_fn__set_table
      push_fn do |%lua_state|
        LibLuaJIT.lua_settable(%lua_state, -3)
        0
      end
    end

    private macro push_fn__set_field
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        %state.pop(1)
        LibLuaJIT.lua_setfield(%state, -2, %key)
        0
      end
    end

    private macro push_fn__set_global
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        %state.pop(1)
        LibLuaJIT.lua_setfield(%state, LibLuaJIT::LUA_GLOBALSINDEX, %key)
        0
      end
    end

    private macro push_fn__set_registry
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        %state.pop(1)
        LibLuaJIT.lua_setfield(%state, LibLuaJIT::LUA_REGISTRYINDEX, %key)
        0
      end
    end

    private macro push_fn__set_environment
      push_fn do |%lua_state|
        %state = LuaState.new(%lua_state)
        %key = %state.to_string(-1)
        %state.pop(1)
        LibLuaJIT.lua_setfield(%state, LibLuaJIT::LUA_ENVIRONINDEX, %key)
        0
      end
    end

    private macro set_at_panic_handler(lua)
      {{lua}}.at_panic do |%lua_state|
        %state = LuaState.new(%lua_state)
        %message = LuaError.at_panic_message(%state)
        STDERR.puts(%message)
        0
      end
    end
  end
end
