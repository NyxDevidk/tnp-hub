-- Orion UI: TNP Weapon Inspector (Enhanced) - Apenas leitura
-- Usa: ReplicatedStorage.ACS_Engine.ToolStorage
-- Versão melhorada com mais recursos de inspeção

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "TNP Tools — Weapon Inspector Pro",
    HidePremium = true,
    SaveConfig = false
})

local TabWeapons = Window:MakeTab({ Name = "Weapons", Icon = "rbxassetid://4483345998" })
local TabStats = Window:MakeTab({ Name = "Stats Comparison", Icon = "rbxassetid://4483345998" })
local TabExperimental = Window:MakeTab({ Name = "⚠️ Experimental", Icon = "rbxassetid://7072707888" })
local TabTools = Window:MakeTab({ Name = "Tools", Icon = "rbxassetid://6026568192" })
local TabMisc = Window:MakeTab({ Name = "Misc", Icon = "rbxassetid://7072723210" })
local TabESP = Window:MakeTab({ Name = "ESP", Icon = "rbxassetid://6026572475" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local okRoot, root = pcall(function() return ReplicatedStorage:WaitForChild("ACS_Engine"):WaitForChild("ToolStorage") end)
if not okRoot or not root then
    TabWeapons:AddParagraph("Erro", "Não encontrei ReplicatedStorage.ACS_Engine.ToolStorage no jogo.")
    OrionLib:Init()
    return
end

-- Armas alvo (conforme saída que você enviou)
local targetNames = {
    "BAR", "BFG 50", "Ar Azul Lunetado", "C9", "Ar10 Tambor", "HK416A5", "M249-DOURADA",
    "MG42", "RPD", "MiniGun", "FAL MATUE", "Fal pmerj", "G3 padrao", "G3 CAÇA PEIXE",
    "M82A1", "G3 VERMELHO", "AR Luneta", "G3 DA ALTA", "Galil Ace 52", "IA2",
    "Imbel 5.56 IA2", "Micro draco", "AR PEIXAO", "FAL FLAMENGO", "FAL Stock", "G3ZAO",
    "Glock 17", "AR15 MÉDIA", "AR-15 Pega tudo", "MadSen", "Glock Framengo",
    "G3 Perneta lunetado", "Fal de 30", "Fal Serrinha", "Fal Para Tudo", "Fal Coronha",
    "Ar LGP", "HK416", "Ar Azul", "Ak do Patrão", "M870", "Ak de guerra Terceiro",
    "Scar 17", "Ak Segundo", "Ak Azul", "AR DE TAMBOR", "AK-74M", "AR TROPA DO CESAR",
    "Fal Aliados", "AWM", "RPK-74M", "G17 Zeus", "TAURUS T4", "M16 Lunetado",
    "AR-15 mira", "AKM", "Ar Zeus", "AK47PRATA", "RPK", "AR TERROR DA ALTA", "Block-1",
    "Glock 17 Aliados", "M110 Blade Runner", "AR-15 Sniper", "AK-47 Gold", "Deagle XRK",
    "TEC-22", "Kolibri", "M4A1", "AR-10 BOLADO", "ParaFal", "AK-47 Escarlate",
    "SIG MCX T1 Escarlate", "Glock De 30", "AR15 Escarlate", "AR-10 SUPERSASS",
    "SVD Dragunov", "G36", "AR 15 PENTE DUPLO", "AR-10A4 Lunetado", "M4A1 Deluxe",
    "Glock 17 Escarlate", "Glock 17 Azul", ".38", "Uzi", "AR10 NERDOLA", "M110 DMR",
    "SIG MCX T1", "AKM Tambor", "T-5000", "Glock 17 MLC", "Barret M107",
    "HK416A5 Silenciada", "AKS-74U", "AR FIEL", "M16A1", "AK FEITA A MAO", "AR CAVEIRA",
    "G3 DE MADEIRA SALOMAO"
}

-- util: safe require (retorna nil se não der)
local function safeRequire(mod)
    if not mod then return nil end
    local ok, res = pcall(function() return require(mod) end)
    if ok then return res end
    return nil
end

-- monta lista de armas reais presentes
local present = {}
for _, name in ipairs(targetNames) do
    local inst = root:FindFirstChild(name)
    if inst then
        table.insert(present, name)
    end
end

if #present == 0 then
    TabWeapons:AddParagraph("Info", "Nenhuma das armas alvo foi encontrada em ToolStorage.")
    OrionLib:Init()
    return
end

-- Estado global
local currentSelection = present[1]
local cachedSettings = {} -- Cache de configurações carregadas

-- ==================== FUNÇÕES UTILITÁRIAS ====================

-- Função: pega ACS_Settings da arma (sem alterar)
local function readACSSettings(weaponName)
    if cachedSettings[weaponName] then
        return cachedSettings[weaponName], nil
    end
    
    local weapon = root:FindFirstChild(weaponName)
    if not weapon then return nil, "Arma não encontrada." end
    local mod = weapon:FindFirstChild("ACS_Settings")
    if not mod then return nil, "ACS_Settings não encontrada." end
    local settings = safeRequire(mod)
    if not settings then return nil, "Falha ao require ACS_Settings (talvez protegido)." end
    
    cachedSettings[weaponName] = settings
    return settings, nil
end

-- Função: retorna caminho completo (lista) para a arma selecionada
local function getWeaponPaths(namesList)
    local collected = {}
    for _, name in ipairs(namesList) do
        local weapon = root:FindFirstChild(name)
        if weapon then
            local function scan(obj, path)
                local current = (path == "" and ("/" .. obj.Name) or (path .. "/" .. obj.Name))
                table.insert(collected, current)
                for _, c in ipairs(obj:GetChildren()) do
                    scan(c, current)
                end
            end
            scan(weapon, "")
        end
    end
    return collected
end

-- Função: formatar valores para exibição
local function formatValue(val)
    local t = typeof(val)
    if t == "table" then
        local items = {}
        for k, v in pairs(val) do
            table.insert(items, tostring(k) .. "=" .. formatValue(v))
        end
        return "{" .. table.concat(items, ", ") .. "}"
    elseif t == "Color3" then
        return string.format("RGB(%d,%d,%d)", val.R*255, val.G*255, val.B*255)
    elseif t == "CFrame" then
        return "CFrame(...)"
    elseif t == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
    else
        return tostring(val)
    end
end

-- Função: serializar tabela completa
local function serializeTable(tbl, indent)
    indent = indent or 0
    local lines = {}
    local spacing = string.rep("  ", indent)
    
    for k, v in pairs(tbl) do
        local key = tostring(k)
        local valType = typeof(v)
        
        if valType == "table" then
            table.insert(lines, spacing .. key .. " = {")
            table.insert(lines, serializeTable(v, indent + 1))
            table.insert(lines, spacing .. "}")
        else
            table.insert(lines, spacing .. key .. " = " .. formatValue(v))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Função: calcular DPS teórico
local function calculateDPS(settings)
    if not settings.ShootRate or not settings.TorsoDamage then return "N/A" end
    local rpm = settings.ShootRate
    local avgDamage = (settings.TorsoDamage[1] + settings.TorsoDamage[2]) / 2
    local dps = (rpm / 60) * avgDamage
    return string.format("%.1f", dps)
end

-- Função: calcular TTK (Time To Kill) - assumindo 100 HP
local function calculateTTK(settings)
    if not settings.ShootRate or not settings.TorsoDamage then return "N/A" end
    local rpm = settings.ShootRate
    local avgDamage = (settings.TorsoDamage[1] + settings.TorsoDamage[2]) / 2
    local shotsToKill = math.ceil(100 / avgDamage)
    local ttk = (shotsToKill - 1) / (rpm / 60)
    return string.format("%.2fs (%d shots)", ttk, shotsToKill)
end

-- ==================== TAB: WEAPONS ====================

TabWeapons:AddLabel("═══════════ Inspeção de Arma ═══════════")

-- Dropdown para escolher arma
local dropdown = TabWeapons:AddDropdown({
    Name = "Selecionar Arma",
    Default = currentSelection,
    Options = present,
    Callback = function(value) 
        currentSelection = value
    end
})

-- Frame para exibir dados básicos
local infoParagraph = TabWeapons:AddParagraph("Dados da Arma", "Clique em 'Carregar Dados' para visualizar ACS_Settings.")

TabWeapons:AddButton({
    Name = "🔍 Carregar Dados Completos",
    Callback = function()
        local set, err = readACSSettings(currentSelection)
        if not set then
            infoParagraph:Set("Dados da Arma", "❌ Erro: " .. tostring(err))
            return
        end
        
        -- Construir informação detalhada
        local lines = {}
        table.insert(lines, "╔══════════════════════════════╗")
        table.insert(lines, string.format("║  %s", currentSelection))
        table.insert(lines, "╚══════════════════════════════╝")
        table.insert(lines, "")
        
        -- Informações gerais
        table.insert(lines, "【 INFORMAÇÕES GERAIS 】")
        if set.gunName then table.insert(lines, "Nome: " .. tostring(set.gunName)) end
        if set.Type then table.insert(lines, "Tipo: " .. tostring(set.Type)) end
        if set.BulletType then table.insert(lines, "Calibre: " .. tostring(set.BulletType)) end
        table.insert(lines, "")
        
        -- Munição
        table.insert(lines, "【 MUNIÇÃO 】")
        if set.Ammo then table.insert(lines, "Capacidade: " .. tostring(set.Ammo)) end
        if set.StoredAmmo then 
            local stored = set.StoredAmmo == math.huge and "∞" or tostring(set.StoredAmmo)
            table.insert(lines, "Munição Reserva: " .. stored)
        end
        if set.MaxStoredAmmo then table.insert(lines, "Máx. Reserva: " .. tostring(set.MaxStoredAmmo)) end
        table.insert(lines, "")
        
        -- Disparo
        table.insert(lines, "【 SISTEMA DE DISPARO 】")
        if set.ShootRate then table.insert(lines, "Cadência: " .. tostring(set.ShootRate) .. " RPM") end
        if set.ShootType then 
            local types = {[1]="Semi", [2]="Burst", [3]="Auto"}
            table.insert(lines, "Modo: " .. (types[set.ShootType] or tostring(set.ShootType)))
        end
        if set.Bullets then table.insert(lines, "Projéteis/Disparo: " .. tostring(set.Bullets)) end
        table.insert(lines, "")
        
        -- Dano
        table.insert(lines, "【 DANO 】")
        if set.HeadDamage then 
            table.insert(lines, string.format("Cabeça: %s-%s", 
                tostring(set.HeadDamage[1]), tostring(set.HeadDamage[2])))
        end
        if set.TorsoDamage then 
            table.insert(lines, string.format("Torso: %s-%s", 
                tostring(set.TorsoDamage[1]), tostring(set.TorsoDamage[2])))
        end
        if set.LimbDamage then 
            table.insert(lines, string.format("Membros: %s-%s", 
                tostring(set.LimbDamage[1]), tostring(set.LimbDamage[2])))
        end
        if set.MinDamage then table.insert(lines, "Dano Mínimo: " .. tostring(set.MinDamage)) end
        if set.DamageFallOf then table.insert(lines, "Queda de Dano: " .. tostring(set.DamageFallOf)) end
        table.insert(lines, "DPS: " .. calculateDPS(set))
        table.insert(lines, "TTK: " .. calculateTTK(set))
        table.insert(lines, "")
        
        -- Balística
        table.insert(lines, "【 BALÍSTICA 】")
        if set.MuzzleVelocity then table.insert(lines, "Velocidade: " .. tostring(set.MuzzleVelocity) .. " m/s") end
        if set.BulletDrop then table.insert(lines, "Queda: " .. tostring(set.BulletDrop)) end
        if set.BulletPenetration then table.insert(lines, "Penetração: " .. tostring(set.BulletPenetration)) end
        table.insert(lines, "")
        
        -- Precisão
        table.insert(lines, "【 PRECISÃO 】")
        if set.MinSpread and set.MaxSpread then
            table.insert(lines, string.format("Dispersão: %.2f - %.2f", set.MinSpread, set.MaxSpread))
        end
        if set.AimSpreadReduction then table.insert(lines, "Redução ADS: " .. tostring(set.AimSpreadReduction) .. "x") end
        table.insert(lines, "")
        
        -- Recuo
        table.insert(lines, "【 RECUO 】")
        if set.camRecoil then
            table.insert(lines, string.format("Câmera (Cima): %s - %s",
                tostring(set.camRecoil.camRecoilUp[1]), tostring(set.camRecoil.camRecoilUp[2])))
        end
        if set.gunRecoil then
            table.insert(lines, string.format("Arma (Cima): %s - %s",
                tostring(set.gunRecoil.gunRecoilUp[1]), tostring(set.gunRecoil.gunRecoilUp[2])))
        end
        if set.AimRecoilReduction then table.insert(lines, "Redução ADS: " .. tostring(set.AimRecoilReduction) .. "x") end
        
        infoParagraph:Set("Dados da Arma", table.concat(lines, "\n"))
    end
})

TabWeapons:AddButton({
    Name = "📋 Copiar Configurações Completas",
    Callback = function()
        local set, err = readACSSettings(currentSelection)
        if not set then
            infoParagraph:Set("Dados da Arma", "❌ Erro: " .. tostring(err))
            return
        end
        
        local output = string.format("-- ACS_Settings: %s\n\n", currentSelection)
        output = output .. serializeTable(set, 0)
        
        if setclipboard then
            pcall(setclipboard, output)
            infoParagraph:Set("Dados da Arma", "✅ Configurações copiadas para clipboard!")
        else
            infoParagraph:Set("Dados da Arma", "❌ Clipboard não disponível no executor.")
        end
    end
})

TabWeapons:AddButton({
    Name = "🗂️ Copiar Estrutura da Arma",
    Callback = function()
        local paths = getWeaponPaths({ currentSelection })
        local output = string.format("-- Estrutura: %s\n-- Total de objetos: %d\n\n", 
            currentSelection, #paths)
        output = output .. table.concat(paths, "\n")
        
        if setclipboard then
            pcall(setclipboard, output)
            infoParagraph:Set("Dados da Arma", "✅ Estrutura copiada para clipboard!")
        else
            infoParagraph:Set("Dados da Arma", "❌ Clipboard não disponível.")
        end
    end
})

-- ==================== TAB: STATS COMPARISON ====================

TabStats:AddLabel("═══════════ Comparação de Armas ═══════════")

local comparisonParagraph = TabStats:AddParagraph("Comparação", "Clique em 'Comparar Todas' para ver estatísticas lado a lado.")

TabStats:AddButton({
    Name = "📊 Comparar Todas as Armas",
    Callback = function()
        local comparison = {}
        table.insert(comparison, "╔══════════════════════════════════════╗")
        table.insert(comparison, "║     COMPARAÇÃO DE ESTATÍSTICAS       ║")
        table.insert(comparison, "╚══════════════════════════════════════╝")
        table.insert(comparison, "")
        
        for _, weaponName in ipairs(present) do
            local set, err = readACSSettings(weaponName)
            if set then
                table.insert(comparison, "━━━━ " .. weaponName .. " ━━━━")
                table.insert(comparison, string.format("Cadência: %s RPM", tostring(set.ShootRate or "N/A")))
                table.insert(comparison, string.format("Dano Torso: %s-%s", 
                    tostring(set.TorsoDamage and set.TorsoDamage[1] or "N/A"),
                    tostring(set.TorsoDamage and set.TorsoDamage[2] or "N/A")))
                table.insert(comparison, string.format("DPS: %s", calculateDPS(set)))
                table.insert(comparison, string.format("TTK: %s", calculateTTK(set)))
                table.insert(comparison, string.format("Munição: %s/%s", 
                    tostring(set.Ammo or "N/A"),
                    set.StoredAmmo == math.huge and "∞" or tostring(set.StoredAmmo or "N/A")))
                table.insert(comparison, "")
            end
        end
        
        comparisonParagraph:Set("Comparação", table.concat(comparison, "\n"))
    end
})

TabStats:AddButton({
    Name = "📈 Copiar Tabela Comparativa (CSV)",
    Callback = function()
        local csv = {"Arma,Cadência,Dano_Min,Dano_Max,DPS,Munição,Velocidade,Penetração"}
        
        for _, weaponName in ipairs(present) do
            local set, err = readACSSettings(weaponName)
            if set then
                local line = string.format("%s,%s,%s,%s,%s,%s,%s,%s",
                    weaponName,
                    tostring(set.ShootRate or ""),
                    tostring(set.TorsoDamage and set.TorsoDamage[1] or ""),
                    tostring(set.TorsoDamage and set.TorsoDamage[2] or ""),
                    calculateDPS(set),
                    tostring(set.Ammo or ""),
                    tostring(set.MuzzleVelocity or ""),
                    tostring(set.BulletPenetration or ""))
                table.insert(csv, line)
            end
        end
        
        if setclipboard then
            pcall(setclipboard, table.concat(csv, "\n"))
            comparisonParagraph:Set("Comparação", "✅ CSV copiado para clipboard!")
        else
            comparisonParagraph:Set("Comparação", "❌ Clipboard não disponível.")
        end
    end
})

-- ==================== TAB: EXPERIMENTAL ====================

TabExperimental:AddLabel("⚠️═════════ ZONA EXPERIMENTAL ═════════⚠️")
TabExperimental:AddParagraph("⚡ AVISO", 
    "Esta aba permite MODIFICAR configurações das armas.\n" ..
    "Use por sua conta e risco!\n" ..
    "Modificações podem resultar em:\n" ..
    "• Kick/Ban do servidor\n" ..
    "• Detecção de anti-cheat\n" ..
    "• Comportamento instável")

local modWeaponSelection = present[1]
local modParagraph = TabExperimental:AddParagraph("Status", "Selecione uma arma e configure os valores abaixo.")

TabExperimental:AddDropdown({
    Name = "🎯 Arma para Modificar",
    Default = modWeaponSelection,
    Options = present,
    Callback = function(value) 
        modWeaponSelection = value
    end
})

TabExperimental:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
TabExperimental:AddLabel("【 MODIFICAÇÕES DE DANO 】")

local newHeadDamage = 100
local newTorsoDamage = 50
local newLimbDamage = 25

TabExperimental:AddSlider({
    Name = "💀 Dano de Cabeça",
    Min = 1,
    Max = 500,
    Default = 100,
    Color = Color3.fromRGB(255, 50, 50),
    Increment = 5,
    Callback = function(value)
        newHeadDamage = value
    end    
})

TabExperimental:AddSlider({
    Name = "🎯 Dano de Torso",
    Min = 1,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 150, 50),
    Increment = 5,
    Callback = function(value)
        newTorsoDamage = value
    end    
})

TabExperimental:AddSlider({
    Name = "🦵 Dano de Membros",
    Min = 1,
    Max = 200,
    Default = 25,
    Color = Color3.fromRGB(255, 200, 50),
    Increment = 5,
    Callback = function(value)
        newLimbDamage = value
    end    
})

TabExperimental:AddButton({
    Name = "✅ Aplicar Modificações de Dano",
    Callback = function()
        local weapon = root:FindFirstChild(modWeaponSelection)
        if not weapon then
            modParagraph:Set("Status", "❌ Arma não encontrada!")
            return
        end
        
        local mod = weapon:FindFirstChild("ACS_Settings")
        if not mod then
            modParagraph:Set("Status", "❌ ACS_Settings não encontrada!")
            return
        end
        
        local success, err = pcall(function()
            local settings = require(mod)
            settings.HeadDamage = {newHeadDamage, newHeadDamage}
            settings.TorsoDamage = {newTorsoDamage, newTorsoDamage}
            settings.LimbDamage = {newLimbDamage, newLimbDamage}
        end)
        
        if success then
            modParagraph:Set("Status", string.format(
                "✅ Dano modificado!\n" ..
                "Cabeça: %d | Torso: %d | Membros: %d",
                newHeadDamage, newTorsoDamage, newLimbDamage))
        else
            modParagraph:Set("Status", "❌ Falha ao modificar: " .. tostring(err))
        end
    end
})

TabExperimental:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
TabExperimental:AddLabel("【 MODIFICAÇÕES DE MUNIÇÃO 】")

local newAmmo = 50
local newStoredAmmo = 210

TabExperimental:AddSlider({
    Name = "📦 Munição no Carregador",
    Min = 1,
    Max = 999,
    Default = 50,
    Color = Color3.fromRGB(100, 200, 255),
    Increment = 1,
    Callback = function(value)
        newAmmo = value
    end    
})

TabExperimental:AddSlider({
    Name = "🔫 Munição de Reserva",
    Min = 0,
    Max = 9999,
    Default = 210,
    Color = Color3.fromRGB(150, 150, 255),
    Increment = 10,
    Callback = function(value)
        newStoredAmmo = value
    end    
})

TabExperimental:AddToggle({
    Name = "♾️ Munição Infinita",
    Default = false,
    Callback = function(value)
        if value then
            newStoredAmmo = math.huge
        else
            newStoredAmmo = 210
        end
    end    
})

TabExperimental:AddButton({
    Name = "✅ Aplicar Modificações de Munição",
    Callback = function()
        local weapon = root:FindFirstChild(modWeaponSelection)
        if not weapon then
            modParagraph:Set("Status", "❌ Arma não encontrada!")
            return
        end
        
        local mod = weapon:FindFirstChild("ACS_Settings")
        if not mod then
            modParagraph:Set("Status", "❌ ACS_Settings não encontrada!")
            return
        end
        
        local success, err = pcall(function()
            local settings = require(mod)
            settings.Ammo = newAmmo
            settings.AmmoInGun = newAmmo
            settings.StoredAmmo = newStoredAmmo
            settings.MaxStoredAmmo = newStoredAmmo == math.huge and math.huge or newStoredAmmo * 2
        end)
        
        if success then
            local stored = newStoredAmmo == math.huge and "∞" or tostring(newStoredAmmo)
            modParagraph:Set("Status", string.format(
                "✅ Munição modificada!\n" ..
                "Carregador: %d | Reserva: %s",
                newAmmo, stored))
        else
            modParagraph:Set("Status", "❌ Falha ao modificar: " .. tostring(err))
        end
    end
})

TabExperimental:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
TabExperimental:AddLabel("【 MODIFICAÇÕES DE PERFORMANCE 】")

local newShootRate = 800
local newRecoilMult = 1.0
local newSpreadMult = 1.0

TabExperimental:AddSlider({
    Name = "⚡ Cadência de Tiro (RPM)",
    Min = 100,
    Max = 9999,
    Default = 800,
    Color = Color3.fromRGB(255, 255, 100),
    Increment = 50,
    Callback = function(value)
        newShootRate = value
    end    
})

TabExperimental:AddSlider({
    Name = "🎯 Multiplicador de Recuo",
    Min = 0,
    Max = 5,
    Default = 1,
    Color = Color3.fromRGB(200, 100, 255),
    Increment = 0.1,
    Callback = function(value)
        newRecoilMult = value
    end    
})

TabExperimental:AddSlider({
    Name = "🔭 Multiplicador de Dispersão",
    Min = 0,
    Max = 5,
    Default = 1,
    Color = Color3.fromRGB(100, 255, 200),
    Increment = 0.1,
    Callback = function(value)
        newSpreadMult = value
    end    
})

TabExperimental:AddButton({
    Name = "✅ Aplicar Modificações de Performance",
    Callback = function()
        local weapon = root:FindFirstChild(modWeaponSelection)
        if not weapon then
            modParagraph:Set("Status", "❌ Arma não encontrada!")
            return
        end
        
        local mod = weapon:FindFirstChild("ACS_Settings")
        if not mod then
            modParagraph:Set("Status", "❌ ACS_Settings não encontrada!")
            return
        end
        
        local success, err = pcall(function()
            local settings = require(mod)
            settings.ShootRate = newShootRate
            
            -- Modificar recuo
            if settings.camRecoil then
                for k, v in pairs(settings.camRecoil) do
                    if type(v) == "table" and #v == 2 then
                        settings.camRecoil[k] = {v[1] * newRecoilMult, v[2] * newRecoilMult}
                    end
                end
            end
            
            if settings.gunRecoil then
                for k, v in pairs(settings.gunRecoil) do
                    if type(v) == "table" and #v == 2 then
                        settings.gunRecoil[k] = {v[1] * newRecoilMult, v[2] * newRecoilMult}
                    end
                end
            end
            
            -- Modificar dispersão
            if settings.MinSpread then
                settings.MinSpread = settings.MinSpread * newSpreadMult
            end
            if settings.MaxSpread then
                settings.MaxSpread = settings.MaxSpread * newSpreadMult
            end
        end)
        
        if success then
            modParagraph:Set("Status", string.format(
                "✅ Performance modificada!\n" ..
                "RPM: %d | Recuo: %.1fx | Dispersão: %.1fx",
                newShootRate, newRecoilMult, newSpreadMult))
        else
            modParagraph:Set("Status", "❌ Falha ao modificar: " .. tostring(err))
        end
    end
})

TabExperimental:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
TabExperimental:AddLabel("【 MODIFICAÇÕES EXTREMAS 】")

TabExperimental:AddButton({
    Name = "💥 Super Arma (All Max)",
    Callback = function()
        local weapon = root:FindFirstChild(modWeaponSelection)
        if not weapon then
            modParagraph:Set("Status", "❌ Arma não encontrada!")
            return
        end
        
        local mod = weapon:FindFirstChild("ACS_Settings")
        if not mod then
            modParagraph:Set("Status", "❌ ACS_Settings não encontrada!")
            return
        end
        
        local success, err = pcall(function()
            local settings = require(mod)
            
            -- Dano extremo
            settings.HeadDamage = {500, 500}
            settings.TorsoDamage = {300, 300}
            settings.LimbDamage = {200, 200}
            settings.MinDamage = 100
            
            -- Munição infinita
            settings.Ammo = 999
            settings.AmmoInGun = 999
            settings.StoredAmmo = math.huge
            settings.MaxStoredAmmo = math.huge
            
            -- Performance extrema
            settings.ShootRate = 9999
            
            -- Sem recuo
            if settings.camRecoil then
                for k, _ in pairs(settings.camRecoil) do
                    settings.camRecoil[k] = {0, 0}
                end
            end
            if settings.gunRecoil then
                for k, _ in pairs(settings.gunRecoil) do
                    settings.gunRecoil[k] = {0, 0}
                end
            end
            
            -- Modificar dispersão
            if settings.MinSpread then
                settings.MinSpread = 0
            end
            if settings.MaxSpread then
                settings.MaxSpread = 0
            end
            
            -- Balística extrema
            settings.MuzzleVelocity = 9999
            settings.BulletDrop = 0
            settings.BulletPenetration = 999
        end)
        
        if success then
            modParagraph:Set("Status", "✅ SUPER ARMA ATIVADA! 💥\n⚠️ Use com EXTREMO cuidado!")
        else
            modParagraph:Set("Status", "❌ Falha ao modificar: " .. tostring(err))
        end
    end
})

TabExperimental:AddButton({
    Name = "🔄 Resetar para Valores Originais",
    Callback = function()
        -- Limpar cache para forçar reload
        cachedSettings[modWeaponSelection] = nil
        
        modParagraph:Set("Status", "✅ Cache limpo!\nRecarregue a arma no jogo para restaurar valores originais.")
    end
})

-- ==================== TAB: TOOLS ====================

TabTools:AddLabel("═══════════ Ferramentas Extras ═══════════")

TabTools:AddButton({
    Name = "🔍 Escanear Todas as Armas",
    Callback = function()
        local allWeapons = {}
        for _, child in ipairs(root:GetChildren()) do
            if child:FindFirstChild("ACS_Settings") then
                table.insert(allWeapons, child.Name)
            end
        end
        
        local output = string.format("-- Armas encontradas: %d\n\n", #allWeapons)
        output = output .. table.concat(allWeapons, "\n")
        
        if setclipboard then
            pcall(setclipboard, output)
            TabTools:AddLabel(string.format("✅ %d armas encontradas e copiadas!", #allWeapons))
        else
            TabTools:AddLabel("❌ Clipboard não disponível.")
        end
    end
})

TabTools:AddButton({
    Name = "📁 Copiar Estrutura Completa (3 armas)",
    Callback = function()
        local paths = getWeaponPaths(targetNames)
        local output = string.format("-- Estrutura completa: %d objetos\n\n", #paths)
        output = output .. table.concat(paths, "\n")
        
        if setclipboard then
            pcall(setclipboard, output)
            TabTools:AddLabel("✅ Estrutura copiada!")
        else
            TabTools:AddLabel("❌ Clipboard não disponível.")
        end
    end
})

TabTools:AddParagraph("ℹ️ Informação", 
    "Este inspetor é somente leitura e não modifica o jogo.\n" ..
    "Todas as funções respeitam os sistemas de proteção do ACS.")

-- ==================== TAB: MISC ====================

TabMisc:AddLabel("═══════════ Configurações ═══════════")

TabMisc:AddButton({
    Name = "🔄 Limpar Cache",
    Callback = function()
        cachedSettings = {}
        TabMisc:AddLabel("✅ Cache limpo!")
    end
})

TabMisc:AddButton({
    Name = "🗑️ Destruir UI",
    Callback = function()
        pcall(function()
            for _, v in pairs(game.CoreGui:GetChildren()) do
                if v.Name == "Orion" then v:Destroy() end
            end
        end)
    end
})

TabMisc:AddParagraph("📌 Versão", "TNP Weapon Inspector Pro v2.0\nSomente leitura | Sem modificações")

-- ==================== TAB: ESP (NOVO) ====================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Configurações do ESP (padrões)
local espSettings = {
    Enabled = false,
    ShowPlayers = true,
    ShowBoxes = true,
    ShowNames = true,
    ShowTracers = false,
    ShowDistance = false,
    TeamCheck = true,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 50, 50),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 200, 50),
    Fill = false,
    FillTransparency = 0.7,
    Thickness = 1
}

-- UI controles
TabESP:AddLabel("═══════════ ESP Config ═══════════")
TabESP:AddToggle({ Name = "🔛 ESP Ativo", Default = espSettings.Enabled, Callback = function(v) espSettings.Enabled = v end })
TabESP:AddToggle({ Name = "👥 Mostrar Jogadores", Default = espSettings.ShowPlayers, Callback = function(v) espSettings.ShowPlayers = v end })
TabESP:AddToggle({ Name = "📦 Caixas", Default = espSettings.ShowBoxes, Callback = function(v) espSettings.ShowBoxes = v end })
TabESP:AddToggle({ Name = "🔤 Nomes", Default = espSettings.ShowNames, Callback = function(v) espSettings.ShowNames = v end })
TabESP:AddToggle({ Name = "📏 Distância no Nome", Default = espSettings.ShowDistance, Callback = function(v) espSettings.ShowDistance = v end })
TabESP:AddToggle({ Name = "📶 Tracer (linha até pé)", Default = espSettings.ShowTracers, Callback = function(v) espSettings.ShowTracers = v end })
TabESP:AddToggle({ Name = "🔰 Respeitar Time (team check)", Default = espSettings.TeamCheck, Callback = function(v) espSettings.TeamCheck = v end })
TabESP:AddSlider({ Name = "📏 Alcance Máximo (m)", Min = 50, Max = 5000, Default = espSettings.MaxDistance, Increment = 10, Callback = function(v) espSettings.MaxDistance = v end })
TabESP:AddColorPicker({ Name = "🎨 Cor da Caixa", Default = espSettings.BoxColor, Callback = function(c) espSettings.BoxColor = c end })
TabESP:AddColorPicker({ Name = "🎨 Cor do Nome", Default = espSettings.NameColor, Callback = function(c) espSettings.NameColor = c end })
TabESP:AddColorPicker({ Name = "🎨 Cor do Tracer", Default = espSettings.TracerColor, Callback = function(c) espSettings.TracerColor = c end })
TabESP:AddToggle({ Name = "⬛ Preencher Caixa", Default = espSettings.Fill, Callback = function(v) espSettings.Fill = v end })
TabESP:AddSlider({ Name = "🔳 Transparência do Fill", Min = 0, Max = 1, Default = espSettings.FillTransparency, Increment = 0.05, Callback = function(v) espSettings.FillTransparency = v end })
TabESP:AddSlider({ Name = "🔎 Espessura (thickness)", Min = 1, Max = 5, Default = espSettings.Thickness, Increment = 1, Callback = function(v) espSettings.Thickness = v end })

TabESP:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
TabESP:AddLabel("⚠️ Use com responsabilidade. Algumas features podem ser bloqueadas pelo roblox/executor.")

-- Anti-Barrier: integrado e controlável via UI
local antiBarrierEnabled = false
local antiBarrierConnection = nil
local lastHumanoidHealth = nil
TabESP:AddToggle({ Name = "🛡️ Anti-Barrier", Default = false, Callback = function(v)
    antiBarrierEnabled = v
    if antiBarrierEnabled then
        -- start
        if antiBarrierConnection then return end
        antiBarrierConnection = RunService.Heartbeat:Connect(function()
            local localChar = Players.LocalPlayer and Players.LocalPlayer.Character
            if not localChar then return end
            local hum = localChar:FindFirstChild("Humanoid")
            if not hum then return end
            if lastHumanoidHealth == nil then lastHumanoidHealth = hum.Health end
            if hum.Health <= 0 and lastHumanoidHealth > 1 then
                pcall(function() hum.Health = lastHumanoidHealth end)
            end
            lastHumanoidHealth = hum.Health
        end)
        pcall(function() print("Anti-Barrier ativado!") end)
    else
        -- stop
        if antiBarrierConnection then
            antiBarrierConnection:Disconnect()
            antiBarrierConnection = nil
        end
        lastHumanoidHealth = nil
        pcall(function() print("Anti-Barrier desativado!") end)
    end
end })

-- ESP runtime
local hasDrawing = (type(Drawing) == "table" and type(Drawing.new) == "function")
local espObjects = {} -- [player] = {box, name, tracer, highlight}

local function createHighlightForCharacter(char)
    if not char then return nil end
    local ok, Highlight = pcall(function() return Instance.new("Highlight") end)
    if not ok or not Highlight then return nil end
    Highlight.Adornee = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    Highlight.Parent = game:GetService("CoreGui") -- Parent safe place; executor may require other parent
    Highlight.FillColor = espSettings.BoxColor
    Highlight.OutlineColor = Color3.new(0,0,0)
    Highlight.FillTransparency = espSettings.Fill and espSettings.FillTransparency or 1
    Highlight.Enabled = false
    return Highlight
end

local function createDraw(objType, props)
    if not hasDrawing then return nil end
    local ok, item = pcall(function() return Drawing.new(objType) end)
    if not ok or not item then return nil end
    for k,v in pairs(props or {}) do pcall(function() item[k] = v end) end
    return item
end

local function removeESPForPlayer(plr)
    local data = espObjects[plr]
    if not data then return end
    if data.box and hasDrawing then pcall(function() data.box:Remove() end) end
    if data.name and hasDrawing then pcall(function() data.name:Remove() end) end
    if data.tracer and hasDrawing then pcall(function() data.tracer:Remove() end) end
    if data.highlight and data.highlight.Parent then pcall(function() data.highlight:Destroy() end) end
    espObjects[plr] = nil
end

local function ensureESPForPlayer(plr)
    if espObjects[plr] then return espObjects[plr] end
    local obj = {}
    if hasDrawing then
        obj.box = createDraw("Square", {Visible = false, Color = espSettings.BoxColor, Filled = espSettings.Fill, Transparency = espSettings.FillTransparency, Thickness = espSettings.Thickness})
        obj.name = createDraw("Text", {Visible = false, Color = espSettings.NameColor, Outline = true, Size = 16, Center = true})
        obj.tracer = createDraw("Line", {Visible = false, Color = espSettings.TracerColor, Thickness = espSettings.Thickness})
    end
    obj.highlight = createHighlightForCharacter(nil) -- adorna quando possível no update
    espObjects[plr] = obj
    return obj
end

local function updateESPObjects()
    if not espSettings.Enabled then
        -- hide all
        for plr, data in pairs(espObjects) do
            if data.box and hasDrawing then data.box.Visible = false end
            if data.name and hasDrawing then data.name.Visible = false end
            if data.tracer and hasDrawing then data.tracer.Visible = false end
            if data.highlight then data.highlight.Enabled = false end
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then goto continue end

            local dist = (root.Position - (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character.HumanoidRootPart.Position or Camera.CFrame.Position)).Magnitude
            if dist > espSettings.MaxDistance then
                removeESPForPlayer(plr)
                goto continue
            end

            if espSettings.TeamCheck then
                local localTeam = plr.Team
                if Players.LocalPlayer.Team and localTeam and Players.LocalPlayer.Team == localTeam then
                    removeESPForPlayer(plr)
                    goto continue
                end
            end

            local onScreen, screenPos = pcall(function()
                return Camera:WorldToViewportPoint(root.Position)
            end)
            if not onScreen then goto continue end
            local screenX, screenY, onScreenFlag = screenPos.X, screenPos.Y, screenPos.Z > 0
            if not onScreenFlag then
                removeESPForPlayer(plr)
                goto continue
            end

            local obj = ensureESPForPlayer(plr)

            -- atualiza highlight (chams)
            if obj.highlight then
                pcall(function()
                    obj.highlight.Adornee = char
                    obj.highlight.FillColor = espSettings.BoxColor
                    obj.highlight.FillTransparency = espSettings.Fill and espSettings.FillTransparency or 1
                    obj.highlight.Enabled = espSettings.ShowPlayers and true or false
                end)
            end

            -- compute box size approximation
            local head = char:FindFirstChild("Head")
            local rootPart = root
            local topPos = head and head.Position or rootPart.Position + Vector3.new(0,1,0)
            local bottomPos = rootPart.Position - Vector3.new(0,1,0)
            local okTop, topScreen = pcall(function() return Camera:WorldToViewportPoint(topPos) end)
            local okBottom, bottomScreen = pcall(function() return Camera:WorldToViewportPoint(bottomPos) end)
            if not (okTop and okBottom) then goto continue end
            local height = math.abs(topScreen.Y - bottomScreen.Y)
            local width = math.clamp(height * 0.45, 20, 300)

            -- Boxes / Text / Tracer (Drawing)
            if hasDrawing then
                if obj.box then
                    obj.box.Size = Vector2.new(width, height)
                    obj.box.Position = Vector2.new(screenX - width/2, screenY - height/2)
                    obj.box.Color = espSettings.BoxColor
                    obj.box.Filled = espSettings.Fill
                    obj.box.Transparency = espSettings.FillTransparency
                    obj.box.Thickness = espSettings.Thickness
                    obj.box.Visible = espSettings.ShowBoxes
                end

                if obj.name then
                    local nameText = plr.Name
                    if espSettings.ShowDistance then nameText = string.format("%s (%.0fm)", nameText, dist) end
                    obj.name.Text = nameText
                    obj.name.Position = Vector2.new(screenX, screenY - height/2 - 12)
                    obj.name.Color = espSettings.NameColor
                    obj.name.Size = 16
                    obj.name.Visible = espSettings.ShowNames
                end

                if obj.tracer then
                    obj.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    obj.tracer.To = Vector2.new(screenX, screenY + height/2)
                    obj.tracer.Color = espSettings.TracerColor
                    obj.tracer.Thickness = espSettings.Thickness
                    obj.tracer.Visible = espSettings.ShowTracers
                end
            end

        end
        ::continue::
    end
end

-- Connections
local espConnection = nil
local function startESP()
    if espConnection then return end
    espConnection = RunService.RenderStepped:Connect(function()
        updateESPObjects()
    end)
end
local function stopESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    -- remove drawings/highlights
    for p,_ in pairs(espObjects) do removeESPForPlayer(p) end
end

-- Toggle automático via setting
TabESP:AddButton({ Name = "🔄 Aplicar Configurações (Ativar/Desativar ESP)", Callback = function()
    if espSettings.Enabled then startESP() else stopESP() end
end })

-- Keep ESP toggles reactive
spawn(function()
    while true do
        if espSettings.Enabled and not espConnection then startESP() end
        if not espSettings.Enabled and espConnection then stopESP() end
        wait(0.5)
    end
end)

-- Cleanup players
Players.PlayerRemoving:Connect(function(plr) removeESPForPlayer(plr) end)

-- Inicializar
OrionLib:Init()
