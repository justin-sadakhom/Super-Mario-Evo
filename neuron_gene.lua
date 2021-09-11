module("neuron_gene", package.seeall)
local NeuronGene = {}

neuronGenePool = {}
outputNeuronGenePool = {}

function NeuronGene:new(layer)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  if layer == nil then
    o.layer = "hidden"
  else
    o.layer = layer
  end
  
  if layer == "output" then
    o.innovation = #outputNeuronGenePool + 1 + 1000000
    table.insert(outputNeuronGenePool, o)
  else
    o.innovation = #neuronGenePool + 1
    table.insert(neuronGenePool, o)
  end
    
  return o
end

function NeuronGene:equals(gene)
  return self.layer == gene.layer and self.innovation == gene.innovation
end

return NeuronGene