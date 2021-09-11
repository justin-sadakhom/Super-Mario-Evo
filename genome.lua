module("genome", package.seeall)
local U = require("utils")

local Genome = {}

function Genome:new(synapseGenes, neuronGenes)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.genes = {}
  o.genes["synapses"] = {}
  o.genes["neurons"] = {}
  
  for i = 1, #synapseGenes do
    o.genes["synapses"][synapseGenes[i].innovation] = synapseGenes[i]
  end
  
  for i = 1, #neuronGenes do
    o.genes["neurons"][neuronGenes[i].innovation] = neuronGenes[i]
  end
  
  return o
end

function Genome:getSynapseGene(innovation)
  return self.genes["synapses"][innovation]
end

function Genome:addSynapseGene(gene)
  self.genes["synapses"][gene.innovation] = gene
end

function Genome:getNeuronGene(innovation)
  return self.genes["neurons"][innovation]
end

function Genome:addNeuronGene(gene)
  self.genes["neurons"][gene.innovation] = gene
end

function Genome:getNumDisabled()
  local result = 0
  local synapseKeys = getKeys(self.genes["synapses"])
  
  for i = 1, #synapseKeys do
    if not self:getSynapseGene(synapseKeys[i]).enabled then
      result = result + 1
    end
  end
  
  return result
end

function Genome:equals(genome)
  
  for innov in pairs(genome.genes["synapses"]) do
    if self:getSynapseGene(innov) == nil or not self:getSynapseGene(innov):equals(genome:getSynapseGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(self.genes["synapses"]) do
    if genome:getSynapseGene(innov) == nil or not self:getSynapseGene(innov):equals(genome:getSynapseGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(genome.genes["neurons"]) do
    if self:getNeuronGene(innov) == nil or not self:getNeuronGene(innov):equals(genome:getNeuronGene(innov)) then
      return false
    end
  end
  
  for innov in pairs(self.genes["neurons"]) do
    if genome:getNeuronGene(innov) == nil or not self:getNeuronGene(innov):equals(genome:getNeuronGene(innov)) then
      return false
    end
  end
  
  return true
end

function Genome:getRandomNeuron(excluding)
  local exclusion = {}
  
  for innov, gene in pairs(self.genes["neurons"]) do
    if gene.layer ~= excluding then
      table.insert(exclusion, gene)
    end
  end
  
  local result = exclusion[math.random(#exclusion)]
  return result
end

function Genome:containsSynapseGene(synapseGene)
  for innov, gene in pairs(self.genes["synapses"]) do
    if gene:equals(synapseGene) then
      return true
    end
  end
  
  return false
end

function Genome:copy(genome)
  local o = U.deepCopy(genome)
  setmetatable(o, self)
  self.__index = self
  return o
end

return Genome