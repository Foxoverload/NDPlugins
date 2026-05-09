-- ============================================================
-- FCEXT AI Narrator Module v1.0
-- Integrates OpenAI API with Firecast for AI-powered narration
-- Requires: fcext (with httpPost), Firecast SDK
-- ============================================================

local ai = {};

-- ============ CONFIGURATION ============
ai.config = {
    apiKey = "",                     -- OpenAI API key (loaded from file)
    model = "gpt-4o-mini",           -- Model to use
    maxHistory = 20,                 -- Max chat messages to keep in context
    triggerPrefix = "/ia",           -- Command prefix to activate AI
    autoNarrate = false,             -- Auto-narrate mode (respond to everything)
    temperature = 0.8,               -- AI creativity (0.0 = deterministic, 1.0 = creative)
    maxTokens = 1024,                -- Max tokens in response
    respondAsNPC = true,             -- Use enviarMensagemNPC (true) or enviarNarracao (false)
    npcName = "IA Narradora",        -- NPC name for responses
    enabled = false,                 -- Master toggle
};

-- ============ STATE ============
local chatHistory = {};              -- Conversation history for OpenAI
local activeMesa = nil;              -- Current room
local activeChat = nil;              -- Current chat
local listenerId = nil;              -- Chat listener ID
local isProcessing = false;          -- Prevent concurrent requests
local configPath = "";               -- Path to config file

-- ============ MINIMAL JSON ============
-- Lightweight JSON encoder (no external deps needed)

local function jsonEscape(s)
    if type(s) ~= "string" then return tostring(s or ""); end;
    s = s:gsub('\\', '\\\\');
    s = s:gsub('"', '\\"');
    s = s:gsub('\n', '\\n');
    s = s:gsub('\r', '\\r');
    s = s:gsub('\t', '\\t');
    -- Escape control characters
    s = s:gsub('[\x00-\x1f]', function(c) return string.format('\\u%04x', string.byte(c)); end);
    return s;
end;

local function jsonEncode(val)
    local t = type(val);
    if t == "nil" then return "null";
    elseif t == "boolean" then return val and "true" or "false";
    elseif t == "number" then return tostring(val);
    elseif t == "string" then return '"' .. jsonEscape(val) .. '"';
    elseif t == "table" then
        -- Check if array or object
        local isArray = (#val > 0);
        if isArray then
            local parts = {};
            for i, v in ipairs(val) do
                parts[i] = jsonEncode(v);
            end;
            return "[" .. table.concat(parts, ",") .. "]";
        else
            local parts = {};
            for k, v in pairs(val) do
                table.insert(parts, '"' .. jsonEscape(tostring(k)) .. '":' .. jsonEncode(v));
            end;
            return "{" .. table.concat(parts, ",") .. "}";
        end;
    end;
    return "null";
end;

-- Minimal JSON decoder (handles OpenAI response format)
local function jsonDecodeValue(str, pos)
    pos = pos or 1;
    -- Skip whitespace
    pos = str:find('[^ \t\n\r]', pos) or pos;
    local c = str:sub(pos, pos);

    if c == '"' then
        -- String
        local endPos = pos + 1;
        while true do
            local ch = str:sub(endPos, endPos);
            if ch == '\\' then endPos = endPos + 2;
            elseif ch == '"' then break;
            else endPos = endPos + 1; end;
        end;
        local s = str:sub(pos + 1, endPos - 1);
        s = s:gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t'):gsub('\\"', '"'):gsub('\\\\', '\\');
        return s, endPos + 1;
    elseif c == '{' then
        -- Object
        local obj = {};
        pos = pos + 1;
        pos = str:find('[^ \t\n\r]', pos) or pos;
        if str:sub(pos, pos) == '}' then return obj, pos + 1; end;
        while true do
            local key, val;
            key, pos = jsonDecodeValue(str, pos);
            pos = str:find('[^ \t\n\r]', pos) or pos;
            pos = pos + 1; -- skip ':'
            val, pos = jsonDecodeValue(str, pos);
            obj[key] = val;
            pos = str:find('[^ \t\n\r]', pos) or pos;
            if str:sub(pos, pos) == '}' then return obj, pos + 1; end;
            pos = pos + 1; -- skip ','
        end;
    elseif c == '[' then
        -- Array
        local arr = {};
        pos = pos + 1;
        pos = str:find('[^ \t\n\r]', pos) or pos;
        if str:sub(pos, pos) == ']' then return arr, pos + 1; end;
        while true do
            local val;
            val, pos = jsonDecodeValue(str, pos);
            table.insert(arr, val);
            pos = str:find('[^ \t\n\r]', pos) or pos;
            if str:sub(pos, pos) == ']' then return arr, pos + 1; end;
            pos = pos + 1; -- skip ','
        end;
    elseif c == 't' then return true, pos + 4;
    elseif c == 'f' then return false, pos + 5;
    elseif c == 'n' then return nil, pos + 4;
    else
        -- Number
        local numStr = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos);
        return tonumber(numStr), pos + #numStr;
    end;
end;

local function jsonDecode(str)
    if not str or str == "" then return nil; end;
    local ok, result = pcall(jsonDecodeValue, str, 1);
    if ok then return result; end;
    return nil;
end;

-- ============ CONFIG PERSISTENCE ============

local function getConfigPath()
    if configPath ~= "" then return configPath; end;
    local fcext = require("fcext");
    -- Try to find the Firecast directory
    local drives = {"C", "D"};
    for _, drv in ipairs(drives) do
        local ok, users = pcall(fcext.listDir, drv .. ":\\Users");
        if ok and users then
            for _, u in ipairs(users) do
                if u ~= "Public" and u ~= "Default" and u ~= "Default User" and u ~= "All Users" then
                    local p = drv .. ":\\Users\\" .. u .. "\\AppData\\Local\\Firecast\\fcext_ai_config.json";
                    configPath = p;
                    return p;
                end;
            end;
        end;
    end;
    configPath = "C:\\fcext_ai_config.json";
    return configPath;
end;

function ai.saveConfig()
    local fcext = require("fcext");
    local path = getConfigPath();
    local data = jsonEncode({
        apiKey = ai.config.apiKey,
        model = ai.config.model,
        maxHistory = ai.config.maxHistory,
        temperature = ai.config.temperature,
        maxTokens = ai.config.maxTokens,
        triggerPrefix = ai.config.triggerPrefix,
        autoNarrate = ai.config.autoNarrate,
        respondAsNPC = ai.config.respondAsNPC,
        npcName = ai.config.npcName,
    });
    pcall(fcext.writeFile, path, data);
end;

function ai.loadConfig()
    local fcext = require("fcext");
    local path = getConfigPath();
    local ok, content = pcall(fcext.readFile, path);
    if ok and content then
        local cfg = jsonDecode(content);
        if cfg then
            for k, v in pairs(cfg) do
                if ai.config[k] ~= nil then
                    ai.config[k] = v;
                end;
            end;
        end;
    end;
end;

-- ============ SHEET READING ============

function ai.readSheetFromNDB(sheet)
    if not sheet then return ""; end;
    local parts = {};

    -- Helper to safely read a field
    local function sf(field)
        local ok, val = pcall(function() return sheet[field]; end);
        if ok and val ~= nil then
            local s = tostring(val);
            if s:find("^table:") then return ""; end;
            return s;
        end;
        return "";
    end;

    -- Basic info
    local nome = sf("nome");
    if nome == "" then nome = sf("name"); end;
    if nome ~= "" then table.insert(parts, "Nome: " .. nome); end;

    -- Core fields
    local fields = {
        {"Titulo", "titulo"}, {"Rank", "rank"}, {"Nivel", "nivel"},
        {"Clã", "cla"}, {"Vila", "vila"}, {"Aldeia", "aldeia"},
        {"Idade", "idade"}, {"Genero", "genero"},
        {"Natureza de Chakra", "natureza_chakra"},
        {"Kekkei Genkai", "kekkei_genkai"},
        {"Tipo Sanguineo", "tipo_sanguineo"},
    };

    for _, f in ipairs(fields) do
        local v = sf(f[2]);
        if v ~= "" then table.insert(parts, f[1] .. ": " .. v); end;
    end;

    -- Attributes
    local attrs = {
        {"FOR", "forca"}, {"DEX", "destreza"}, {"CON", "constituicao"},
        {"INT", "inteligencia"}, {"SAB", "sabedoria"}, {"CAR", "carisma"},
        {"NIN", "ninjutsu"}, {"GEN", "genjutsu"}, {"TAI", "taijutsu"},
    };

    local attrParts = {};
    for _, a in ipairs(attrs) do
        local v = sf(a[2]);
        if v ~= "" and v ~= "0" then
            table.insert(attrParts, a[1] .. "=" .. v);
        end;
    end;
    if #attrParts > 0 then
        table.insert(parts, "Atributos: " .. table.concat(attrParts, ", "));
    end;

    -- Combat stats
    local combatStats = {
        {"HP", "hp_atual"}, {"HP Max", "hp_max"},
        {"Chakra", "chakra_atual"}, {"Chakra Max", "chakra_max"},
        {"Stamina", "stamina_atual"}, {"Stamina Max", "stamina_max"},
    };
    local combatParts = {};
    for _, cs in ipairs(combatStats) do
        local v = sf(cs[2]);
        if v ~= "" and v ~= "0" then
            table.insert(combatParts, cs[1] .. "=" .. v);
        end;
    end;
    if #combatParts > 0 then
        table.insert(parts, "Status: " .. table.concat(combatParts, ", "));
    end;

    -- Personality fields
    local persFields = {
        {"Gostos", "gostos"}, {"Desgostos", "desgostos"},
        {"Hobbies", "hobbies"}, {"Sonho", "sonho"}, {"Objetivo", "objetivo"},
    };
    for _, pf in ipairs(persFields) do
        local v = sf(pf[2]);
        if v ~= "" then table.insert(parts, pf[1] .. ": " .. v); end;
    end;

    return table.concat(parts, "\n");
end;

-- ============ SYSTEM PROMPT ============

function ai.buildSystemPrompt(sheets)
    local prompt = [[Voce e uma IA Narradora para o RPG "Naruto Destiny" (ND), um sistema de RPG de mesa baseado no universo de Naruto.

REGRAS DE COMPORTAMENTO:
- Responda sempre em portugues brasileiro
- Seja imersivo e dramatico nas narracoes
- Use as informacoes das fichas dos personagens para contextualizar respostas
- Respeite as capacidades e limitacoes de cada personagem baseado em seus atributos
- Quando pedido para narrar combate, descreva usando os atributos relevantes
- Quando pedido para descrever cenarios, use detalhes do universo Naruto
- Se um jogador fizer algo que parece impossivel para seu nivel/rank, avise educadamente
- Use emojis ocasionalmente para dar vida a narracao (⚔️ 🔥 💨 etc.)

SISTEMA ND - RESUMO:
- Atributos primarios: FOR (Forca), DEX (Destreza), CON (Constituicao), INT (Inteligencia), SAB (Sabedoria), CAR (Carisma)
- Atributos de jutsu: NIN (Ninjutsu), GEN (Genjutsu), TAI (Taijutsu)
- Ranks: Estudante < Genin < Chuunin < Jounin < ANBU < Kage/Sannin
- Naturezas de Chakra: Katon (Fogo), Suiton (Agua), Doton (Terra), Fuuton (Vento), Raiton (Raio)
- HP, Chakra e Stamina sao recursos que se gastam em combate

COMANDOS:
- /ia [pergunta] - Responde uma pergunta ou narra algo
- /ia narrar [descricao] - Narra uma cena
- /ia combate [situacao] - Narra um combate
- /ia ficha [nome] - Mostra resumo de uma ficha
- /ia ajuda - Lista comandos disponiveis]];

    -- Add character sheets
    if sheets and #sheets > 0 then
        prompt = prompt .. "\n\nFICHAS DOS PERSONAGENS NA MESA:";
        for _, s in ipairs(sheets) do
            prompt = prompt .. "\n\n--- " .. (s.nome or "Personagem") .. " ---\n" .. s.dados;
        end;
    end;

    return prompt;
end;

-- ============ OPENAI API ============

function ai.sendToOpenAI(messages, callback)
    local fcext = require("fcext");

    if ai.config.apiKey == "" then
        if callback then callback(nil, "API key nao configurada. Use /ia config para configurar."); end;
        return;
    end;

    -- Build request body
    local body = jsonEncode({
        model = ai.config.model,
        messages = messages,
        temperature = ai.config.temperature,
        max_tokens = ai.config.maxTokens,
    });

    -- Build headers
    local headers = "Authorization: Bearer " .. ai.config.apiKey;

    -- Make HTTP request
    local status, response = fcext.httpPost(
        "https://api.openai.com/v1/chat/completions",
        body,
        "application/json",
        headers
    );

    if not status then
        if callback then callback(nil, "Erro HTTP: " .. tostring(response)); end;
        return;
    end;

    if status ~= 200 then
        local errMsg = "API retornou status " .. tostring(status);
        local errBody = jsonDecode(response);
        if errBody and errBody.error and errBody.error.message then
            errMsg = errMsg .. ": " .. errBody.error.message;
        end;
        if callback then callback(nil, errMsg); end;
        return;
    end;

    -- Parse response
    local data = jsonDecode(response);
    if data and data.choices and data.choices[1] and data.choices[1].message then
        local content = data.choices[1].message.content;
        if callback then callback(content, nil); end;
    else
        if callback then callback(nil, "Resposta da API invalida"); end;
    end;
end;

-- ============ CHAT INTERACTION ============

function ai.respond(chat, text)
    if not chat then return; end;

    -- Split long messages (Firecast has char limits)
    local maxLen = 900;
    if #text <= maxLen then
        if ai.config.respondAsNPC then
            pcall(function() chat:enviarMensagemNPC(ai.config.npcName, text); end);
        else
            pcall(function() chat:enviarNarracao(text); end);
        end;
    else
        -- Split into chunks
        local pos = 1;
        while pos <= #text do
            local chunk = text:sub(pos, pos + maxLen - 1);
            -- Try to break at a sentence/newline
            if pos + maxLen - 1 < #text then
                local breakPos = chunk:find("\n[^\n]*$") or chunk:find("%.[^%.]*$") or chunk:find(" [^ ]*$");
                if breakPos and breakPos > maxLen / 2 then
                    chunk = text:sub(pos, pos + breakPos - 1);
                    pos = pos + breakPos;
                else
                    pos = pos + maxLen;
                end;
            else
                pos = pos + maxLen;
            end;
            if ai.config.respondAsNPC then
                pcall(function() chat:enviarMensagemNPC(ai.config.npcName, chunk); end);
            else
                pcall(function() chat:enviarNarracao(chunk); end);
            end;
        end;
    end;
end;

function ai.processCommand(msg)
    if isProcessing then
        if msg.chat then
            ai.respond(msg.chat, "⏳ Aguarde... ainda estou processando a mensagem anterior.");
        end;
        return;
    end;

    local texto = msg.mensagem or "";
    local prefix = ai.config.triggerPrefix;

    -- Remove prefix
    local command = texto:sub(#prefix + 1):match("^%s*(.-)%s*$");
    if command == "" then command = "ajuda"; end;

    -- Handle special commands
    if command == "ajuda" or command == "help" then
        ai.respond(msg.chat, [[🤖 **IA Narradora - Comandos:**
/ia [pergunta] - Faz uma pergunta ou pede narracao
/ia narrar [cena] - Narra uma cena especifica
/ia combate [situacao] - Narra uma sequencia de combate
/ia ficha [nome] - Mostra resumo de uma ficha
/ia status - Estado atual da IA
/ia ajuda - Este menu]]);
        return;
    end;

    if command == "status" then
        local status = "🤖 **IA Narradora - Status:**\n";
        status = status .. "Modelo: " .. ai.config.model .. "\n";
        status = status .. "Historico: " .. #chatHistory .. "/" .. ai.config.maxHistory .. " mensagens\n";
        status = status .. "Modo: " .. (ai.config.autoNarrate and "Automatico" or "Comandos") .. "\n";
        status = status .. "API Key: " .. (ai.config.apiKey ~= "" and "Configurada ✅" or "Nao configurada ❌");
        ai.respond(msg.chat, status);
        return;
    end;

    -- Process with AI
    isProcessing = true;

    -- Notify processing
    if msg.chat then
        pcall(function() msg.chat:enviarMensagemNPC(ai.config.npcName, "🤔 Pensando..."); end);
    end;

    -- Collect sheets
    local sheets = {};
    pcall(function()
        if activeMesa then
            local bib = activeMesa.biblioteca;
            if bib then
                local filhos = bib.filhos;
                if filhos then
                    for _, item in ipairs(filhos) do
                        pcall(function()
                            if item:isType("personagem") then
                                item:loadSheetNDB(function(ndb)
                                    if ndb then
                                        local dados = ai.readSheetFromNDB(ndb);
                                        if dados ~= "" then
                                            table.insert(sheets, {
                                                nome = item.nome or "Personagem",
                                                dados = dados,
                                            });
                                        end;
                                    end;
                                end);
                            end;
                        end);
                    end;
                end;
            end;
        end;
    end);

    -- Build messages
    local systemPrompt = ai.buildSystemPrompt(sheets);

    -- Add player context
    local playerName = "Jogador";
    pcall(function()
        if msg.jogador then
            playerName = msg.jogador.nick or msg.jogador.login or "Jogador";
        end;
    end);

    local userMsg = playerName .. " diz: " .. command;

    -- Add to history
    table.insert(chatHistory, {role = "user", content = userMsg});

    -- Trim history if needed
    while #chatHistory > ai.config.maxHistory do
        table.remove(chatHistory, 1);
    end;

    -- Build full message array
    local messages = {};
    table.insert(messages, {role = "system", content = systemPrompt});
    for _, h in ipairs(chatHistory) do
        table.insert(messages, h);
    end;

    -- Send to API
    ai.sendToOpenAI(messages, function(response, err)
        isProcessing = false;

        if err then
            ai.respond(msg.chat, "❌ Erro: " .. tostring(err));
            return;
        end;

        if response then
            -- Add to history
            table.insert(chatHistory, {role = "assistant", content = response});
            while #chatHistory > ai.config.maxHistory do
                table.remove(chatHistory, 1);
            end;

            -- Send response
            ai.respond(msg.chat, response);
        end;
    end);
end;

-- ============ INITIALIZATION ============

function ai.start(mesa)
    if not mesa then
        -- Try to get current room
        pcall(function()
            local mesas = rrpg.getMesas();
            if mesas and #mesas > 0 then
                mesa = mesas[1];
            end;
        end);
    end;

    if not mesa then return false, "Nenhuma mesa encontrada"; end;

    activeMesa = mesa;
    ai.config.enabled = true;

    -- Load config
    ai.loadConfig();

    -- Set up chat listener
    if listenerId then
        pcall(function() rrpg.messaging.unlisten(listenerId); end);
    end;

    listenerId = rrpg.listen("ChatMessage", function(msg)
        if not ai.config.enabled then return; end;

        local texto = msg.mensagem or "";
        local prefix = ai.config.triggerPrefix;

        -- Check if message starts with trigger prefix
        if texto:sub(1, #prefix) == prefix then
            -- Get the chat object
            if not msg.chat and msg.mesa then
                msg.chat = msg.mesa.activeChat or msg.mesa.chat;
            end;

            if msg.chat then
                activeChat = msg.chat;
                ai.processCommand(msg);
            end;
        end;
    end);

    return true;
end;

function ai.stop()
    ai.config.enabled = false;

    if listenerId then
        pcall(function() rrpg.messaging.unlisten(listenerId); end);
        listenerId = nil;
    end;

    activeMesa = nil;
    activeChat = nil;
    chatHistory = {};
end;

function ai.setApiKey(key)
    ai.config.apiKey = key or "";
    ai.saveConfig();
end;

function ai.clearHistory()
    chatHistory = {};
end;

return ai;
