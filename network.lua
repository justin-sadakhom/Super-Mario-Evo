module("network", package.seeall)
local Neuron = require("neuron")
local I = require("input")

local function buildNeuralNetwork(genome)
  local network = {}
  network.neurons = {}
  
  for i = 1, 169 + 1 do -- +1 to account for potential bias node.
    network.neurons[i] = Neuron:new()
  end
  
  for i = 1, 8 do
		network.neurons[1000000 + i] = Neuron:new()
	end
  
  for innov, gene in pairs(genome.genes["synapses"]) do
    if gene.enabled then
      if network.neurons[gene.output] == nil then
        network.neurons[gene.output] = Neuron:new()
      end
      
      local neuron = network.neurons[gene.output]
      neuron:addIncomingSynapse(gene)
      
      if network.neurons[gene.input] == nil then
        network.neurons[gene.input] = Neuron:new()
      end
    end
  end
  
  return network
end

local function sigmoid(x)
  return 2 / (1 + math.exp(-4.9 * x)) - 1
end

local function evaluateNeuralNetwork(network, input)
  local output = {}
  table.insert(input, 1)
  
  if #input ~= 169 + 1 then
		print("Incorrect number of neural network inputs.")
    return {}
	end
  
  -- Set initial input through input neurons.
  for i = 1, 169 + 1 do
    network.neurons[i].value = input[i]
  end
  
  -- Process input through hidden neurons.
  for innov, neuron in pairs(network.neurons) do
    local sum = 0
    
    -- Get strength of input.
    for j = 1, #neuron.incoming do
      local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.input]
			sum = sum + incoming.weight * other.value
    end
    
    -- Attempt to fire neuron.
    if #neuron.incoming > 0 then
			neuron.value = sigmoid(sum)
		end
  end
  
  -- Get resulting value of output neurons.
  for i = 1, 8 do
    local button = "P1 " .. I.ButtonNames[i]
    
    -- If neuron fires, register output.
    if network.neurons[1000000 + i].value > 0 then
      output[button] = true
    else
      output[button] = false
    end
  end
  
  return output
end

local N = {}

N.buildNeuralNetwork = buildNeuralNetwork
N.evaluateNeuralNetwork = evaluateNeuralNetwork

return N