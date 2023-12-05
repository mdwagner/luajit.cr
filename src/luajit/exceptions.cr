module Luajit
  class LuaError < Exception
    def self.default_handler(state : LuaState, status : LuaStatus) : LuaError
      new(
        String.build do |str|
          if state.is_string?(-1)
            str << state.to_string(-1) << ' '
            state.pop(1)
          end
          str << "(#{status.to_s})"
        end
      )
    end

    # :nodoc:
    def self.pcall_handler(state : LuaState, status : LuaStatus, lua_method : String) : LuaError
      new(
        String.build do |str|
          if state.is_string?(-1)
            str << state.to_string(-1) << ' '
            state.pop(1)
          end
          str << "(#{status.to_s}) from '#{lua_method}'"
        end
      )
    end

    # :nodoc:
    def self.at_panic_message(state : LuaState) : String
      String.build do |str|
        str << "PANIC: "
        if state.is_string?(-1)
          str << state.to_string(-1)
          state.pop(1)
        else
          str << "Unknown"
        end
        str << '\n'
      end
    end
  end
end
