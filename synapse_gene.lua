module("synapse_gene", package.seeall)
local SynapseGene = {}

synapseGenePool = {}

function SynapseGene:new(input, output, weight, enabled)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  
  o.input = input
  o.output = output
  o.weight = weight
  o.enabled = enabled
  
  for i = 1, #synapseGenePool do
    if o:equals(synapseGenePool[i]) then
      o.innovation = synapseGenePool[i].innovation
    end
  end
  
  if o.innovation == nil then
    o.innovation = #synapseGenePool + 1
    table.insert(synapseGenePool, o)
  end
  
  return o
end

function SynapseGene:copy(gene)
  self.input = gene.input
  self.output = gene.output
  self.weight = gene.weight
  self.enabled = gene.enabled
  self.innovation = gene.innovation
end

function SynapseGene:equals(gene)
  return self.input == gene.input and self.output == gene.output
end

return SynapseGene