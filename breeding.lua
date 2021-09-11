module("breeding", package.seeall)
local G = require("genetics")
local U = require("utils")

local Mario = require("mario")
local Genome = require("genome")
local NeuronGene = require("neuron_gene")

local MaxPopulation = 300

local function getSpecies(population)
  local species = {}
  table.insert(species, {population[1]})
  
  for i = 2, #population do
    local flag = false
    
    for j = 1, #species do
      if G.isSameSpecies(population[i].genome, species[j][1].genome) then
        table.insert(species[j], population[i])
        flag = true
        break
      end
    end
    
    if not flag then
      table.insert(species, {population[i]})
    end
  end
  
  return species
end

local function getSpeciesFitness(species)
  local fitness = 0
  
  for i = 1, #species do
    fitness = fitness + species[i].fitness
  end
  
  return fitness
end

-- Decide how many individuals from each species will be birthed for next gen.
local function assignBirthRights(species)
  -- Table of species num mapping to number of babies.
  local result = {}
  local sumFitness = 0
  
  for i = 1, #species do
    for j = 1, #species[i] do
      sumFitness = sumFitness + species[i][j].fitness
    end
  end
  
  local sum = 0
  
  for i = 1, #species do
    speciesFitness = getSpeciesFitness(species[i])
    local birthRights = 0
    
    if math.ceil(#species[i] / 2) < 2 then
      birthRights = 1
    else
      birthRights = math.ceil(speciesFitness / sumFitness * MaxPopulation)
    end
    
    result[i] = birthRights
    sum = sum + birthRights
  end
  
  print("Total birthrights: " .. sum)
  return result
end

local function sortByDescending(object)
  table.sort(object, function(a, b)
      return a.fitness > b.fitness
    end
  )
end

local function cullStaleSpecies(species)
end

local function cullPopulation(species)
  
  for i = 1, #species do
    sortByDescending(species[i])
    local current = #species[i]
    local survivors = 0
    
    if current < 2 then 
      survivors = current
    else
      survivors = math.floor(#species[i] / 2)
    end
    
    while current > survivors do
      table.remove(species[i], current)
      current = current - 1
    end
  end
end

local function sortByDescendingTrueFitness(object)
  table.sort(object, function(a, b)
      return a:getTrueFitness() > b:getTrueFitness()
    end
  )
end

local function getSelectionWeights(species)
  local weights = {}
  local speciesFitness = 0
    
  for i = 1, #species do
    speciesFitness = speciesFitness + species[i].fitness
  end
    
  for i = 1, #species do
    weights[i] = species[i].fitness / speciesFitness
  end
  
  return weights
end

local function selectParents(species)
  local parents = {}
  local birthRights = assignBirthRights(species)
  
  for i = 1, #species do
    sortByDescending(species[i])
    local weights = getSelectionWeights(species[i])
    
    for j = 1, birthRights[i] * 2 do
      local roll = math.random()
      
      for k = 1, #weights do
        local chance = 0
        
        if k == 1 then
          chance = weights[k]
        else
          chance = chance + weights[k]
        end
        
        if roll < chance then
          table.insert(parents, species[i][k])
          break
        end
      end
    end
  end
  
  print("Total parents: " .. #parents)
  return parents
end

local starterGenome = G.getStarterGenome()

local function breedFirstGen()
  local generation = {}
  
  for i = 1, MaxPopulation do
    local mario = Mario:new(Genome:copy(starterGenome))
    G.mutate(mario.genome)
    table.insert(generation, mario)
  end
  
  return generation
end

local function breedNextGen(lastGeneration)
  local generation = {}
  sortByDescendingTrueFitness(lastGeneration)
  
  local copy1 = U.deepCopy(lastGeneration[1])
  local copy2 = U.deepCopy(lastGeneration[2])
  
  local species = getSpecies(lastGeneration)
  cullPopulation(species)
  local parents = selectParents(species)
  
  for i = 1, #parents / 2 do
    local parent1 = parents[2 * i - 1]
    local parent2 = parents[2 * i]
    table.insert(generation, Mario:new(G.crossover(parent1, parent2)))
  end
  
  -- The individual with the highest unadjusted fitness is cloned.
  generation[1] = copy1
  generation[2] = copy2
  
  for i = 1, MaxPopulation - #generation do
    table.insert(generation, Mario:new(G.crossover(generation[1], generation[2])))
  end
  
  print("Total population: " .. #generation)
  return generation
end

local B = {}
B.getSpecies = getSpecies
B.breedFirstGen = breedFirstGen
B.breedNextGen = breedNextGen

return B