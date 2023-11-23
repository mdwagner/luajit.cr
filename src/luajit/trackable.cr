module Luajit
  # :nodoc:
  class Trackable
    # LuaState (pointer address) => tracked pointers used within LuaState
    #
    # Used to avoid garbage collecting in-use pointers inside LuaState
    @@tracked = {} of String => Array(Pointer(Void))

    def self.track(key : String, ptr : Pointer(Void)) : Nil
      if ptrs = @@tracked[key]?
        ptrs << ptr
      else
        @@tracked[key] = [ptr]
      end
    end

    def self.untrack(key : String, ptr : Pointer(Void)) : Nil
      if ptrs = @@tracked[key]?
        ptrs.reject! do |tracked_ptr|
          tracked_ptr == ptr
        end
      end
    end

    def self.clear : Nil
      @@tracked.clear
    end

    def self.remove(key : String) : Nil
      @@tracked.delete(key)
    end
  end
end
