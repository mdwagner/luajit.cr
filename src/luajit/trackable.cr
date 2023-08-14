module Luajit
  module Trackable
    macro included
      # Collection of pointers to track within Crystal to avoid GC
      class_getter trackables = [] of Pointer(Void)

      # Adds a reference (pointer) to be tracked
      def self.add_trackable(ptr : Pointer(Void)) : Nil
        trackables << ptr
      end

      # Removes a reference from being tracked
      def self.remove_trackable(ref : Reference) : Nil
        trackables.reject! do |ptr|
          ptr.address == ref.object_id
        end
      end
    end
  end
end
