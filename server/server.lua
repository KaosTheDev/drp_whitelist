Whitelist = {}
NotWhitelisted = {}

-- Check if player is whitelisted
AddEventHandler('playerConnecting', function(name, setCallback)
    local Identifiers = GetPlayerIdentifiers(source)
    local _source = source
    
    if not has_value(Whitelist, Identifiers[1]) and not has_value(Whitelist, Identifiers[2]) and #NotWhitelisted >= Config.OpenSlots then
        setCallback(_U('not_whitelisted'))
        CancelEvent()
        return
    else
        if not has_value(Whitelist, Identifiers[1]) and not has_value(Whitelist, Identifiers[2]) then
            table.insert(NotWhitelisted, {source = source, steamid = Identifiers[1]})
            
            for i = 1, #NotWhitelisted, 1 do
                if NotWhitelisted[i].steamid == Identifiers[1] and NotWhitelisted[i].source ~= source then
                    table.remove(NotWhitelisted, i)
                    break
                end
            end
            
            SetTimeout(240000, function()
                checkSpawned(_source)
            end)
        end
    end

end)

AddEventHandler('playerDropped', function()
    local SteamID = GetPlayerIdentifiers(source)[1]
    local _source = source

    print(source)
    
    for i = 1, #NotWhitelisted, 1 do
        if NotWhitelisted[i].steamid == SteamID then
            table.remove(NotWhitelisted, i)
            break
        end
    end
end)

function checkSpawned(source)
    if GetPlayerName(source) == nil then
        if has_value(NotWhitelisted, source) then
            for i = 1, #NotWhitelisted, 1 do
                if NotWhitelisted[i].source == source then
                    table.remove(NotWhitelisted, i)
                    break
                end
            end
        end
    end
end

-- Add Whitelist Command
TriggerEvent('es:addGroupCommand', 'addwl', "mod", function(source, args, user)
    addToWhitelist(args, source, false)
end, function(source, args, user)
    TriggerClientEvent('chat:addMessage', source, {args = {"^1SYSTEM ", _U('permissions')}})
end, {help = _U('addwl_help_text'), params = {{name = "identifier", help = _U('awl_help_text_param')}}})

-- Remove Whitelist Command
TriggerEvent('es:addGroupCommand', 'removewl', "mod", function(source, args, user)
    removeFromWhitelist(args, source, false)
end, function(source, args, user)
    TriggerClientEvent('chat:addMessage', source, {args = {"^1SYSTEM ", "Insufficienct permissions!"}})
end, {help = _U('removewl_help_text'), params = {{name = "identifier", help = _U('awl_help_text_param')}}})

-- Rcon Add Whitelist Command (Supports Ace)
RegisterCommand("rconaddwl", function(source, args, rawCommand)
    addToWhitelist(args, "", true)
end, true)

-- Rcon Remove Whitelist Command (Supports Ace)
RegisterCommand("rconremovewl", function(source, args, rawCommand)
    removeFromWhitelist(args, "", true)
end, true)

-- Load Whitelist
function initWhitelist()
    MySQL.Async.fetchAll('SELECT identifier FROM whitelist', {}, function(result)
        for i = 1, #result, 1 do
            table.insert(Whitelist, tostring(result[i].identifier):lower())
        end
    end)
end

-- Add whitelist to mysql
function addWhitelistToMysql(identifier)
    MySQL.Async.execute('INSERT INTO whitelist (identifier) VALUES (@identifier)', {
        ['@identifier'] = identifier
    })
end

-- Remove whitelist from mysql
function removeWhitelistFromMysql(identifier)
    MySQL.Async.execute('DELETE FROM whitelist WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
end

-- Add to whitelist function
function addToWhitelist(args, source, rcon)
    if args[1] then
        
        -- Converts args[1] to lowcase
        local id = tostring(args[1]):lower()
        
        -- Check if ID includes Steam
        if string.find(id, "steam:") then
            
            -- Removes Steam: from ID
            local StreamID = string.gsub(id, "steam:", "")
            
            -- Check length of SteamID64 should be 17
            if string.len(StreamID) == 17 then
                
                -- Converts SteamID to hex and add's steam: in front again
                local HexSteamID = "steam:" .. string.format('%x', StreamID)
                
                -- Check if ID Whitelisted
                if not has_value(Whitelist, HexSteamID) then
                    
                    -- Adds ID to whitelist Mysql and Table
                    addWhitelistToMysql(HexSteamID)
                    table.insert(Whitelist, HexSteamID)
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^2WHITELIST ", _U('added_to_whitelist', HexSteamID)}})
                    else
                        RconPrint("[Whitelist] Added ID to whitelist " .. HexSteamID .. " \n")
                    end
                
                -- ID found in table
                else
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('already_whitelisted')}})
                    else
                        RconPrint("[Whitelist] The ID is already whitelisted\n")
                    end
                
                end
            
            -- Not a valid SteamID
            else
                
                if not rcon then
                    TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('not_valid_steamid')}})
                else
                    RconPrint("[Whitelist] Not a valid Steam ID\n")
                end
            
            end
        
        -- Check if ID includes License
        elseif string.find(id, "license:") then
            
            -- Removes License: from ID
            local License = string.gsub(id, "license:", "")
            
            -- Check length with out license: should be 40
            if string.len(License) == 40 then
                
                -- Check if ID is whitelisted
                if not has_value(Whitelist, id) then
                    
                    -- Adds ID to whitelist MySQL and Table
                    addWhitelistToMysql("license:" .. License)
                    table.insert(Whitelist, id)
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^2WHITELIST ", _U('added_to_whitelist', id)}})
                    else
                        RconPrint("[Whitelist] Added ID to whitelist " .. id .. " \n")
                    end
                
                -- ID found in table
                else
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('already_whitelisted')}})
                    else
                        RconPrint("[Whitelist] The ID is already whitelisted\n")
                    end
                
                end
            
            -- Not a valid License ID
            else
                
                if not rcon then
                    TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('not_valid_license')}})
                else
                    RconPrint("[Whitelist] Not a valid License ID\n")
                end
            
            end
        
        -- If Steam or License is not found
        else
            if not rcon then
                TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('invalid_id')}})
            else
                RconPrint("[Whitelist] Invalid ID remember steam: or license:\n")
            end
        end
    
    -- No identifier
    else
        if not rcon then
            TriggerClientEvent('chat:addMessage', source, {args = {"^1SYSTEM ", _U('invalid_entry')}})
        else
            RconPrint("[Whitelist] Identifier Missing\n")
        end
    end
end

-- Remove from whitelist function
function removeFromWhitelist(args, source, rcon)
    if args[1] then
        
        -- Converts args[1] to lowcase
        local id = tostring(args[1]):lower()
        
        -- Check if ID includes Steam
        if string.find(id, "steam:") then
            
            -- Removes Steam: from ID
            local StreamID = string.gsub(id, "steam:", "")
            
            -- Check length of SteamID64 should be 17
            if string.len(StreamID) == 17 then
                
                -- Converts SteamID to hex and add's steam: in front again
                local HexSteamID = "steam:" .. string.format('%x', StreamID)
                
                -- Check if ID Whitelisted
                if has_value(Whitelist, HexSteamID) then
                    
                    -- Removes ID to whitelist Mysql and Table
                    removeWhitelistFromMysql(HexSteamID)
                    
                    --Remove from Table
                    for i = 1, #Whitelist, 1 do
                        if Whitelist[i] == HexSteamID then
                            table.remove(Whitelist, i)
                            break
                        end
                    end
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('removed_from_whitelist', HexSteamID)}})
                    else
                        RconPrint("[Whitelist] ID removed from whitelist " .. HexSteamID .. "\n")
                    end
                
                -- ID found in table
                else
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('is_not_whitelisted')}})
                    else
                        RconPrint("[Whitelist] ID is not whitelisted\n")
                    end
                
                end
            
            -- Check length of SteamID Hex Format should be 15
            elseif string.len(StreamID) == 15 then
                
                if has_value(Whitelist, id) then
                    
                    -- Check if ID Whitelisted
                    removeWhitelistFromMysql(id)
                    
                    --Remove from Table
                    for i = 1, #Whitelist, 1 do
                        if Whitelist[i] == id then
                            table.remove(Whitelist, i)
                            break
                        end
                    end
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('removed_from_whitelist', id)}})
                    else
                        RconPrint("[Whitelist] ID removed from whitelist " .. id .. "\n")
                    end
                
                -- ID found in table
                else
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('is_not_whitelisted')}})
                    else
                        RconPrint("[Whitelist] ID is not whitelisted\n")
                    end
                
                end
            
            -- Not a valid SteamID
            else
                if not rcon then
                    TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('not_valid_steamid')}})
                else
                    RconPrint("[Whitelist] Not a valid SteamID\n")
                end
            end
        
        -- Check if ID includes License
        elseif string.find(id, "license:") then
            
            -- Removes License: from ID
            local License = string.gsub(id, "license:", "")
            
            -- Check length with out license: should be 40
            if string.len(License) == 40 then
                
                -- Check if ID is whitelisted
                if has_value(Whitelist, id) then
                    
                    -- Removes ID to whitelist MySQL and Table
                    removeWhitelistFromMysql(id)
                    
                    --Remove from Table
                    for i = 1, #Whitelist, 1 do
                        if Whitelist[i] == id then
                            table.remove(Whitelist, i)
                            break
                        end
                    end
                    
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('removed_from_whitelist', id)}})
                    else
                        RconPrint("[Whitelist] ID removed from whitelist " .. id .. "\n")
                    end
                
                -- ID found in table
                else
                    if not rcon then
                        TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('is_not_whitelisted')}})
                    else
                        RconPrint("[Whitelist] ID is not whitelisted\n")
                    end
                end
            
            -- Not a valid License ID
            else
                if not rcon then
                    TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('not_valid_license')}})
                else
                    RconPrint("[Whitelist] Not a valid License ID\n")
                end
            end
        
        else
            
            if not rcon then
                TriggerClientEvent('chat:addMessage', source, {args = {"^1WHITELIST ", _U('invalid_id')}})
            else
                RconPrint("[Whitelist] Invalid ID remember steam: or license:\n")
            end
        
        end
    
    -- ID found in table
    else
        
        if not rcon then
            TriggerClientEvent('chat:addMessage', source, {args = {"^1SYSTEM ", _U('invalid_entry')}})
        else
            RconPrint("[Whitelist] Identifier Missing\n")
        end
    
    end
end

-- Validate if table got identifier
function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    
    return false
end

-- Loads Whitelist when MySQL is ready
MySQL.ready(function()
    initWhitelist()
end)
