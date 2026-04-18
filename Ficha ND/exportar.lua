local LT = string.char(60);
local GT = string.char(62);
local AMP = string.char(38);

local function esc(s)
    if s == nil then return ""; end
    s = tostring(s);
    s = string.gsub(s, AMP, AMP .. "amp;");
    s = string.gsub(s, LT, AMP .. "lt;");
    s = string.gsub(s, GT, AMP .. "gt;");
    return s;
end

local function tag(name, content, attrs)
    local a = attrs or "";
    if a ~= "" then a = " " .. a; end
    return LT .. name .. a .. GT .. content .. LT .. "/" .. name .. GT;
end

local function selfClose(name, attrs)
    local a = attrs or "";
    if a ~= "" then a = " " .. a; end
    return LT .. name .. a .. "/" .. GT;
end

function exportarFichaHTML(sheet, selfForm)
    require("dialogs.lua");
    require("utils.lua");
    
    local function v(field)
        local val = sheet[field];
        if val == nil then return ""; end
        return tostring(val);
    end
    
    local function row(label, field)
        local val = v(field);
        if val == "" then return ""; end
        return tag("tr",
            tag("td", esc(label), "class='l'") ..
            tag("td", esc(val))
        ) .. "\n";
    end
    
    local function getText(ctrl)
        if ctrl ~= nil then
            local ok, txt = pcall(function() return ctrl:getText(); end);
            if ok and txt then return txt; end
        end
        return "";
    end
    
    local html = LT .. "!DOCTYPE html" .. GT .. "\n";
    html = html .. tag("html",
        tag("head",
            selfClose("meta", "charset='utf-8'") .. "\n" ..
            tag("title", "Ficha ND - " .. esc(v("nome"))) .. "\n" ..
            tag("style", [[
body{background:#0D0D1A;color:#E0E0FF;font-family:Segoe UI,sans-serif;padding:20px;max-width:900px;margin:0 auto}
h1{color:#FF6B35;text-align:center;border-bottom:2px solid #FF6B35;padding-bottom:10px}
h2{color:#FF6B35;margin-top:25px;border-bottom:1px solid #333}
h3{color:#CCAA55;margin-top:15px}
table{width:100%;border-collapse:collapse;margin-bottom:15px}
td,th{padding:4px 8px;border:1px solid #2A2A4E;text-align:left}
.l{width:180px;color:#B8B8CC;font-weight:bold;background:#141428}
.sec{background:#1A1A3E;color:#FF6B35;font-size:14px;text-align:center}
pre{background:#141428;padding:10px;border:1px solid #2A2A4E;white-space:pre-wrap;font-size:12px;color:#CCCCEE}
.footer{text-align:center;color:#666;margin-top:30px;font-size:11px}
            ]])
        ) .. "\n" ..
        tag("body",
            -- Titulo
            tag("h1", "Ficha Naruto Destiny - " .. esc(v("nome"))) .. "\n" ..
            
            -- Dados Pessoais
            tag("h2", "Dados Pessoais") .. "\n" ..
            tag("table",
                row("Nome", "nome") ..
                row("Idade", "idade") ..
                row("Sexo", "sexo") ..
                row("Altura", "altura") ..
                row("Peso", "peso") ..
                row("Tipo Sanguineo", "tipo_sanguineo") ..
                row("Aniversario", "aniversario") ..
                row("Vila de Nascimento", "vila_nascimento") ..
                row("Cla Ninja", "cla_ninja") ..
                row("Rank Shinobi", "rank_shinobi") ..
                row("Sensei", "sensei") ..
                row("Organizacao", "organizacao") ..
                row("Natureza", "natureza") ..
                row("Mao Dominante", "mao_dominante") ..
                row("Nivel", "nivel") ..
                row("Kekkei Genkai", "kekkei_genkai")
            ) .. "\n" ..
            
            -- Personalidade
            tag("h2", "Personalidade") .. "\n" ..
            tag("table",
                row("Comportamento", "comportamento") ..
                row("Objetivo", "objetivo") ..
                row("Sonho", "sonho") ..
                row("Gostos", "gostos") ..
                row("Desgostos", "desgostos") ..
                row("Hobbies", "hobbies") ..
                row("Interesse Romantico", "interesse_romantico")
            ) .. "\n" ..
            
            -- Atributos Core
            tag("h2", "Atributos Core") .. "\n" ..
            tag("table",
                row("Forca", "forca") ..
                row("Agilidade", "agilidade") ..
                row("Constituicao", "constituicao") ..
                row("Destreza", "destreza") ..
                row("Ctrl Chakra", "ctrl_chakra") ..
                row("Concentracao", "concentracao") ..
                row("Inteligencia", "inteligencia") ..
                row("Forca Espiritual", "forca_espiritual")
            ) .. "\n" ..
            
            -- Status
            tag("h2", "Status") .. "\n" ..
            tag("table",
                row("PV", "pv") ..
                row("PV Atual", "pv_atual") ..
                row("Chakra", "pchakra") ..
                row("Chakra Atual", "pchakra_atual") ..
                row("Estamina", "pestamina") ..
                row("Estamina Atual", "pestamina_atual") ..
                row("Ryous", "ryous")
            ) .. "\n" ..
            
            -- Atributos de Combate
            tag("h2", "Atributos de Combate") .. "\n" ..
            tag("table",
                row("Taijutsu", "taijutsu") ..
                row("Bukijutsu", "bukijutsu") ..
                row("Ninjutsu", "ninjutsu") ..
                row("Genjutsu", "genjutsu") ..
                row("Genjutsu Kai", "genjutsu_kai") ..
                row("Fuinjutsu", "fuinjutsu") ..
                row("Arremesso", "arremesso") ..
                row("Esquiva", "esquiva") ..
                row("Bloqueio Fisico", "bloqueio_fisico") ..
                row("Bloqueio Chakra", "bloqueio_chakra") ..
                row("Reflexo", "reflexo") ..
                row("Iniciativa", "iniciativa") ..
                row("Tai-Bukijutsu", "tai_bukijutsu") ..
                row("Nin-Taijutsu", "nin_taijutsu") ..
                row("Hiraishin", "hiraishin") ..
                row("Movimentacao", "movimentacao")
            ) .. "\n" ..
            
            -- Pericias
            tag("h2", "Pericias") .. "\n" ..
            tag("table",
                row("Sobrevivencia", "sobrevivencia") ..
                row("Armadilha", "armadilha") ..
                row("Empatia", "empatia") ..
                row("Intimidacao", "intimidacao") ..
                row("Ladinagem", "ladinagem") ..
                row("Enganacao", "enganacao") ..
                row("Percepcao", "percepcao") ..
                row("Persuasao", "persuasao") ..
                row("Seducao", "seducao") ..
                row("Medicina", "medicina") ..
                row("Conhecimento", "conhecimento") ..
                row("Oficio", "oficio") ..
                row("Ensinamento", "ensinamento") ..
                row("Aprendizado", "aprendizado")
            ) .. "\n" ..
            
            -- Elementos
            tag("h2", "Elementos") .. "\n" ..
            tag("table",
                row("Fogo", "elem_fogo") ..
                row("Agua", "elem_agua") ..
                row("Vento", "elem_vento") ..
                row("Terra", "elem_terra") ..
                row("Raio", "elem_raio") ..
                row("Combo", "elem_combo")
            ) .. "\n" ..
            
            -- Traits
            tag("h2", "Traits") .. "\n" ..
            tag("p", esc(v("trait_resumo"))) .. "\n" ..
            tag("pre", esc(getText(selfForm.edtTraits))) .. "\n" ..
            
            -- Qualidades e Defeitos
            tag("h2", "Qualidades e Defeitos") .. "\n" ..
            tag("table",
                row("Qualidade 1", "qualidade1") ..
                row("Defeito 1", "defeito1") ..
                row("Qualidade 2", "qualidade2") ..
                row("Defeito 2", "defeito2") ..
                row("Qualidade 3", "qualidade3") ..
                row("Defeito 3", "defeito3") ..
                row("Qualidade 4", "qualidade4") ..
                row("Defeito 4", "defeito4") ..
                row("Qualidade 5", "qualidade5") ..
                row("Defeito 5", "defeito5")
            ) .. "\n"
        )
    );
    
    -- Tecnicas
    local tecNames = {"Taijutsu","Bukijutsu","Ninjutsu","Elemental","Fuinjutsu","Kuchiyose","Kekkei Genkai","Hab. Gerais"};
    local tecEdits = {
        selfForm.edtTecTaijutsu, selfForm.edtTecBukijutsu,
        selfForm.edtTecNinjutsu, selfForm.edtTecElemental,
        selfForm.edtTecFuinjutsu, selfForm.edtTecKuchiyose,
        selfForm.edtTecKekkei, selfForm.edtTecGerais
    };
    
    local tecBlock = tag("h2", "Tecnicas") .. "\n";
    tecBlock = tecBlock .. tag("p", esc(v("jutsu_pontos_atual")) .. " / " .. esc(v("jutsu_pontos_max")) .. " Pontos de Jutsu") .. "\n";
    
    for i = 1, #tecNames do
        local txt = getText(tecEdits[i]);
        if txt ~= "" then
            tecBlock = tecBlock .. tag("h3", esc(tecNames[i])) .. "\n";
            tecBlock = tecBlock .. tag("pre", esc(txt)) .. "\n";
        end
    end
    
    -- Inventario
    local invTxt = getText(selfForm.edtInventario);
    local invBlock = "";
    if invTxt ~= "" then
        invBlock = tag("h2", "Inventario") .. "\n" .. tag("pre", esc(invTxt)) .. "\n";
    end
    
    -- Historia
    local histTxt = getText(selfForm.edtHistoria);
    local histBlock = "";
    if histTxt ~= "" then
        histBlock = tag("h2", "Historia") .. "\n" .. tag("pre", esc(histTxt)) .. "\n";
    end
    
    -- Footer
    local footer = tag("div", "Exportado de Naruto Destiny - Firecast", "class='footer'") .. "\n";
    
    -- Insert tecnicas, inventario, historia before closing body/html
    local closeTag = LT .. "/body" .. GT .. LT .. "/html" .. GT;
    html = string.gsub(html, LT .. "/body" .. GT, tecBlock .. invBlock .. histBlock .. footer .. LT .. "/body" .. GT);
    
    -- Save
    local stream = utils.newMemoryStream();
    stream:write(html);
    stream.position = 0;
    
    local nome = v("nome");
    if nome == "" then nome = "Ficha"; end
    
    Dialogs.saveFile("Exportar ficha HTML", stream, nome .. "_ND.html", "text/html",
        function()
            showMessage("Ficha exportada com sucesso!");
        end
    );
end
