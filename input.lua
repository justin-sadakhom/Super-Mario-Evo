module("input", package.seeall)

local ButtonNames = {
  "A",
  "B",
  "X",
  "Y",
  "Up",
  "Down",
  "Left",
  "Right",
}

-- We divide the screen into squares of dimensions BoxLength x BoxLength
-- and use info in each of those squares as elements for the input array.
local BoxLength = 16
local BoxRadius = 6

function getPositions()
  local result = {}
  
  -- Reference memory addresses for Mario's position in the level.
  -- AVOID local position because Mario is often fixed relative
  -- to the camera while moving around.
  marioX = memory.read_s16_le(0x94)
  marioY = memory.read_s16_le(0x96)
  
  -- Reference memory addresses for position of first layer.
  local layerX = memory.read_s16_le(0x1A);
  local layerY = memory.read_s16_le(0x1C);

  screenX = marioX - layerX
  screenY = marioY - layerY
  
  result["marioX"] = marioX
  result["marioY"] = marioY
  result["screenX"] = screenX
  result["screenY"] = screenY
  
  return result
end

-- 
-- Valid values for memory address 0xE4:
-- 00 Free slot, non-existent sprite.
-- 01	Initial phase of sprite.
-- 02 Killed, falling off screen.
-- 03	Smushed. Rex and shell-less Koopas can be in this state.
-- 04	Killed with a spinjump.
-- 05	Burning in lava; sinking in mud.
-- 06	Turn into coin at level end.
-- 07	Stay in Yoshi's mouth.
-- 08	Normal routine.
-- 09	Stationary / Carryable.
-- 0A	Kicked.
-- 0B	Carried.
-- 0C	Powerup from being carried past goaltape.
--
local function getSprites()
  local sprites = {}
  
  -- Memory address 0x14C8 stores 12 bytes.
  -- 0x14C8 + 0 would be status of first sprite...
  -- 0x14C8 + 1 would be status of second sprite, and so on.
  for slot = 0, 11 do
    local status = memory.readbyte(0x14C8 + slot)
    
    -- Ignore status 0 because sprite would be non-existent.
    if status ~= 0 then
      
      -- Both 0xE4 and 0xD8 store high-byte values.
      -- Convert low-byte values by multiplying them by 256
      -- before summing up both high-byte values.
      spriteX = memory.readbyte(0xE4 + slot) + memory.readbyte(0x14E0 + slot) * 256
      spriteY = memory.readbyte(0xD8 + slot) + memory.readbyte(0x14D4 + slot) * 256
      
      sprites[#sprites + 1] = {["x"] = spriteX, ["y"] = spriteY}
    end
  end		

  return sprites
end

--
-- Valid values for memory address 0x170B:
-- 00	(empty)
-- 01	Smoke puff
-- 02	Reznor fireball
-- 03	Flame left by hopping flame
-- 04	Hammer
-- 05	Player fireball
-- 06	Bone from Dry Bones
-- 07	Lava splash
-- 08	Torpedo Ted shooter's arm
-- 09	Unknown flickering object
-- 0A	Coin from coin cloud game
-- 0B	Piranha Plant fireball
-- 0C	Lava Lotus's fiery objects
-- 0D	Baseball
-- 0E	Wiggler's flower
-- 0F	Trail of smoke (from Yoshi stomping the ground)
-- 10	Spinjump stars
-- 11	Yoshi fireballs
-- 12	Water bubble
--
local function getExtendedSprites()
  local extended = {}
  
  for slot = 0, 11 do
    local number = memory.readbyte(0x170B + slot)
    
    if number ~= 0 then
      spriteX = memory.readbyte(0x171F + slot) + memory.readbyte(0x1733 + slot) * 256
      spriteY = memory.readbyte(0x1715 + slot) + memory.readbyte(0x1729 + slot) * 256
      
      extended[#extended + 1] = {["x"] = spriteX, ["y"] = spriteY}
    end
  end		

  return extended
end

-- Check if there's a tile at the given coordinates.
-- Return 1 if yes, return 0 otherwise.
local function getTile(dx, dy)
  -- Since origin (0, 0) is the upper left corner, marioX is actually the
  -- leftmost pixel on Mario's sprite. Add 8 to account for this because
  -- the sprite is 8 pixels wide.
  x = math.floor((marioX + dx + 8) / BoxLength) -- xPos of box that tile is in
  y = math.floor((marioY + dy) / BoxLength)     -- yPos of box that tile is in
  
  return memory.readbyte(0x1C800 + math.floor(x / 0x10) * 0x1B0 + y * 0x10 + x % 0x10)
end

-- Each input value indicates a different box.
-- -1: Enemy
--  0: Air
--  1: Obstruction
function getInputs()
  getPositions()
  
  sprites = getSprites()
  extended = getExtendedSprites()
  
  local inputs = {}
  local limit = BoxRadius * BoxLength
  
  -- Create 13x13 input array.
  -- Iterate through dy = -96, -80, ..., 96.
  -- Iterate through dx = -96, -80, ..., 96.
  for dy = -limit, limit, BoxLength do
    for dx = -limit, limit, BoxLength do
      inputs[#inputs + 1] = 0 -- By default, a box is empty and doesn't affect the environment.
      tile = getTile(dx, dy)
      
      -- If there's a tile less than a screen's length away, mark its box as an obstruction.
      if tile == 1 and marioY + dy < 0x1B0 then
        inputs[#inputs] = 1
      end
      
      for i = 1, #sprites do
        distX = math.abs(sprites[i]["x"] - (marioX + dx))
        distY = math.abs(sprites[i]["y"] - (marioY + dy))
        
        -- If there's a sprite on the screen, mark its box as an enemy.
        if distX <= 8 and distY <= 8 then
          inputs[#inputs] = -1
        end
      end
      
      for i = 1, #extended do
        distX = math.abs(extended[i]["x"] - (marioX + dx))
        distY = math.abs(extended[i]["y"] - (marioY + dy))
        
        -- If there's a sprite on the screen, mark its box as an enemy.
        if distX <= 8 and distY <= 8 then
          inputs[#inputs] = -1
        end
      end
    end
  end
  
  return inputs
end

local I = {}

I.ButtonNames = ButtonNames
I.getPositions = getPositions 
I.getInputs = getInputs

return I