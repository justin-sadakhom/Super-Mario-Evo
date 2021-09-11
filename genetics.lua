module("genetics", package.seeall)
local U = require("utils")

local Genome = require("genome")
local NeuronGene = require("neuron_gene")
local SynapseGene = require("synapse_gene")

local PointMutationRate = 0.25
local SynapseMutationRate = 2.0
local BiasMutationRate = 0.40
local NeuronMutationRate = 0.50
local DisableMutationRate = 0.4
local EnableMutationRate = 0.2
local NonMatchingCoeff = 1.0
local WeightCoeff = 0.4
local SpeciesThreshold = 1.5

local function getStarterGenome()
  local genome = {}
  local neuronGenes = {}
  
  for j = 1, 169 + 8 do
    if j <= 169 then
      neuronGene = NeuronGene:new("input")
    else
      neuronGene = NeuronGene:new("output")
    end
    
    table.insert(neuronGenes, neuronGene)
  end
  
  return Genome:new({}, neuronGenes)
end

local starterGenome = getStarterGenome()

local function crossoverSynapses(genome1, genome2, isEqualFitness)
  local newGenome = Genome:copy(starterGenome)
  
  local synapses1 = genome1.genes["synapses"]
  local synapses2 = genome2.genes["synapses"]
  local synapseUnion = U.union(synapses1, synapses2)
  
  for innov, gene in pairs(synapseUnion) do
    -- If genes match, inherit from a random parent.
    if synapses1[innov] ~= nil and synapses2[innov] ~= nil and synapses1[innov]:equals(synapses2[innov]) then
      local randChoice = math.random(2)
      
      if randChoice == 1 then
        newGenome:addSynapseGene(synapses1[innov])
      else
        newGenome:addSynapseGene(synapses2[innov])
      end
    
    elseif isEqualFitness then
    -- If genes are disjoint / excess, inherit regardless of parent.
    
      if synapses1[innov] ~= nil then
        newGenome:addSynapseGene(synapses1[innov])
      
      elseif synapses2[innov] ~= nil then
        newGenome:addSynapseGene(synapses2[innov])
      end
      
    else
      -- If genes are disjoint / excess, inherit from the more fit parent.
      if synapses1[innov] ~= nil then
        newGenome:addSynapseGene(synapses1[innov])
      end
    end
  end
  
  return newGenome
end

local function generateNeuronGenes(genome1, genome2, childGenome)
  local synapses = childGenome.genes["synapses"]
  
  -- Add neuron genes corresponding to the neurons that the connections use.
  for innov, gene in pairs(synapses) do
    local inputInnov = gene.input
    local outputInnov = gene.output
    
    if childGenome:getNeuronGene(inputInnov) == nil then
      
      if genome1:getNeuronGene(inputInnov) ~= nil then
        childGenome:addNeuronGene(genome1:getNeuronGene(inputInnov))
        
      elseif genome2:getNeuronGene(inputInnov) ~= nil then
        childGenome:addNeuronGene(genome2:getNeuronGene(inputInnov))
      end
    end
      
    if childGenome:getNeuronGene(outputInnov) == nil then
      
      if genome1:getNeuronGene(outputInnov) ~= nil then
        childGenome:addNeuronGene(genome1:getNeuronGene(outputInnov))
        
      elseif genome2:getNeuronGene(outputInnov) ~= nil then
        childGenome:addNeuronGene(genome2:getNeuronGene(outputInnov))
      end
    end
    
  end
end

-- Return random value between minWeight and maxWeight, inclusive.
local function getRandomWeight(minWeight, maxWeight)
  return math.random(minWeight * 10, maxWeight * 10) / 10
end

-- Mutate random weights in the genome.
local function mutatePoint(genome)
  for innov, gene in pairs(genome.genes["synapses"]) do
    if math.random() < 0.9 then
      gene.weight = gene.weight * getRandomWeight(-2.0, 2.0)
    end
  end
end

local function getKeys(someTable)
  local keys = {}
  
  for key in pairs(someTable) do
    table.insert(keys, key)
  end
  
  return keys
end

-- Mutate by connecting two previously unconnected nodes.
local function mutateConnection(genome, forceBias)
  local inputNeuron = genome:getRandomNeuron("output")
  local outputNeuron = genome:getRandomNeuron("input")
  local gene = SynapseGene:new(inputNeuron.innovation, outputNeuron.innovation, getRandomWeight(-2, 2), true)
  
  -- Make resulting synapse take input from a bias neuron.
  if forceBias then
    gene.input = 170
  end
  
  if genome:containsSynapseGene(gene) then
    return
  else
    genome:addSynapseGene(gene)
  end
end

-- Mutate by adding an intermediate node to an existing connection.
-- Example: a synapse connects neuron 1 and neuron 2.
-- The mutation here would create a neuron 3 and corresponding synapses
-- such that neuron 1 connects to neuron 3 and neuron 3 connects to neuron 2.
local function mutateNode(genome)
  
  if #getKeys(genome.genes["synapses"]) == 0 then
    return
  end
  
  local synapseKeys = getKeys(genome.genes["synapses"])
  local randomSynapse = genome:getSynapseGene(synapseKeys[math.random(#synapseKeys)])
  local randomNeuron = NeuronGene:new()
  
  if not randomSynapse.enabled then
    return
  end
  
  -- Disable old synapse.
  randomSynapse.enabled = false
  
  local synapse1 = SynapseGene:new(randomSynapse.input, randomNeuron.innovation, getRandomWeight(-2, 2), true)
  local synapse2 = SynapseGene:new(randomNeuron.innovation, randomSynapse.output, getRandomWeight(-2, 2), true)
  
  genome:addNeuronGene(randomNeuron)
  genome:addSynapseGene(synapse1)
  genome:addSynapseGene(synapse2)
end

local function mutateBridge(genome, enable)
	local candidates = {}
  
	for innov, gene in pairs(genome.genes["synapses"]) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end
 
	if #candidates == 0 then
		return
	end
 
	local gene = candidates[math.random(1, #candidates)]
	gene.enabled = not gene.enabled
end

-- NOTE: ADD DYNAMIC MUTATION RATES
local function mutate(genome)
  if math.random() < PointMutationRate then
    mutatePoint(genome)
  end
  
  local p = SynapseMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateConnection(genome, false)
		end
    
		p = p - 1
	end
  
  p = BiasMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateConnection(genome, true)
		end
    
		p = p - 1
	end
  
  p = NeuronMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateNode(genome)
		end
    
		p = p - 1
	end
  
  p = EnableMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateBridge(genome, true)
		end
    
		p = p - 1
	end
 
	p = DisableMutationRate
  
	while p > 0 do
		if math.random() < p then
			mutateBridge(genome, false)
		end
    
		p = p - 1
	end
end

-- Generate a new genome from two parents.
local function crossover(mario1, mario2)
  -- Note: this assumes that calcFitness() has already been called.
  local fitness1 = mario1.fitness
  local fitness2 = mario2.fitness
  
  -- Assume genome1 has higher or equal fitness.
  local genome1 = mario2.genome
  local genome2 = mario1.genome
  
  if fitness2 > fitness1 then
    local genome1 = mario2.genome
    local genome2 = mario1.genome
  end
  
  local newGenome = crossoverSynapses(genome1, genome2, fitness1 == fitness2)
  generateNeuronGenes(genome1, genome2, newGenome)
  
  -- Sprinkle in random mutations.
  mutate(newGenome)
  return newGenome
end

local function getNumNonMatching(genome1, genome2)
  result = 0
  
  for innov in pairs(genome1.genes["synapses"]) do
    if genome2:getSynapseGene(innov) == nil then
      result = result + 1
    end
  end
  
  for innov in pairs(genome2.genes["synapses"]) do
    if genome1:getSynapseGene(innov) == nil then
      result = result + 1
    end
  end
  
  return result
end

local function getWeightDiffs(genome1, genome2)
  result = 0
  
  for innov in pairs(genome1.genes["synapses"]) do
    if genome2:getSynapseGene(innov) ~= nil then
      result = result + math.abs(genome1:getSynapseGene(innov).weight - genome2:getSynapseGene(innov).weight)
    end
  end
  
  return result
end

local function isSameSpecies(genome1, genome2)
  local var1 = getNumNonMatching(genome1, genome2)
  local var2 = getWeightDiffs(genome1, genome2)
  
  local keys1 = getKeys(genome1.genes["synapses"])
  local keys2 = getKeys(genome2.genes["synapses"])
  local n = math.max(#keys1, #keys2)
  
  return NonMatchingCoeff * var1 / n + WeightCoeff * var2 < SpeciesThreshold
end

local G = {}

G.getStarterGenome = getStarterGenome
G.mutate = mutate
G.crossover = crossover
G.isSameSpecies = isSameSpecies

return G