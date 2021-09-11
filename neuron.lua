module("neuron", package.seeall)
local Neuron = {}

function Neuron:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.incoming = {}
  o.value = 0.0
  
  return o
end

function Neuron:addIncomingSynapse(synapse)
  table.insert(self.incoming, synapse)
end

function Neuron:equals(neuron)
  return self.incoming == neuron.incoming and self.value == neuron.value
end

return Neuron