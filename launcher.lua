local casino = require("casino")--22:52
local event = require("event")
local shell = require("shell")
local unicode = require("unicode")
local settings = require("settings")
local computer = require('computer')
local games
local currencies
local image
local buffer
local colorlib
local unicode = require("unicode")
local event = require("event")
local computer = require("computer")
local fs = require("filesystem")
local com = require('component')
--local interface = com.me_interface
local gpu = com.gpu
local choice,run = false,true
local drawFrom = 0
local items,pos_str = {},{}
local patch_items = "/home/items.lua"

if not fs.exists(patch_items) then
  local f = io.open(patch_items,'w')
  f:write("{".."\n")
  f:write("  shop = {".."\n")
  --local data = interface.getItemsInNetwork()
  for item = 1,#data do
    if data[item] then
      f:write('    { text = "'..data[item].label..'", price = "0", label = "'..data[item].label..'" },'..'\n')
    end
  end
  f:write("  }".."\n")
  f:write("}")
  f:close()
  os.execute("edit "..patch_items)
  os.exit()
end

local f, err = io.open(patch_items, "r")
if not f then
  error(err, 2)
end
local text = f:read('*a')
f:close() 
local chunk, err = load("return " .. text, "=items.lua", "t")
if not chunk then 
  error(err, 2)
else
  items = chunk()
end
table.sort(items.shop, function(a,b) if a.text then return a.text < b.text end end)
for i = 1,#items.shop do
  --items.shop[i].available = "0"
  items.shop[i].available = tostring(math.random(0,10))
end

local ind = {}
for i = 1,#items.shop do
  if items.shop[i].available ~= "0" then
    table.insert(ind,i)
  end
end

local function square(x,y,width,height,color)
  if color and gpu.getBackground() ~= color then
    gpu.setBackground(color)
  end
  gpu.fill(x,y,width,height," ")
end



local function scroll(n)
  if n == 1 or n == "+" then
    drawFrom = drawFrom - 11
  else
    drawFrom = drawFrom + 11
  end
  if drawFrom >= #ind - 11 then
    drawFrom = #ind - 11
  end
  if drawFrom <= 0 then
    drawFrom = 0
  end
  drawlist()
end







 
REPOSITORY = settings.REPOSITORY

CURRENT_APP = nil
SHOULD_INTERRUPT = false

event.shouldInterrupt = function()
    if SHOULD_INTERRUPT then
        SHOULD_INTERRUPT = false
        if CURRENT_APP then
            CURRENT_APP = nil
            return true
        end
    end
    return false
end

local state = {
    selection = 1,
    devMode = false,
    currencyDropdown = false
}


local requiredDirectories = { "" }

local libs = {
    {
        url = REPOSITORY .. "/config/settings.lua",
        path = "/lib/settings.lua"
    },
    {
        url = REPOSITORY .. "/libs/casino.lua",
        path = "/lib/casino.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/AdvancedLua.lua",
        path = "/lib/advancedLua.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/Color.lua",
        path = "/lib/color.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/OCIF.lua",
        path = "/lib/FormatModules/OCIF.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/Image.lua",
        path = "/lib/image.lua"
    },
    {
        url = REPOSITORY .. "/external/IgorTimofeev/DoubleBuffering.lua",
        path = "/lib/doubleBuffering.lua"
    },
    {
        url = REPOSITORY .. "/config/games.lua",
        path = "/lib/games.lua"
    },
    {
        url = REPOSITORY .. "/config/currencies.lua",
        path = "/lib/currencies.lua"
    },
    {
        url = REPOSITORY .. "/libs/slot_machine.lua",
        path = "/lib/slot_machine.lua"
    },
    {
        url = REPOSITORY .. "/config/openChestConfiguration.lua",
        path = "/lib/openChestConfiguration.lua"
    }
}

local function isAdmin(player)
    for i = 1, #settings.ADMINS do
        if settings.ADMINS[i] == player then
            return true
        end
    end
    return false
end

local function writeCenter(x, y, text, color)
    buffer.drawText(math.floor(x - unicode.len(text) / 2), math.floor(y), color, text)
end

local function drawRectangleWithCenterText(x, y, width, height, text, bgColor, fgColor)
    buffer.drawRectangle(x, y, width, height, bgColor, 0, " ")
    writeCenter(width / 2 + x, height / 2 + y, text, fgColor)
end

local function drawCurrency(x, y, currency, current)
    buffer.drawRectangle(x, y, 46, 3, --[[current and 0xA890AA or--]] 0xE3E3E3, 0, " ")
    buffer.drawText(x + 8, y    , 0, currency.name)
    buffer.drawText(x + 8, y + 1, 0, "Максимальная ставка: " .. (currency.max or "-"))
    buffer.drawText(x + 8, y + 2, 0, "У казино: " .. casino.getCurrencyInStorage(currency) .. " шт.")

    local color = currency.color or 0xE3E3E3
    local darkColor = colorlib.transition(color, 0, 0.1)
    if currency.model == 'INGOT' then
        buffer.drawSemiPixelLine(x, y * 2 + 1, x + 2, y * 2 + 1, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2, x + 5, y * 2, darkColor)
        buffer.drawSemiPixelLine(x, y * 2 + 2, x + 2, y * 2 + 2, color)
        buffer.drawSemiPixelLine(x + 3, y * 2 + 1, x + 5, y * 2 + 1, color)
        buffer.drawSemiPixelLine(x, y * 2 + 3, x + 2, y * 2 + 3, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2 + 2, x + 5, y * 2 + 2, darkColor)
    elseif currency.model == 'DUST' then
        buffer.drawSemiPixelRectangle(x + 2, y * 2 + 1, 3, 2, color)
        buffer.drawSemiPixelRectangle(x + 1, y * 2 + 3, 5, 1, color)
        buffer.drawSemiPixelLine(x, y * 2 + 3, x + 3, y * 2, darkColor)
        buffer.drawSemiPixelLine(x + 3, y * 2, x + 6, y * 2 + 3, darkColor)
        buffer.drawSemiPixelLine(x + 1, y * 2 + 4, x + 5, y * 2 + 4, darkColor)
    elseif currency.model == 'BLOCK' then
        buffer.drawSemiPixelRectangle(x, y * 2 - 1, 6, 6, darkColor)
        buffer.drawSemiPixelRectangle(x + 1, y * 2, 4, 4, color)
    end

end
local function drawBigText(x, y, text)
    if not text then
        return
    end
    local lines = casino.splitString(text, "\n")
    for i = 0, #lines - 1 do
        buffer.drawText(x, y + i, 0x000000, lines[i + 1])
    end
end


if not fs.exists(patch_items) then
  local f = io.open(patch_items,'w')
  f:write("{".."\n")
  f:write("  shop = {".."\n")
  --local data = interface.getItemsInNetwork()
  for item = 1,#data do
    if data[item] then
      f:write('    { text = "'..data[item].label..'", price = "0", label = "'..data[item].label..'" },'..'\n')
    end
  end
  f:write("  }".."\n")
  f:write("}")
  f:close()
  os.execute("edit "..patch_items)
  os.exit()
end
 
local f, err = io.open(patch_items, "r")
if not f then
  error(err, 2)
end
local text = f:read('*a')
f:close() 
local chunk, err = load("return " .. text, "=items.lua", "t")
if not chunk then 
  error(err, 2)
else
  items = chunk()
end
table.sort(items.shop, function(a,b) if a.text then return a.text < b.text end end)
for i = 1,#items.shop do
  --items.shop[i].available = "0"
  items.shop[i].available = tostring(math.random(0,10))
end
 
local ind = {}
for i = 1,#items.shop do
  if items.shop[i].available ~= "0" then
    table.insert(ind,i)
  end
end
 
local function square(x,y,width,height,color)
  if color and gpu.getBackground() ~= color then
    gpu.setBackground(color)
  end
  gpu.fill(x,y,width,height," ")
end
 
local function drawlist()
  pos_str = {}
  local yPos = 8
  for i = 1,11 do
    local i = drawFrom + i
    if items.shop[ind[i]] then
      gpu.setForeground(0xFFFFFF)
      table.insert(pos_str,{yPos,ind[i]})
      buffer.drawText(5,yPos,0xFFFFFF,items.shop[ind[i]].text)
      buffer.drawText(65,yPos,0xFFFFFF,items.shop[ind[i]].price)
      if tonumber(items.shop[ind[i]].available) > 0 then
        buffer.drawText(45,yPos,0xFFFFF,items.shop[ind[i]].available)
      else
        buffer.drawText(45,yPos,0xFFFFFF,"-")
      end
    end
    yPos = yPos + 001
  end
end
 

 

function getJBQty()
    local JBqty = 0
    local inventorySize = 36
    local slot = {}
    for i = 1, inventorySize do
        slot[i] = casino.container.getStackInSlot (i)
        if slot[i] ~= nil then
            if slot[i].display_name == "Железный блок" or slot[i].display_name == "Block of Iron" then
                JBqty = JBqty + slot[i].qty
            end
        end
    end
    return JBqty
end
--os.execute("cls")
local function drawStatic()
    buffer.setResolution(76,24)
    drawRectangleWithCenterText(1, 1, 76, 24, settings.TITLE, 0x1a1a1a, 0x1a1a1a)
    buffer.drawText(7, 6, 0xff381a, 'Имя предмета                        Доступно             Цена')
    buffer.drawText(4, 5, 0xFFFFFF, '┌────────────────────────────────────────────────────────────────────┐')
    buffer.drawText(4, 6, 0xFFFFFF, '│')
    buffer.drawText(4, 7, 0xFFFFFF, '├────────────────────────────────────────────────────────────────────')
    buffer.drawText(4, 8, 0xFFFFFF, '│')
    buffer.drawText(4, 9, 0xFFFFFF, '│')
    buffer.drawText(4, 10, 0xFFFFFF, '│')
    buffer.drawText(4, 11, 0xFFFFFF, '│')
    buffer.drawText(4, 12, 0xFFFFFF, '│')
    buffer.drawText(4, 13, 0xFFFFFF, '│')
    buffer.drawText(4, 14, 0xFFFFFF, '│')
    buffer.drawText(4, 15, 0xFFFFFF, '│')
    buffer.drawText(4, 16, 0xFFFFFF, '│')
    buffer.drawText(4, 17, 0xFFFFFF, '│')
    buffer.drawText(4, 18, 0xFFFFFF, '│')
    buffer.drawText(4, 19, 0xFFFFFF, '│')
    buffer.drawText(4, 20, 0xFFFFFF, '│')
    buffer.drawText(4, 21, 0xFFFFFF, '│')
    buffer.drawText(73, 6, 0xFFFFFF, '│')
    buffer.drawText(73, 7, 0xFFFFFF, '┤')
    buffer.drawText(73, 8, 0xFFFFFF, '│')
    buffer.drawText(73, 9, 0xFFFFFF, '│')
    buffer.drawText(73, 10, 0xFFFFFF, '│')
    buffer.drawText(73, 11, 0xFFFFFF, '│')
    buffer.drawText(73, 12, 0xFFFFFF, '│')
    buffer.drawText(73, 13, 0xFFFFFF, '│')
    buffer.drawText(73, 14, 0xFFFFFF, '│')
    buffer.drawText(73, 15, 0xFFFFFF, '│')
    buffer.drawText(73, 16, 0xFFFFFF, '│')
    buffer.drawText(73, 17, 0xFFFFFF, '│')
    buffer.drawText(73, 18, 0xFFFFFF, '│')
    buffer.drawText(73, 19, 0xFFFFFF, '│')
    buffer.drawText(73, 20, 0xFFFFFF, '│')
    buffer.drawText(73, 21, 0xFFFFFF, '│')
    buffer.drawText(4, 22, 0xFFFFFF,'└────────────────────────────────────────────────────────────────────┘')
    buffer.drawText(34, 2, 0xFFFFFF, '└──────────┘')
    buffer.drawText(1, 1, 0xFFFFFF, '┌────────────────────────────────┐──────────')
    buffer.drawText(45, 1, 0xFFFFFF, '┌─────────────┬────────────────┐')
    buffer.drawText(1, 2, 0xFFFFFF, '│')
    buffer.drawText(1, 3, 0xFFFFFF, '│')
    buffer.drawText(1, 4, 0xFFFFFF, '│')
    buffer.drawText(1, 5, 0xFFFFFF, '│')
    buffer.drawText(1, 6, 0xFFFFFF, '│')
    buffer.drawText(1, 7, 0xFFFFFF, '│')
    buffer.drawText(1, 8, 0xFFFFFF, '│')
    buffer.drawText(1, 9, 0xFFFFFF, '│')
    buffer.drawText(1, 10, 0xFFFFFF, '│')
    buffer.drawText(1, 11, 0xFFFFFF, '│')
    buffer.drawText(1, 12, 0xFFFFFF, '│')
    buffer.drawText(1, 13, 0xFFFFFF, '│')
    buffer.drawText(1, 14, 0xFFFFFF, '│')
    buffer.drawText(1, 15, 0xFFFFFF, '│')
    buffer.drawText(1, 16, 0xFFFFFF, '│')
    buffer.drawText(1, 17, 0xFFFFFF, '│')
    buffer.drawText(1, 18, 0xFFFFFF, '│')
    buffer.drawText(1, 19, 0xFFFFFF, '│')
    buffer.drawText(1, 20, 0xFFFFFF, '│')
    buffer.drawText(1, 21, 0xFFFFFF, '│')
    buffer.drawText(1, 22, 0xFFFFFF, '│')
    buffer.drawText(1, 23, 0xFFFFFF, '│')
    buffer.drawText(76, 2, 0xFFFFFF, '│')
 
    buffer.drawText(76, 3, 0xFFFFFF, '┤')
    buffer.drawText(59, 3, 0xFFFFFF, '└')
    buffer.drawText(59, 2, 0xFFFFFF, '│')
    buffer.drawText(60, 3, 0xFFFFFF, '────────────────')
    buffer.drawText(76, 4, 0xFFFFFF, '│')
    buffer.drawText(76, 5, 0xFFFFFF, '│')
    buffer.drawText(76, 6, 0xFFFFFF, '│')
    buffer.drawText(76, 7, 0xFFFFFF, '│')
    buffer.drawText(76, 8, 0xFFFFFF, '│')
    buffer.drawText(76, 9, 0xFFFFFF, '│')
    buffer.drawText(76, 10, 0xFFFFFF, '│')
    buffer.drawText(76, 11, 0xFFFFFF, '│')
    buffer.drawText(76, 12, 0xFFFFFF, '│')
    buffer.drawText(76, 13, 0xFFFFFF, '│')
    buffer.drawText(76, 14, 0xFFFFFF, '│')
    buffer.drawText(76, 15, 0xFFFFFF, '│')
    buffer.drawText(76, 16, 0xFFFFFF, '│')
    buffer.drawText(76, 17, 0xFFFFFF, '│')
    buffer.drawText(76, 18, 0xFFFFFF, '│')
    buffer.drawText(76, 19, 0xFFFFFF, '│')
    buffer.drawText(76, 20, 0xFFFFFF, '│')
    buffer.drawText(76, 21, 0xFFFFFF, '│')
    buffer.drawText(76, 22, 0xFFFFFF, '│')
    buffer.drawText(76, 23, 0xFFFFFF, '│')
    buffer.drawText(1, 24, 0xFFFFFF, '└──────────────────────────────────────────────────────────────────────────┘')
    buffer.drawText(4, 23, 0x43ba0d, 'Авторизован:')
    computer.addUser(casino.container.getInventoryName())
    buffer.drawText(17, 23, 0xff903d, casino.container.getInventoryName())
    buffer.drawText(60, 2, 0x4cb01e, "Баланс ЖБ: ")
    buffer.drawText(71, 2, 0xff903d, getJBQty())
    buffer.drawText(35, 1, 0x46c8e3, 'Error Shop')
    buffer.drawText(36, 4,0xFFFFFF , 'Магазин')   
    drawlist()
    os.sleep(0.001)
    if (state.devMode) then
        writeCenter(158, 1, "{dev}", 0xE700FF)
        writeCenter(160, 2, "X", 0xFF0000)
        writeCenter(157, 3, "[LIBS]", 0xE700FF)
    else
        writeCenter(158, 1, "{dev}", 0x78517C)
    end
    buffer.drawChanges()
end

local function drawLibSettings()

    for i = 1, #libs do
        buffer.drawText(51, 5 + i * 2, 0x0000AA, "Скачать  Правка");
        buffer.drawText(68, 5 + i * 2, 0, libs[i].path);
    end
    buffer.drawText(51, 5 + (1 + #libs) * 2, 0xff0000, "При редактировании, компьютер не будет защищен от других игроков!");
    buffer.drawText(51, 6 + (1 + #libs) * 2, 0xff0000, "Изменения вступят в силу после перезагрузки!");
    buffer.drawChanges()
end

local function drawDynamic()
    if state.selection == 0 then
        drawLibSettings()
        return
    end
    local selection = games[state.selection]
    local gameImgPath = "/home/images/games_logo/" .. selection.image
    casino.downloadFile(REPOSITORY .. "/resources/images/games_logo/" .. selection.image, gameImgPath)
    writeCenter(133, 7, selection.title, 0x000000)
    drawBigText(102, 9, (selection.description or " ") .. "\n \n" .. "Разработчик: " .. selection.author)

    for i = 1, #games do
        local bgColor = selection == games[i] and 0xA890AA or 0xE3E3E3
    end

    local currentCurrency = casino.getCurrency()
    if state.currencyDropdown then
        local currencyLen = #currencies
        for i = 1, currencyLen do
            drawCurrency(2, 43 - 4 * (currencyLen - i), currencies[i], currencies[i] == currentCurrency)
        end
    end
    drawRectangleWithCenterText(2, 46, 46, 1, "Текущая валюта", 0x431148, 0xFFFFFF)
    drawCurrency(2, 47, currentCurrency)
    buffer.drawText(40, 48, 0, "Сменить")

    if (state.devMode) then
        drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
    else
        if selection.available then
            drawRectangleWithCenterText(51, 40, 50, 5, "Играть", 0x431148, 0xffffff)
        else
            drawRectangleWithCenterText(51, 40, 50, 5, "Временно недоступно", 0x433b44, 0xffffff)
        end
    end
    buffer.drawChanges()
end

local function removeUsers()
    local users = table.pack(computer.users())
    for i = 1, #users do
        if not isAdmin(users[i]) then
            computer.removeUser(users[i])
        end
    end
end

local function onPimPlayerOff(_, name)
    SHOULD_INTERRUPT = true
end

local function handlePim()
    if casino.container.getInventoryName() == 'pim' then
        removeUsers()
        
        buffer.setResolution(76,24)
        buffer.drawChanges()
        local frame = 0
        while casino.container.getInventoryName() == 'pim' do
            if frame < 25 then
                for i = 1, 5 do
                    frame = frame + 1
                    buffer.drawRectangle(1, 1, 76, 24, 0x1a1a1a, 0x0, ' ')
                    buffer.drawText(34, 3, 0x4cb01e, 'OC Магазин')
                    buffer.drawText(26, 6, 0xff903d, 'Встаньте на PIM чтобы войти')
                    buffer.drawRectangle(32, 9, 12, 6, 0x101010, 0x0, ' ')
                    buffer.drawText(31, 8, 0x46c8e3, '⡏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹')
                    buffer.drawText(31, 9, 0x46c8e3, '⡇ ⡏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹ ⢸')
                    buffer.drawText(31, 10, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 11, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 12, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 13, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 14, 0x46c8e3, '⡇ ⣇⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸ ⢸')
                    buffer.drawText(31, 15, 0x46c8e3, '⣇⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸')
                    buffer.drawText(28, 17, 0xFFFFFF, 'Валюта: Железные блоки')
                    buffer.drawText(34, 24, 0x000000, 'By Tumko')
                    buffer.drawChanges()
                    
                    os.sleep(0.001)
                end
            else
                frame = frame + 5
                os.sleep(0.001)
            end
            if frame > 150 then
                frame = 0
            end
        end
        computer.addUser(casino.container.getInventoryName())
                    buffer.drawRectangle(1, 1, 76, 24, 0x1a1a1a, 0x0, ' ')
                    buffer.drawText(34, 3, 0x4cb01e, 'OC Магазин')
                    buffer.drawText(26, 6, 0xff903d, 'Встаньте на PIM чтобы войти')
                    buffer.drawRectangle(32, 9, 12, 6, 0x101010, 0x0, ' ')
                    buffer.drawText(31, 8, 0x46c8e3, '⡏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹')
                    buffer.drawText(31, 9, 0x46c8e3, '⡇ ⡏⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹ ⢸')
                    buffer.drawText(31, 10, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 11, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 12, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 13, 0x46c8e3, '⡇ ⡇          ⢸ ⢸')
                    buffer.drawText(31, 14, 0x46c8e3, '⡇ ⣇⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸ ⢸')
                    buffer.drawText(31, 15, 0x46c8e3, '⣇⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸')
                    buffer.drawText(28, 17, 0xFFFFFF, 'Валюта: Железные блоки')
                    buffer.drawText(33, 23, 0xFFFFFF, 'Авторизация')
                    buffer.drawText(34, 24, 0x000000, 'By Tumko')
                    buffer.drawChanges()
        os.sleep(0.001)
        drawStatic()
        drawDynamic()
        buffer.drawChanges()
    end
end
local function magz()
  local e = {event.pull(1)}
  if e[1] == "key_down" then
    if e[4] == 29 then
      run = false
    elseif e[4] == 200 then
      scroll("+")
    elseif e[4] == 208 then
      scroll("-")
    end
  elseif e[1] == "scroll" then
    scroll(e[5])
  elseif e[1] == "touch" then
    drawlist()   
    gpu.set(1,1,e[3].."  "..e[4].." ")
    choice = false
    for i = 1,#pos_str do
      if e[3] <= 77 and e[4] == pos_str[i][1] then
        choice = pos_str[i][2]
        break
      end
    end
    if choice then
      drawlist()
      gpu.set(10,1,"choice = "..choice.."  ")
      square(1,e[4],77,1,0xDEDE6C)
      gpu.setForeground(0x3366CC)
      gpu.set(4,e[4],items.shop[choice].text)
      gpu.set(54,e[4],items.shop[choice].price)
      if tonumber(items.shop[choice].available) > 0 then
        gpu.set(64,e[4],items.shop[choice].available)
      else
        gpu.set(64,e[4],"-")
      end
    end
  end
end


local function initLauncher()
    for i = 1, #requiredDirectories do
        shell.execute("md " .. requiredDirectories[i])
    end
    for i = 1, #libs do
        casino.downloadFile(libs[i].url, libs[i].path)
    end
    games = require("games")
    currencies = require("currencies")
    image = require("image")
    buffer = require("doubleBuffering")
    colorlib = require("color")
    casino.setCurrency(currencies[1])
end

initLauncher()
buffer.flush()
drawStatic()
drawDynamic()

if settings.PAYMENT_METHOD == 'PIM' then event.listen('player_off', onPimPlayerOff) end

while true do
    :: continue :: -- В Lua отсутствует ключевое слово continiue
    local e, _, x, y, _, p = event.pull(1)
    if e == "touch" then
        if state.devMode and not isAdmin(p) then
            goto continue
        end

        -- Currency
        if state.currencyDropdown and state.selection > 0 then
            if x >= 2 and x <= 46 and  y % 4 ~= 2 then
                local currencyId = math.floor((y - (47 - 4 * #currencies)) / 4 + 1)
                if currencyId > 0 and currencyId <= #currencies then
                    casino.setCurrency(currencies[currencyId])
                end
            end
            state.currencyDropdown = false
            drawDynamic()
            goto continue
        elseif x >= 2 and y >= 46 and x <= 92 and y <= 50 and state.selection > 0 then
            state.currencyDropdown = true
            drawDynamic()
        end

        -- Left menu buttons
        if (x >= 2 and x <= 47 and y >= 7 and ((y - 2) % 4)) and state.selection > 0 then
            local selection = math.floor((y - 3) / 4)
            if (selection <= #games) then
                state.selection = selection
                drawDynamic()
            end
        end

        -- Run/Update button
        if (x >= 51 and y >= 40 and x <= 100 and y <= 44) and state.selection > 0 then
            local selection = games[state.selection]
            if state.devMode then
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x5B5B5B, 0xffffff)
                buffer.drawChanges()
                
                drawRectangleWithCenterText(51, 40, 50, 5, "Обновить", 0x431148, 0xffffff)
                drawDynamic()
            else
                if selection.available then
                    casino.downloadFile(REPOSITORY .. "/apps/" .. selection.file, "/home/apps/" .. selection.file)
                    CURRENT_APP = selection.title
                    local result, errorMsg = pcall(loadfile("/home/apps/" .. selection.file))
                    CURRENT_APP = nil
                    casino.gameIsOver()
                    drawStatic()
                    drawDynamic()
                end
            end
        end

        -- Lib buttons
        if state.devMode and state.selection == 0 and y >= 7 and y % 2 == 1 then
            local lib = libs[math.floor((y - 7) / 2) + 1]
            -- Download
            if lib and x >= 51 and x <= 57 then
                buffer.drawText(51, y, 0xAAAAAA, "Скачать");
                buffer.drawChanges()
                casino.downloadFile(lib.url, lib.path, true)
                buffer.drawText(51, y, 0x0000AA, "Скачать");
                buffer.drawChanges()
            end
            -- Edit
            if lib and x >= 60 and x <= 65 then
                local component = require("component")
                component.gpu.setBackground(0);
                component.gpu.setForeground(0xffffff);
                shell.execute("edit " .. lib.path)
                drawStatic()
                drawDynamic()
            end
        end

        -- Dev mode button
        if x >= 157 and y == 1 and isAdmin(p) then
            state.devMode = not state.devMode
            state.selection = 1
            drawStatic()
            drawDynamic()
        end

        -- Reset button
        if x == 159 and y == 2 and state.devMode then
            shell.execute("reboot")
        end

        -- Libs configuration
        if x >= 156 and y == 3 and state.devMode then
            state.selection = 0
            drawStatic()
            drawDynamic()
        end
    end
    if settings.PAYMENT_METHOD == 'PIM' then handlePim() end
end

--123123
function fieldSymbolInput:new(x, y, lengthField, cursorSymbol, customInitTextOnField, canInputOnlyNumbers)
    local obj = {}
    obj.onFocusedStatus = false
    obj.debugStatus = false
    obj.x = x
    obj.y = y
    obj.lengthField = lengthField
    obj.cursorSymbol = cursorSymbol
    obj.savedText = ""
    obj.xPosC = obj.x + 1
    obj.signalHandler = signalHandler
    obj.canFocused = false
    obj.canInputOnlyNumbers = canInputOnlyNumbers == nil and false or canInputOnlyNumbers
    
    obj.backgroundColor = 0xb4b4b4

    obj.customInitTextOnField = tostring(customInitTextOnField)

    local privateVariable = {}

    privateVariable.xPosC = obj.x + 1
    privateVariable.xWithLengthField = obj.x + obj.lengthField

    function obj:changeOnFocusedStatus(status)
        self.onFocusedStatus = status
    end

    function obj:dropFocused(signal)
        if signal[3] >= 2 + privateVariable.xWithLengthField and signal[3] <= 4 + privateVariable.xWithLengthField then
            self.onFocusedStatus = false
        end
    end

    function obj:drawCrossButton()
        -----СЃРёРІРѕР» X РЅР° РєРЅРѕРїРєРµ СЃС‚РёСЂР°РЅРёСЏ-------- 0x343a40
        gpuSet(self.x + self.lengthField + 2, self.y, " Г— ", 0x343a40, 0x0d6efd)
        -----СЃРёРІРѕР» X РЅР° РєРЅРѕРїРєРµ СЃС‚РёСЂР°РЅРёСЏ-------
    end
    function obj:drawInit()
        --------------
        gpuFill(self.x, self.y, 2 + self.lengthField, 1, " ", self.backgroundColor)
        gpuSet(1 + self.x, self.y, self.customInitTextOnField, self.backgroundColor, 0x212529)
        ---------------0x212529
        self:drawCrossButton()
    end

    obj:drawInit()


    function obj:customMatch(symbol)
        if not self.canInputOnlyNumbers then
            local result = symbol:match("^[A-Za-z0-9Рђ-РЇ-Р°-СЏ -_#&]")
            return result == nil and (symbol == "]" and symbol or (symbol == "[" and symbol or (symbol == "-" and symbol or nil))) or result
        end
        if tonumber(self.savedText == "" and 0 or self.savedText) < 100 then
            return symbol:match("^[0-9]")
        end
        return nil
    end

    function obj:blinkCrossButton()
        gpuSet((3) + (self.lengthField) + self.x,  self.y, "Г—", 0x343a40, 0x00b600)
        sleep(0.001)
        gpuSet((3) + (self.lengthField) + self.x,  self.y, "Г—", 0x343a40, 0x0d6efd)
    end

    function obj:drawCursor()
        gpu.setBackground(self.backgroundColor)
        gpu.setForeground(0xffc107)
        gpu.set(self.xPosC, self.y, self.cursorSymbol)
    end

    function obj:blinkCursor()
        gpu.setBackground(self.backgroundColor)
        gpu.setForeground(0x00b600)
        gpu.set(self.xPosC, self.y, self.cursorSymbol)
        sleep(0.1)
        gpu.setForeground(0xffc107)
        gpu.set(self.xPosC, self.y, self.cursorSymbol)
    end
    
    function obj:reDrawText(text)
        gpuFill(self.x, self.y, 2 + self.lengthField, 1, " ", self.backgroundColor)
        gpuSet(self.x + 1, self.y, tostring(text), self.backgroundColor, 0x212529)
    end

    function obj:modifySavedTextAndPreCalcCursor(text)
        self.savedText = text
        self.xPosC = self.x + unicode.len(self.savedText) + 1
        self:reDrawText(self.savedText)
    end

    function obj:reDrawTextWithCursor(text)
        gpuFill(self.x, self.y, 2 + self.lengthField, 1, " ", self.backgroundColor)
        gpuSet(self.x + 1, self.y, tostring(text), self.backgroundColor, 0x212529)
        self:drawCursor()
    end

    function obj:reDrawTextWithCursorAndCross(text)
        self:reDrawTextWithCursor(text)
        self:drawCrossButton()
    end

    function obj:lenSavedText()
        return unicode.len(self.savedText)
    end

    function obj:eventTrap(signal)
        if signal[1] == "touch" then
            if signal[3] >= 2 + privateVariable.xWithLengthField and signal[3] <= 4 + privateVariable.xWithLengthField then --РїСЂРѕР¶Р°Р» X, РѕС‚С‡РёСЃС‚РёС‚СЊ
                obj:blinkCrossButton()
                self.xPosC = self.x + 1
                self.savedText = ""
                self:reDrawTextWithCursor("")
                obj:debug(signal)
                -- return "erase"
            end
            if signal[3] <= self.lengthField and signal[3] >= 4 + privateVariable.xWithLengthField or signal[4] ~= self.y then 
                return "focusedDroped"
            end
        elseif signal[1] == "key_up" and signal[1] ~= "key_down" then
            local char, sChar = signal[3], signal[4]
            local TextLen = self:lenSavedText()
            local symbol = unicode.char(char)
            if signal[3] == 127 or signal[4] == 211 then --РїСЂРѕР¶Р°Р» delete, РѕС‚С‡РёСЃС‚РёС‚СЊ
                self:blinkCrossButton()
                self.xPosC = self.x + 1
                self.savedText = ""
                self:reDrawTextWithCursor("")
                obj:debug(signal)
                -- return "erase"
            end
            if self:customMatch(symbol) ~= nil and TextLen ~= self.lengthField then
                if self.xPosC == 1 + self.x then -- РїРёС€Сѓ СЃРёРјРІРѕР» РІ СЃР°РјРѕРј РєРѕРЅС†Рµ СЃС‚СЂРѕРєРё
                    local afterCur = unicode.sub(self.savedText, 1 + self.x - self.xPosC, TextLen)
                    self.xPosC = self.xPosC + 1
                    self.savedText = symbol .. afterCur
                    self:reDrawTextWithCursor(self.savedText)
                    return true

                elseif self.xPosC ~= self.x and 1 + self.xPosC >= 1 + self.x + unicode.len(self.savedText) then -- РџСЂРѕРІРµСЂРєР°, РЅР°С…РѕРґРёС‚СЃСЏ Р»Рё РєСѓСЂСЃРѕСЂ РІ РЅР°С‡Р°Р»Рµ СЃС‚СЂРѕРєРё Рё СЃРёРјРІРѕР» С‚РµРєСЃС‚
                    self.xPosC = self.xPosC + 1
                    self.savedText = self.savedText .. unicode.char(signal[3])
                    self:reDrawTextWithCursor(self.savedText)
                    return true

                elseif self.xPosC >= 1 + self.x and self.xPosC <= 1 + self.x + TextLen then -- РїРёС€Сѓ СЃРёРјРІРѕР» РІ С†РµРЅС‚СЂРµ СЃС‚СЂРѕРєРё                    
                    self.savedText = unicode.sub(self.savedText, 1, self.xPosC - 1 - self.x) .. symbol .. unicode.sub(self.savedText, self.xPosC - self.x, TextLen)
                    self.xPosC = self.xPosC + 1
                    self:reDrawTextWithCursor(self.savedText)
                    return true
                end
            end
            if signal[1] == "key_up" and signal[4] == 28 then
                return "focusedDroped"
            end
        elseif signal[1] ~= "key_up" and signal[1] == "key_down" then
            if signal[4] == 205 and self.xPosC <= self:lenSavedText() + self.x and self.xPosC ~= 1 + self.x + self.lengthField then -- 205 СЃС‚СЂРµР»РєР° РІ РїСЂР°РІРѕ
                self.xPosC = self.xPosC + 1 -- РЎС‚СЂРµР»РєР° РІ РїСЂР°РІРѕ, РєСѓСЂСЃРѕСЂ РґРІРёРіР°РµС‚СЃСЏ РІ РїСЂР°РІРѕ.
                self:reDrawTextWithCursor(self.savedText)
            elseif signal[4] == 203 and self.xPosC >= 2 + self.x then -- 203 СЃС‚СЂРµР»РєР° РІ Р»РµРІРѕ
                self.xPosC = self.xPosC - 1 -- РЎС‚СЂРµР»РєР° РІ Р»РµРІРѕ, РєСѓСЂСЃРѕСЂ РґРІРёРіР°РµС‚СЃСЏ РІ Р»РµРІРѕ.
                self:reDrawTextWithCursor(self.savedText)
            end
            if signal[3] and signal[4] == 14 then --РЎС‚РёСЂР°Р» РѕС‡РєР°
                if self.xPosC >= 1 + self.x then 
                    local TextLen = self:lenSavedText()
                    if self.xPosC == 1 + self.x + TextLen and TextLen > 0 then
                        if self.xPosC ~= 1 + self.x then self.xPosC = self.xPosC - 1 end
                            self.savedText = unicode.sub(self.savedText, 1, TextLen - 1)
                            self:reDrawTextWithCursor(self.savedText)
                            if self.savedText == "" then return "erase" end
                            return true

                        elseif self.xPosC >= 3 + self.x and self.xPosC <= self.x + TextLen then
                            self.savedText = unicode.sub(self.savedText, 1, self.xPosC - 2 - self.x)..unicode.sub(self.savedText, self.xPosC - self.x, TextLen)
                            self.xPosC = self.xPosC - 1
                            self:reDrawTextWithCursor(self.savedText)
                            if self.savedText == "" then return "erase" end
                            return true

                        elseif self.xPosC == 2 + self.x then
                            self.savedText = unicode.sub(self.savedText, 2, TextLen)
                            self.xPosC = self.xPosC - 1
                            self:reDrawTextWithCursor(self.savedText)
                            return true
                    end
                    return false
                end
            end
        elseif signal[1] == "clipboard" then
            local stringGeted = tostring(signal[3])
            local stringToPaste = ""
            if unicode.len(stringGeted) > self.lengthField then stringToPaste = unicode.sub(stringGeted, 1, self.lengthField) else stringToPaste = stringGeted end
            self.savedText = stringToPaste
            self:modifySavedTextAndPreCalcCursor(self.savedText)
        end
    end

    function obj:canFocusedToggle(bool)
        self.canFocused = bool
    end

    function obj:isFocused(signal)
        if signal and signal[1] == "touch" and signal[3] >= self.x and signal[3] <= self.x + self.lengthField and signal[4] == self.y then
            return true
        end
        return false
    end

    function obj:isDropFocused(signal)
        if self:eventTrap(signal) == "focusedDroped" then
            return true
        end
        return false
    end
    function obj:onFocused(_SIGNAL, errorText)
        if self:isFocused(_SIGNAL) then
            if self.canFocused then
                self.backgroundColor = 0xf8f9fa
                self:reDrawTextWithCursor(self.savedText)
                local blinkCursorCount = 0
                while true do
                    computer.pushSignal("fakeEvent")
                    blinkCursorCount = blinkCursorCount + 1
                    if blinkCursorCount == 50 then self:blinkCursor() blinkCursorCount = 0 end
                    if self:isDropFocused(self:signalHandler()) then
                        self.backgroundColor = 0xb4b4b4
                        self:reDrawText(tostring(self.savedText))
                        return "focusedDroped"
                    end
                end
            else
                self.backgroundColor = 0xf8f9fa
                self:reDrawText(tostring(errorText)) --"РќР• Р’Р«Р‘Р РђР› Р“Р РЈРџРџРЈ!"
                computer.beep(600, 0.1)
                self.backgroundColor = 0xb4b4b4
                self:reDrawText(tostring(self.customInitTextOnField))
                return
            end
        end
    end


    function obj:debug(signal)
        -- if self.debugStatus then
        --     local x = 41
        --     gpuFill(abs(x- 1), 1, 50, 8, " ", 0xf8f9fa)
        --     gpuSet(x, 2, tostring(signal[3]), color.white, color.yellow)
        --     gpuSet(x, 3, tostring(signal[4]), color.white, color.yellow)
        --     gpuSet(x, 4, "xPosC: " .. tostring(self.xPosC), color.background, color.yellow)
        --     gpuSet(x, 5, "TextLen: " .. tostring(unicode.len(self.savedText)), color.background, color.red)
        --     gpuSet(x, 6, "savedText: " .. self.savedText, color.background, color.red)
        -- end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end
