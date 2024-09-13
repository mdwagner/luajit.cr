require "../luajit"

class Luajit::Wrappers::NIL
  def self.setup(state : Luajit::LuaState) : Nil
    state.new_userdata(0_u64)
    state.push({
      "__tostring" => Luajit::LuaState::Function.new { |__state|
        __state.push("NIL")
        1
      }
    })
    state.push_value(-1)
    state.set_registry("__NIL__")
    state.set_metatable(-2)
    state.set_global("NIL")
  end

  def self.is_nil?(state : Luajit::LuaState, index : Int32) : Bool
    begin
      state.check_userdata!(index, "__NIL__")
      true
    rescue Luajit::LuaError
      false
    end
  end
end
