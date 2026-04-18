function exportarFichaHTML(sheet, selfForm)
    require("dialogs.lua");
    require("utils.lua");
    
    local LT = string.char(60);
    local GT = string.char(62);
    local AMP = string.char(38);
    
    local parts = {};
    local idx = 0;
    
    local function add(s)
        idx = idx + 1;
        parts[idx] = s;
    end
    
    local function esc(s)
        if s == nil then return ""; end
        s = tostring(s);
        s = string.gsub(s, AMP, AMP .. "amp;");
        s = string.gsub(s, LT, AMP .. "lt;");
        s = string.gsub(s, GT, AMP .. "gt;");
        return s;
    end
    
    local function v(field)
        local val = sheet[field];
        if val == nil then return ""; end
        return tostring(val);
    end
    
    local function row(label, field)
        local val = v(field);
        if val == "" then return; end
        add(LT .. "tr" .. GT .. LT .. "td class='l'" .. GT .. esc(label) .. LT .. "/td" .. GT .. LT .. "td" .. GT .. esc(val) .. LT .. "/td" .. GT .. LT .. "/tr" .. GT);
    end
    
    local function h2(titulo)
        add(LT .. "h2" .. GT .. esc(titulo) .. LT .. "/h2" .. GT);
    end
    
    local function h3(titulo)
        add(LT .. "h3" .. GT .. esc(titulo) .. LT .. "/h3" .. GT);
    end
    
    local function pre(texto)
        add(LT .. "pre" .. GT .. esc(texto) .. LT .. "/pre" .. GT);
    end
    
    local function tableOpen()
        add(LT .. "table" .. GT);
    end
    
    local function tableClose()
        add(LT .. "/table" .. GT);
    end
    
    local function getText(ctrl)
        if ctrl == nil then return ""; end
        local ok, txt = pcall(function() return ctrl:getText(); end);
        if ok and txt then return txt; end
        return "";
    end
    
    -- HEAD
    add(LT .. "!DOCTYPE html" .. GT);
    add(LT .. "html" .. GT .. LT .. "head" .. GT);
    add(LT .. "meta charset='utf-8'" .. "/" .. GT);
    add(LT .. "title" .. GT .. "Ficha ND - " .. esc(v("nome")) .. LT .. "/title" .. GT);
    add(LT .. "style" .. GT);
    add("body{background:#080C14;color:#E2E8F0;font-family:Segoe UI,sans-serif;padding:20px;max-width:900px;margin:0 auto}");
    add("h1{color:#F97316;text-align:center;border-bottom:2px solid #F97316;padding-bottom:10px}");
    add("h2{color:#F97316;margin-top:25px;border-bottom:1px solid #333}");
    add("h3{color:#D97706;margin-top:15px}");
    add("table{width:100%;border-collapse:collapse;margin-bottom:15px}");
    add("td,th{padding:4px 8px;border:1px solid #1A2A3A;text-align:left}");
    add(".l{width:180px;color:#94A3B8;font-weight:bold;background:#0F172A}");
    add("pre{background:#0F172A;padding:10px;border:1px solid #1A2A3A;white-space:pre-wrap;font-size:12px;color:#CBD5E1}");
    add(LT .. "/style" .. GT);
    add(LT .. "/head" .. GT);
    
    -- BODY
    add(LT .. "body" .. GT);
    add(LT .. "h1" .. GT .. "Ficha Naruto Destiny - " .. esc(v("nome")) .. LT .. "/h1" .. GT);
    
    -- Dados Pessoais
    h2("Dados Pessoais");
    tableOpen();
    row("Nome", "nome");
    row("Idade", "idade");
    row("Sexo", "sexo");
    row("Altura", "altura");
    row("Peso", "peso");
    row("Tipo Sanguineo", "tipo_sanguineo");
    row("Aniversario", "aniversario");
    row("Vila de Nascimento", "vila_nascimento");
    row("Cla Ninja", "cla_ninja");
    row("Rank Shinobi", "rank_shinobi");
    row("Sensei", "sensei");
    row("Organizacao", "organizacao");
    row("Natureza", "natureza");
    row("Mao Dominante", "mao_dominante");
    row("Nivel", "nivel");
    row("Kekkei Genkai", "kekkei_genkai");
    tableClose();
    
    -- Personalidade
    h2("Personalidade");
    tableOpen();
    row("Comportamento", "comportamento");
    row("Objetivo", "objetivo");
    row("Sonho", "sonho");
    row("Gostos", "gostos");
    row("Desgostos", "desgostos");
    row("Hobbies", "hobbies");
    row("Interesse Romantico", "interesse_romantico");
    tableClose();
    
    -- Atributos Core
    h2("Atributos Core");
    tableOpen();
    row("Forca", "forca");
    row("Agilidade", "agilidade");
    row("Constituicao", "constituicao");
    row("Destreza", "destreza");
    row("Ctrl Chakra", "ctrl_chakra");
    row("Concentracao", "concentracao");
    row("Inteligencia", "inteligencia");
    row("Forca Espiritual", "forca_espiritual");
    tableClose();
    
    -- Status
    h2("Status");
    tableOpen();
    row("PV", "pv");
    row("PV Atual", "pv_atual");
    row("Chakra", "pchakra");
    row("Chakra Atual", "pchakra_atual");
    row("Estamina", "pestamina");
    row("Estamina Atual", "pestamina_atual");
    row("Ryous", "ryous");
    tableClose();
    
    -- Atributos de Combate
    h2("Atributos de Combate");
    tableOpen();
    row("Taijutsu", "taijutsu");
    row("Bukijutsu", "bukijutsu");
    row("Ninjutsu", "ninjutsu");
    row("Genjutsu", "genjutsu");
    row("Genjutsu Kai", "genjutsu_kai");
    row("Fuinjutsu", "fuinjutsu");
    row("Arremesso", "arremesso");
    row("Esquiva", "esquiva");
    row("Bloqueio Fisico", "bloqueio_fisico");
    row("Bloqueio Chakra", "bloqueio_chakra");
    row("Reflexo", "reflexo");
    row("Iniciativa", "iniciativa");
    row("Tai-Bukijutsu", "tai_bukijutsu");
    row("Nin-Taijutsu", "nin_taijutsu");
    row("Hiraishin", "hiraishin");
    row("Movimentacao", "movimentacao");
    tableClose();
    
    -- Pericias
    h2("Pericias");
    tableOpen();
    row("Sobrevivencia", "sobrevivencia");
    row("Armadilha", "armadilha");
    row("Empatia", "empatia");
    row("Intimidacao", "intimidacao");
    row("Ladinagem", "ladinagem");
    row("Enganacao", "enganacao");
    row("Percepcao", "percepcao");
    row("Persuasao", "persuasao");
    row("Seducao", "seducao");
    row("Medicina", "medicina");
    row("Conhecimento", "conhecimento");
    row("Oficio", "oficio");
    row("Ensinamento", "ensinamento");
    row("Aprendizado", "aprendizado");
    tableClose();
    
    -- Elementos
    h2("Elementos");
    tableOpen();
    row("Fogo", "elem_fogo");
    row("Agua", "elem_agua");
    row("Vento", "elem_vento");
    row("Terra", "elem_terra");
    row("Raio", "elem_raio");
    row("Combo", "elem_combo");
    tableClose();
    
    -- Qualidades e Defeitos
    h2("Qualidades e Defeitos");
    tableOpen();
    row("Qualidade 1", "qualidade1");
    row("Defeito 1", "defeito1");
    row("Qualidade 2", "qualidade2");
    row("Defeito 2", "defeito2");
    row("Qualidade 3", "qualidade3");
    row("Defeito 3", "defeito3");
    row("Qualidade 4", "qualidade4");
    row("Defeito 4", "defeito4");
    row("Qualidade 5", "qualidade5");
    row("Defeito 5", "defeito5");
    tableClose();
    
    -- Traits
    h2("Traits");
    add(LT .. "p" .. GT .. esc(v("trait_resumo")) .. LT .. "/p" .. GT);
    local traitTxt = getText(selfForm.edtTraits);
    if traitTxt ~= "" then
        pre(traitTxt);
    end
    
    -- Tecnicas
    h2("Tecnicas");
    add(LT .. "p" .. GT .. esc(v("jutsu_pontos_atual")) .. " / " .. esc(v("jutsu_pontos_max")) .. " Pontos de Jutsu" .. LT .. "/p" .. GT);
    
    local tecNames = {"Taijutsu","Bukijutsu","Ninjutsu","Elemental","Fuinjutsu","Kuchiyose","Kekkei Genkai","Hab. Gerais"};
    local tecEdits = {
        selfForm.edtTecTaijutsu, selfForm.edtTecBukijutsu,
        selfForm.edtTecNinjutsu, selfForm.edtTecElemental,
        selfForm.edtTecFuinjutsu, selfForm.edtTecKuchiyose,
        selfForm.edtTecKekkei, selfForm.edtTecGerais
    };
    
    for i = 1, #tecNames do
        local txt = getText(tecEdits[i]);
        if txt ~= "" then
            h3(tecNames[i]);
            pre(txt);
        end
    end
    
    -- Inventario
    local invTxt = getText(selfForm.edtInventario);
    if invTxt ~= "" then
        h2("Inventario");
        pre(invTxt);
    end
    
    -- Historia
    local histTxt = getText(selfForm.edtHistoria);
    if histTxt ~= "" then
        h2("Historia");
        pre(histTxt);
    end
    
    -- Footer
    add(LT .. "div style='text-align:center;color:#4B5563;margin-top:30px;font-size:11px'" .. GT .. "Exportado de Naruto Destiny - Firecast" .. LT .. "/div" .. GT);
    add(LT .. "/body" .. GT);
    add(LT .. "/html" .. GT);
    
    -- Juntar tudo
    local html = table.concat(parts, "\n");
    
    local stream = utils.newMemoryStream();
    stream:writeBinary("utf8", html);
    stream.position = 0;
    
    local nome = v("nome");
    if nome == "" then nome = "Ficha"; end
    
    Dialogs.saveFile("Exportar ficha HTML", stream, nome .. "_ND.html", "text/html",
        function()
            showMessage("Ficha exportada com sucesso!");
        end
    );
end
