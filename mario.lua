module("mario", package.seeall)
local Mario = {}

-- Mario class.
function Mario:new(genome)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.distance = 0
  o.finishTime = 0
  o.genome = genome
  
  return o
end

function Mario:equals(mario)
  return self.distance == mario.distance and self.finishTime == mario.finishTime and self.genome:equals(mario.genome)
end

function Mario:setFinishTime()
  -- Max time is 300.
  if self.distance < 4832 then
    self.finishTime = 0
  else
    self.finishTime = memory.readbyte(0x0F31) * 100 + memory.readbyte(0x0F32) * 10 + memory.readbyte(0x0F33)
  end
end

function Mario:calcFitness(numSameSpecies)
  -- Square distance to place more emphasis on reaching the end goal.
  self.fitness = (self.distance + self.finishTime) / numSameSpecies
end

function Mario:getTrueFitness()
  return self.distance + self.finishTime
end

return Mario