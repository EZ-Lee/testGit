require_relative 'dfc_observable'

class DFC_FloorObserver
	def brforeFloorChange(*arguments); end
	def onFloorChange(*arguments); end
end

class FloorMonitor < DFC_FloorObserver
	def brforeFloorChange(*arguments)
		puts "brforeFloorChange -> #{arguments}"
	end
	def onFloorChange(*arguments)
		puts "onFloorChange -> #{arguments}"
	end
end

class FloorInitialize
	include DFC_BIM::SYSTEM::DFC_Observable
	def initialize
		@value = 1
	end

	def onchange
		changed
		notify_observers(:brforeFloorChange, @value)
		@value = 2
		changed
		notify_observers(:onFloorChange, @value)
	end

end

ob = FloorMonitor.new

FLOOR = FloorInitialize.new
FLOOR.add_observer(ob)
FLOOR.onchange
FLOOR.remove_observer(ob)
FLOOR.onchange

