-- IMPORTANT: Replace with absolute path of your src directory.
path = ""
package.path = path .. "\\?.lua;" .. package.path

module("main", package.seeall)
local I = require("input")
local B = require("breeding")
local N = require("network")

function evaluateCurrent(network)
  -- Get output from neural network.
	local input = I.getInputs()
	controller = N.evaluateNeuralNetwork(network, input)
 
	if controller["P1 Left"] and controller["P1 Right"] then
		controller["P1 Left"] = false
		controller["P1 Right"] = false
	end
  
	if controller["P1 Up"] and controller["P1 Down"] then
		controller["P1 Up"] = false
		controller["P1 Down"] = false
	end
 
  -- Control Mario using outputs.
	joypad.set(controller)
end

function clearJoypad()
  controller = {}
  
	for b = 1, #I.ButtonNames do
		controller["P1 " .. I.ButtonNames[b]] = false
	end
  
	joypad.set(controller)
end

function runProgram()
  local genCount = 1
  local lastGeneration = {}
  
  while true do
    -- Initialize generation.
    local generation = {}
    print("Generation " .. genCount)
    
    if genCount == 1 then
      generation = B.breedFirstGen()
    else
      generation = B.breedNextGen(lastGeneration)
    end
    
    local species = B.getSpecies(generation)
    print("No. of species: " .. #species)
    local count = 1
    
    -- Loop through individuals in generation.
    for i = 1, #species do
      
      for j = 1, #species[i] do
        if count % 10 == 0 then
          print("Current individual: " .. count)
        end
        
        local rightmost = 0
        local currentFrame = 0
        local timeLeft = 20
        savestate.loadslot(1)
        clearJoypad()
        local network = N.buildNeuralNetwork(species[i][j].genome)
        
        -- Individual plays out their run.
        while true do
          if currentFrame % 5 == 0 then
            evaluateCurrent(network)
          end
          
          joypad.set(controller)
          
          local positions = I.getPositions()
          if positions["marioX"] > rightmost then
            rightmost = positions["marioX"]
            timeLeft = 20
          end
          
          timeLeft = timeLeft - 1
          
          -- Calculate timeoutBonus.
          local timeoutBonus = currentFrame / 4
          
          if timeLeft + timeoutBonus <= 0 then
            species[i][j].distance = rightmost
            species[i][j]:setFinishTime()
            local numSameSpecies = #species[i]
            species[i][j]:calcFitness(numSameSpecies)
            
            if species[i][j].distance > 16 then
              print(species[i][j]:getTrueFitness())
            end
            
            break
          end
          
          currentFrame = currentFrame + 1
          emu.frameadvance()
        end
        
        count = count + 1
      end
    end
    
    lastGeneration = generation
    genCount = genCount + 1
  end
end

runProgram()