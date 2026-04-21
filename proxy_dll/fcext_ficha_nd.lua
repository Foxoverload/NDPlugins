-- ============================================================
-- FCEXT Ficha ND Avancada v1.0
-- Ficha de personagem Naruto Destiny com design moderno
-- Powered by Firecast Script Extender + fcext_ui.lua
-- ============================================================

local function criarFichaAvancada(sheet, parentForm)
    -- Load UI library (auto-discover path)
    local fcext = require("fcext");
    
    local function findScript(name)
        local candidates = {};
        pcall(function()
            local ad = os.getenv("LOCALAPPDATA");
            if ad then table.insert(candidates, ad .. "\\Firecast\\" .. name); end;
        end);
        pcall(function()
            local up = os.getenv("USERPROFILE");
            if up then table.insert(candidates, up .. "\\AppData\\Local\\Firecast\\" .. name); end;
        end);
        -- Scan user directories
        local drives = {"C", "D"};
        for _, drv in ipairs(drives) do
            local ok2, users = pcall(fcext.listDir, drv .. ":\\Users");
            if ok2 and users then
                for _, u in ipairs(users) do
                    if u ~= "Public" and u ~= "Default" and u ~= "Default User" and u ~= "All Users" then
                        local p = drv .. ":\\Users\\" .. u .. "\\AppData\\Local\\Firecast\\" .. name;
                        if fcext.fileExists(p) then table.insert(candidates, 1, p); end;
                    end;
                end;
            end;
        end;
        for _, path in ipairs(candidates) do
            if fcext.fileExists(path) then
                local code = fcext.readFile(path);
                if code then return code; end;
            end;
        end;
        return nil;
    end;
    
    local uiCode = findScript("fcext_ui.lua");
    if not uiCode then return "ERRO: fcext_ui.lua nao encontrado"; end;
    local ui = load(uiCode)();
    if not ui then return "ERRO: falha ao carregar ui"; end;

    local t = ui.t();

    -- Helper: read sheet field safely
    local function sf(field)
        if sheet == nil then return ""; end;
        local ok, val = pcall(function() return sheet[field]; end);
        if ok and val ~= nil then return tostring(val); end;
        return "";
    end;

    local function sfn(field)
        return tonumber(sf(field)) or 0;
    end;

    -- Forward declarations for calculation functions
    -- (implemented below, after UI creation)
    local calcularAtributos;
    local atualizarBarras;
    local calcularKuchiyose;
    local contarPontosJutsu;
    local validarInterpretativos;
    local calcularTraits;

    -- ========== MAIN CONTAINER ==========
    -- Instead of creating a popup, we attach to the provided parentForm
    local content = parentForm;
    if not content then return "ERRO: parentForm nulo"; end;

    -- Clear previous content if any (to avoid duplicates on reload)
    pcall(function()
        if content.layoutConteudo then
            content.layoutConteudo:destroy();
        end
    end)

    local mainLayout = GUI.newLayout();
    mainLayout.parent = content;
    mainLayout.align = "client";
    mainLayout.name = "layoutConteudo";

    -- Theme background
    local bg = GUI.newRectangle();
    bg.parent = mainLayout;
    bg.align = "client";
    bg.color = "#121212"; -- Base dark theme background

    -- ========== BANNER ==========
    local bannerBox = GUI.newLayout();
    bannerBox.parent = mainLayout;
    bannerBox.align = "top";
    bannerBox.height = 75;
    bannerBox.margins = {left = 10, right = 10, top = 8, bottom = 4};

    local bannerBg = GUI.newRectangle();
    bannerBg.parent = bannerBox;
    bannerBg.align = "client";
    bannerBg.color = "#0A0E17";
    bannerBg.strokeColor = "#F97316";
    bannerBg.strokeSize = 2;
    bannerBg.xradius = 10;
    bannerBg.yradius = 10;

    -- Banner image
    pcall(function()
        local bannerImg = GUI.newImage();
        bannerImg.parent = bannerBox;
        bannerImg.align = "client";
        bannerImg.style = "stretch";
        bannerImg.src = "/images/top_banner.png";
        bannerImg.opacity = 0.3;
    end);

    local bannerTitle = GUI.newLabel();
    bannerTitle.parent = bannerBox;
    bannerTitle.align = "client";
    bannerTitle.text = "N A R U T O   D E S T I N Y";
    bannerTitle.horzTextAlign = "center";
    bannerTitle.vertTextAlign = "center";
    bannerTitle.fontColor = "#F97316";
    bannerTitle.fontSize = 26;
    bannerTitle.fontStyle = "bold";

    -- Subtitle with character name
    local nomeChar = sf("nome");
    if nomeChar ~= "" then
        local subTitle = GUI.newLabel();
        subTitle.parent = bannerBox;
        subTitle.align = "bottom";
        subTitle.height = 22;
        subTitle.text = nomeChar;
        subTitle.horzTextAlign = "center";
        subTitle.fontColor = "#FBBF24";
        subTitle.fontSize = 14;
        subTitle.fontStyle = "bold";
    end;

    -- ========== TAB CONTROL ==========
    local tabs = GUI.newTabControl();
    tabs.parent = mainLayout;
    tabs.align = "client";
    tabs.margins = {left = 8, right = 8, top = 4, bottom = 8};

    -- ==========================================
    -- TAB 1: PERFIL
    -- ==========================================
    local tab1 = GUI.newTab();
    tab1.parent = tabs;
    tab1.title = "Perfil";

    local scroll1 = GUI.newScrollBox();
    scroll1.parent = tab1;
    scroll1.align = "client";

    -- --- Status Bars (top of profile) ---
    local statusCard = ui.card(scroll1, {
        title = "Status",
        height = 150,
        headerColor = "#0D1B2A",
        borderColor = "#1E3A5C",
        margins = {top = 6, left = 6, right = 6},
    });
    local statusBody = statusCard._body;

    -- Helper function to create a status bar row
    local function criarBarraStatus(parent, label, color, bgColor, fieldAtual, fieldMax, extraMaxCalc)
        local row = GUI.newLayout();
        row.parent = parent;
        row.align = "top";
        row.height = 24;
        row.margins = {top = 2};

        -- Label (HP/Chakra/etc)
        local lbl = GUI.newLabel();
        lbl.parent = row;
        lbl.align = "left";
        lbl.width = 55;
        lbl.text = label;
        lbl.fontColor = color;
        lbl.fontSize = 12;
        lbl.fontStyle = "bold";
        lbl.horzTextAlign = "trailing";
        lbl.margins = {right = 4};

        -- Editable current value
        local editAtual = GUI.newEdit();
        editAtual.parent = row;
        editAtual.align = "left";
        editAtual.width = 45;
        editAtual.fontColor = "white";
        editAtual.fontSize = 11;
        editAtual.horzTextAlign = "center";
        pcall(function() editAtual.field = fieldAtual; end);
        pcall(function() editAtual.transparent = true; end);
        editAtual:addEventListener("onChange", function()
            if atualizarBarras then atualizarBarras(); end;
        end);

        -- Separator " / "
        local sep = GUI.newLabel();
        sep.parent = row;
        sep.align = "left";
        sep.width = 12;
        sep.text = "/";
        sep.fontColor = "#71717A";
        sep.fontSize = 11;
        sep.horzTextAlign = "center";

        -- Max value (read-only label)
        local lblMax = GUI.newLabel();
        lblMax.parent = row;
        lblMax.align = "left";
        lblMax.width = 40;
        lblMax.fontColor = "#A1A1AA";
        lblMax.fontSize = 11;
        lblMax.horzTextAlign = "center";
        if fieldMax then
            pcall(function() lblMax.field = fieldMax; end);
        end;

        -- Progress bar container
        local barBox = GUI.newLayout();
        barBox.parent = row;
        barBox.align = "client";
        barBox.margins = {top = 3, bottom = 3, right = 10};

        local barBg = GUI.newRectangle();
        barBg.parent = barBox;
        barBg.align = "client";
        barBg.color = bgColor;
        barBg.xradius = 6;
        barBg.yradius = 6;

        local bar = GUI.newProgressBar();
        bar.parent = barBox;
        bar.align = "client";
        bar.min = 0;
        bar.max = math.max(sfn(fieldMax or ""), 1);
        bar.position = sfn(fieldAtual);
        bar.color = color;
        pcall(function() bar.mouseGlow = true; end);
        pcall(function() bar.field = fieldAtual; end);
        if fieldMax then
            pcall(function() bar.fieldMax = fieldMax; end);
        end;

        return {row = row, bar = bar, lblMax = lblMax, editAtual = editAtual};
    end;

    -- Create the 4 status bars
    local hp = criarBarraStatus(statusBody, "HP", "#EF4444", "#1A0A10", "pv_atual", "pv");
    local ck = criarBarraStatus(statusBody, "Chakra", "#818CF8", "#0A0A1A", "pchakra_atual", "pchakra");
    local st = criarBarraStatus(statusBody, "Stamina", "#22C55E", "#0A1A0A", "pestamina_atual", "pestamina");
    local xp = criarBarraStatus(statusBody, "XP", "#A855F7", "#120A1A", "xp_atual", "xp_max");

    -- Expose bar/val references for atualizarBarras
    local hpBar = hp.bar;
    local hpVal = hp.lblMax;
    local ckBar = ck.bar;
    local ckVal = ck.lblMax;
    local stBar = st.bar;
    local stVal = st.lblMax;

    -- --- Dados Pessoais ---
    ui.section(scroll1, {text = "Dados Pessoais", margins = {top = 10, bottom = 4}});

    -- Two-column layout
    local perfilRow = GUI.newLayout();
    perfilRow.parent = scroll1;
    perfilRow.align = "top";
    perfilRow.height = 240;
    perfilRow.margins = {left = 6, right = 6};

    -- Left column: avatar
    local avatarCol = GUI.newLayout();
    avatarCol.parent = perfilRow;
    avatarCol.align = "left";
    avatarCol.width = 200;

    local avatarBg = GUI.newRectangle();
    avatarBg.parent = avatarCol;
    avatarBg.align = "client";
    avatarBg.color = "#0E1420";
    avatarBg.strokeColor = "#F97316";
    avatarBg.strokeSize = 1;
    avatarBg.xradius = 10;
    avatarBg.yradius = 10;
    avatarBg.margins = {left = 4, right = 4, top = 4, bottom = 4};

    local avatarImg = GUI.newImage();
    avatarImg.parent = avatarCol;
    avatarImg.align = "client";
    avatarImg.margins = {left = 8, right = 8, top = 8, bottom = 8};
    pcall(function() avatarImg.style = "autoFit"; end);
    pcall(function() avatarImg.field = "aparencia_img1"; end);
    pcall(function() avatarImg.editable = true; end);

    -- Right column: info fields
    local infoCol = GUI.newLayout();
    infoCol.parent = perfilRow;
    infoCol.align = "client";
    infoCol.margins = {left = 10};

    local campos = {
        {"Nome", "nome"},
        {"Idade", "idade"},
        {"Vila", "vila_nascimento"},
        {"Cla", "cla_ninja"},
        {"Kekkei Genkai", "kekkei_genkai"},
        {"Sensei", "sensei"},
        {"Kuchiyose", "kuchiyose"},
    };
    for _, c in ipairs(campos) do
        ui.field(infoCol, {label = c[1], field = c[2], labelWidth = 110, margins = {top = 1}});
    end;

    -- Rank + Level row
    local rankRow = GUI.newLayout();
    rankRow.parent = scroll1;
    rankRow.align = "top";
    rankRow.height = 28;
    rankRow.margins = {left = 6, right = 6, top = 4};

    local rankLabel = GUI.newLabel();
    rankLabel.parent = rankRow;
    rankLabel.align = "left";
    rankLabel.width = 120;
    rankLabel.text = "  Rank:";
    rankLabel.fontColor = "#8BA3C4";
    rankLabel.fontSize = 13;

    local rankVal = GUI.newLabel();
    rankVal.parent = rankRow;
    rankVal.align = "left";
    rankVal.width = 200;
    rankVal.text = sf("rank_shinobi");
    rankVal.fontColor = "#FBBF24";
    rankVal.fontSize = 16;
    rankVal.fontStyle = "bold";

    local nivelLabel = GUI.newLabel();
    nivelLabel.parent = rankRow;
    nivelLabel.align = "left";
    nivelLabel.width = 80;
    nivelLabel.text = "Nivel:";
    nivelLabel.fontColor = "#8BA3C4";
    nivelLabel.fontSize = 13;
    nivelLabel.horzTextAlign = "trailing";
    nivelLabel.margins = {right = 10};

    local nivelVal = GUI.newLabel();
    nivelVal.parent = rankRow;
    nivelVal.align = "left";
    nivelVal.width = 50;
    nivelVal.text = sf("nivel");
    nivelVal.fontColor = "#FBBF24";
    nivelVal.fontSize = 16;
    nivelVal.fontStyle = "bold";

    -- Elementos toggle buttons
    local function criarToggleElem(parent, elem)
        local isActive = (sf(elem.field) == "true");

        local container = GUI.newLayout();
        container.parent = parent;
        container.align = "left";
        container.width = 72;
        container.height = 26;
        container.margins = {right = 4, top = 3};

        -- Visual pill background
        local bg = GUI.newRectangle();
        bg.parent = container;
        bg.align = "client";
        bg.color = isActive and elem.color or "#1A2332";
        bg.strokeColor = elem.color;
        bg.strokeSize = 1;
        bg.xradius = 13;
        bg.yradius = 13;

        -- Visual text
        local lbl = GUI.newLabel();
        lbl.parent = container;
        lbl.align = "client";
        lbl.horzTextAlign = "center";
        lbl.vertTextAlign = "center";
        lbl.text = elem.name;
        lbl.fontSize = 11;
        lbl.fontStyle = "bold";
        lbl.fontColor = isActive and "white" or "#556677";

        -- Invisible checkbox on top for click handling
        local cb = GUI.newCheckBox();
        cb.parent = container;
        cb.align = "client";
        cb.field = elem.field;
        cb.text = "";
        cb.opacity = 0;
        cb.cursor = "handPoint";

        -- Update visual when checkbox changes
        local fieldName = elem.field;
        local activeColor = elem.color;
        cb.onChange = function()
            local active = (tostring(sheet[fieldName]) == "true");
            bg.color = active and activeColor or "#1A2332";
            lbl.fontColor = active and "white" or "#556677";
        end;
    end

    -- Linha 1: Basicos
    local elemRow1 = GUI.newLayout();
    elemRow1.parent = scroll1;
    elemRow1.align = "top";
    elemRow1.height = 32;
    elemRow1.margins = {left = 6, right = 6, top = 4};

    local elemLabel = GUI.newLabel();
    elemLabel.parent = elemRow1;
    elemLabel.align = "left";
    elemLabel.width = 75;
    elemLabel.text = "Elementos:";
    elemLabel.fontColor = "#8BA3C4";
    elemLabel.fontSize = 12;

    local basicos = {
        {field = "elem_fogo",  name = "Katon",   color = "#EA580C"},
        {field = "elem_agua",  name = "Suiton",  color = "#0EA5E9"},
        {field = "elem_terra", name = "Doton",   color = "#A16207"},
        {field = "elem_vento", name = "Futon",   color = "#2DD4BF"},
        {field = "elem_raio",  name = "Raiton",  color = "#FACC15"},
    };
    for _, elem in ipairs(basicos) do
        criarToggleElem(elemRow1, elem);
    end

    -- Linha 2: Avancados
    local elemRow2 = GUI.newLayout();
    elemRow2.parent = scroll1;
    elemRow2.align = "top";
    elemRow2.height = 32;
    elemRow2.margins = {left = 81, right = 6, top = 0};

    local avancados = {
        {field = "elem_hyoton",   name = "Hyoton",   color = "#7DD3FC"},
        {field = "elem_mokuton",  name = "Mokuton",  color = "#4ADE80"},
        {field = "elem_yoton",    name = "Yoton",    color = "#FB923C"},
        {field = "elem_futton",   name = "Futton",   color = "#F472B6"},
        {field = "elem_shakuton", name = "Shakuton", color = "#F87171"},
        {field = "elem_ranton",   name = "Ranton",   color = "#A78BFA"},
        {field = "elem_bakuton",  name = "Bakuton",  color = "#FCD34D"},
        {field = "elem_jiton",    name = "Jiton",    color = "#94A3B8"},
        {field = "elem_shoton",   name = "Shoton",   color = "#E879F9"},
        {field = "elem_jinton",   name = "Jinton",   color = "#FDE68A"},
        {field = "elem_enton",    name = "Enton",    color = "#EF4444"},
    };
    for _, elem in ipairs(avancados) do
        criarToggleElem(elemRow2, elem);
    end

    -- Combo elemental (auto-calculado)
    local comboElem = sf("elem_combo");
    if comboElem ~= "" and comboElem ~= "Nenhuma" then
        ui.label(scroll1, {text = "  Combo: " .. comboElem, color = "#FDBA74", fontSize = 11, bold = true, italic = true, margins = {left = 6, top = 1}});
    end;

    -- ==========================================
    -- TRAITS (Bonuses Automaticos)
    -- ==========================================
    ui.section(scroll1, {text = "Traits", margins = {top = 4, bottom = 4}});

    -- Trait point counter bar (Trait [ X / Y ])
    local traitResumoRow = GUI.newLayout();
    traitResumoRow.parent = scroll1;
    traitResumoRow.align = "top";
    traitResumoRow.height = 30;
    traitResumoRow.margins = {left = 6, right = 6, top = 2, bottom = 2};

    local traitResumoBg = GUI.newRectangle();
    traitResumoBg.parent = traitResumoRow;
    traitResumoBg.align = "client";
    traitResumoBg.color = "#0C1828";
    traitResumoBg.strokeColor = "#F97316";
    traitResumoBg.strokeSize = 2;
    traitResumoBg.xradius = 8;
    traitResumoBg.yradius = 8;

    local traitResumoLabel = GUI.newLabel();
    traitResumoLabel.parent = traitResumoRow;
    traitResumoLabel.align = "client";
    traitResumoLabel.horzTextAlign = "center";
    traitResumoLabel.vertTextAlign = "center";
    traitResumoLabel.fontStyle = "bold";
    traitResumoLabel.fontColor = "white";
    traitResumoLabel.fontSize = 15;
    traitResumoLabel.text = "Trait [ 0 / 0 ]";
    pcall(function() traitResumoLabel.field = "trait_resumo"; end);

    -- Hint label
    ui.label(scroll1, {text = "  Formato: Nome do Trait (XXX pontos de Trait)  |  Bonus: [bonus: campo +N]", color = "#5E7FA0", fontSize = 10, italic = true, margins = {left = 6, top = 1, bottom = 1}});

    -- Bonus resumo
    local traitBonusLabel = GUI.newLabel();
    traitBonusLabel.parent = scroll1;
    traitBonusLabel.align = "top";
    traitBonusLabel.height = 18;
    traitBonusLabel.horzTextAlign = "center";
    traitBonusLabel.fontColor = "#38BDF8";
    traitBonusLabel.fontSize = 11;
    traitBonusLabel.fontStyle = "bold";
    pcall(function() traitBonusLabel.field = "trait_bonus_resumo"; end);

    -- Rich Text area for trait descriptions
    local traitTextBox = GUI.newLayout();
    traitTextBox.parent = scroll1;
    traitTextBox.align = "top";
    traitTextBox.height = 250;
    traitTextBox.margins = {left = 6, right = 6, top = 2, bottom = 6};

    local traitBorder = GUI.newRectangle();
    traitBorder.parent = traitTextBox;
    traitBorder.align = "client";
    traitBorder.color = t.bgAlt;
    traitBorder.strokeColor = t.border;
    traitBorder.strokeSize = 1;
    traitBorder.xradius = 6;
    traitBorder.yradius = 6;

    local edtTraits = ui.richEdit(traitTextBox, {field = "traits", align = "client", margins = {top = 4, bottom = 4, left = 4, right = 4}, onChange = function() if calcularTraits then calcularTraits(); end; end});

    -- Campos mecanicos de Traits (afetam calculos)
    ui.label(scroll1, {text = "  Modificadores Manuais:", color = t.textDim, fontSize = 11, italic = true, margins = {left = 6, top = 2}});
    local traitGrid1 = ui.grid(scroll1, {cols = 3, totalWidth = 900, height = 30, margins = {top = 2}});
    ui.attribute(traitGrid1._cols[1], {label = "Bonus PV (%)", field = "trait_pv", labelWidth = 110, onChange = function() calcularAtributos(); atualizarBarras(); end});
    ui.attribute(traitGrid1._cols[2], {label = "Bonus Chakra (%)", field = "trait_pchakra", labelWidth = 130, onChange = function() calcularAtributos(); atualizarBarras(); end});
    ui.attribute(traitGrid1._cols[3], {label = "Bonus Stamina (%)", field = "trait_pestamina", labelWidth = 135, onChange = function() calcularAtributos(); atualizarBarras(); end});

    -- Trait Combate - Tipo (combo selector)
    ui.spacer(scroll1, 6);
    local tcRow = GUI.newLayout();
    tcRow.parent = scroll1;
    tcRow.align = "top";
    tcRow.height = 30;
    tcRow.margins = {left = 6, right = 6};

    local tcLabel = GUI.newLabel();
    tcLabel.parent = tcRow;
    tcLabel.align = "left";
    tcLabel.width = 130;
    tcLabel.text = "Trait de Combate:";
    tcLabel.fontColor = t.textDim;
    tcLabel.fontSize = t.fontSize;
    tcLabel.horzTextAlign = "trailing";
    tcLabel.margins = {right = 10};

    local tcCombo = GUI.newComboBox();
    tcCombo.parent = tcRow;
    tcCombo.align = "left";
    tcCombo.width = 180;
    pcall(function() tcCombo.items = {"Nenhum", "Artes Marciais", "Dom. Armas", "Manip. Chakra", "Ilusionista", "Mente Blindada", "Bloqueador", "Intuicao"}; end);
    pcall(function() tcCombo.values = {"nenhum", "artmarcial", "domarmas", "manipchakra", "ilusionista", "menteblind", "bloqueador", "intuicao"}; end);
    pcall(function() tcCombo.field = "trait_combate_tipo"; end);
    tcCombo:addEventListener("onChange", function() calcularAtributos(); end);

    -- Trait Combate - Estagios (checkboxes)
    local tcStages = GUI.newLayout();
    tcStages.parent = scroll1;
    tcStages.align = "top";
    tcStages.height = 28;
    tcStages.margins = {left = 6, right = 6, top = 2};

    local tcStLabel = GUI.newLabel();
    tcStLabel.parent = tcStages;
    tcStLabel.align = "left";
    tcStLabel.width = 130;
    tcStLabel.text = "Estagios:";
    tcStLabel.fontColor = t.textDim;
    tcStLabel.fontSize = t.fontSize;
    tcStLabel.horzTextAlign = "trailing";
    tcStLabel.margins = {right = 10};

    for i = 1, 5 do
        local chkS = GUI.newCheckBox();
        chkS.parent = tcStages;
        chkS.align = "left";
        chkS.width = 35;
        chkS.text = tostring(i);
        chkS.fontColor = "#F59E0B";
        chkS.fontSize = 11;
        pcall(function() chkS.field = "trait_combate_s" .. i; end);
        chkS:addEventListener("onChange", function() calcularAtributos(); end);
    end;

    -- Kekkei Genkai / Sharingan Stages
    ui.spacer(scroll1, 6);
    local kkgRow = GUI.newLayout();
    kkgRow.parent = scroll1;
    kkgRow.align = "top";
    kkgRow.height = 28;
    kkgRow.margins = {left = 6, right = 6};

    local kkgLabel = GUI.newLabel();
    kkgLabel.parent = kkgRow;
    kkgLabel.align = "left";
    kkgLabel.width = 130;
    kkgLabel.text = "Sharingan:";
    kkgLabel.fontColor = "#EF4444";
    kkgLabel.fontSize = t.fontSize;
    kkgLabel.horzTextAlign = "trailing";
    kkgLabel.margins = {right = 10};

    local kkgNames = {"1 Tomoe", "2 Tomoe", "3 Tomoe"};
    for i = 1, 3 do
        local chkK = GUI.newCheckBox();
        chkK.parent = kkgRow;
        chkK.align = "left";
        chkK.width = 80;
        chkK.text = kkgNames[i];
        chkK.fontColor = "#EF4444";
        chkK.fontSize = 11;
        pcall(function() chkK.field = "kkg_sharingan" .. i; end);
        chkK:addEventListener("onChange", function() calcularAtributos(); end);
    end;

    -- KKG Ativo Label
    local kkgAtivo = GUI.newLabel();
    kkgAtivo.parent = kkgRow;
    kkgAtivo.align = "client";
    pcall(function() kkgAtivo.field = "kkg_ativos_label"; end);
    kkgAtivo.fontColor = "#F87171";
    kkgAtivo.fontSize = 11;
    kkgAtivo.fontStyle = "italic";
    kkgAtivo.margins = {left = 10};

    -- ==========================================
    -- TAB 2: ATRIBUTOS
    -- ==========================================
    local tab2 = GUI.newTab();
    tab2.parent = tabs;
    tab2.title = "Atributos";

    local scroll2 = GUI.newScrollBox();
    scroll2.parent = tab2;
    scroll2.align = "client";

    -- Core Attributes
    ui.section(scroll2, {text = "Atributos Core", margins = {top = 6, bottom = 4}});

    local coreAttrs = {
        {"Forca", "forca"},
        {"Agilidade", "agilidade"},
        {"Constituicao", "constituicao"},
        {"Destreza", "destreza"},
        {"Ctrl. Chakra", "ctrl_chakra"},
        {"Concentracao", "concentracao"},
        {"Inteligencia", "inteligencia"},
        {"Forca Espiritual", "forca_espiritual"},
    };

    for i = 1, #coreAttrs, 2 do
        local gridR = ui.grid(scroll2, {cols = 2, totalWidth = 900, height = 30, margins = {top = 1}});
        ui.attribute(gridR._cols[1], {label = coreAttrs[i][1], field = coreAttrs[i][2], labelWidth = 120, onChange = function() calcularAtributos(); atualizarBarras(); end});
        if coreAttrs[i+1] then
            ui.attribute(gridR._cols[2], {label = coreAttrs[i+1][1], field = coreAttrs[i+1][2], labelWidth = 120, onChange = function() calcularAtributos(); atualizarBarras(); end});
        end;
    end;

    -- Combat Attributes
    ui.section(scroll2, {text = "Atributos de Combate", margins = {top = 12, bottom = 4}});

    local combatAttrs = {
        {"Taijutsu", "taijutsu"},
        {"Bukijutsu", "bukijutsu"},
        {"Ninjutsu", "ninjutsu"},
        {"Genjutsu", "genjutsu"},
        {"Genjutsu Kai", "genjutsu_kai"},
        {"Fuinjutsu", "fuinjutsu"},
        {"Arremesso", "arremesso"},
        {"Esquiva", "esquiva"},
        {"Bloq. Fisico", "bloqueio_fisico"},
        {"Bloq. Chakra", "bloqueio_chakra"},
        {"Reflexo", "reflexo"},
        {"Iniciativa", "iniciativa"},
        {"Tai-Bukijutsu", "tai_bukijutsu"},
        {"Nin-Taijutsu", "nin_taijutsu"},
        {"Hiraishin", "hiraishin"},
        {"Movimentacao", "movimentacao"},
    };

    for i = 1, #combatAttrs, 2 do
        local gridR = ui.grid(scroll2, {cols = 2, totalWidth = 900, height = 30, margins = {top = 1}});
        ui.attribute(gridR._cols[1], {label = combatAttrs[i][1], field = combatAttrs[i][2], labelWidth = 120, readOnly = true});
        if combatAttrs[i+1] then
            ui.attribute(gridR._cols[2], {label = combatAttrs[i+1][1], field = combatAttrs[i+1][2], labelWidth = 120, readOnly = true});
        end;
    end;

    -- Atributos Interpretativos
    ui.section(scroll2, {text = "Atributos Interpretativos", margins = {top = 12, bottom = 4}});

    -- Contador de pontos interpretativos
    local interpResumoRow = GUI.newLayout();
    interpResumoRow.parent = scroll2;
    interpResumoRow.align = "top";
    interpResumoRow.height = 28;
    interpResumoRow.margins = {left = 6, right = 6, top = 2, bottom = 2};

    local interpResumoBg = GUI.newRectangle();
    interpResumoBg.parent = interpResumoRow;
    interpResumoBg.align = "client";
    interpResumoBg.color = "#0C1828";
    interpResumoBg.strokeColor = "#F97316";
    interpResumoBg.strokeSize = 2;
    interpResumoBg.xradius = 8;
    interpResumoBg.yradius = 8;

    local interpResumoLabel = GUI.newLabel();
    interpResumoLabel.parent = interpResumoRow;
    interpResumoLabel.align = "client";
    interpResumoLabel.horzTextAlign = "center";
    interpResumoLabel.vertTextAlign = "center";
    interpResumoLabel.fontStyle = "bold";
    interpResumoLabel.fontColor = "white";
    interpResumoLabel.fontSize = 14;
    interpResumoLabel.text = "Pontos Interp.: 0 / 0";
    pcall(function() interpResumoLabel.field = "interp_uso_resumo"; end);

    -- Regra de limites
    ui.label(scroll2, {text = "  Regra: 1 atributo max 10  |  2 atributos max 8  |  Demais max 7", color = "#5E7FA0", fontSize = 10, italic = true, margins = {left = 6, top = 1, bottom = 2}});

    -- Aviso de correcao automatica
    local avisoInterpLabel = GUI.newLabel();
    avisoInterpLabel.parent = scroll2;
    avisoInterpLabel.align = "top";
    avisoInterpLabel.height = 16;
    avisoInterpLabel.horzTextAlign = "center";
    avisoInterpLabel.fontColor = "#EF4444";
    avisoInterpLabel.fontSize = 11;
    avisoInterpLabel.fontStyle = "bold";
    pcall(function() avisoInterpLabel.field = "aviso_interp"; end);

    local pericias = {
        {"Sobrevivencia", "sobrevivencia"},
        {"Armadilhas", "armadilha"},
        {"Empatia", "empatia"},
        {"Intimidacao", "intimidacao"},
        {"Ladinagem", "ladinagem"},
        {"Enganacao", "enganacao"},
        {"Percepcao", "percepcao"},
        {"Persuasao", "persuasao"},
        {"Seducao", "seducao"},
        {"Medicina", "medicina"},
        {"Historia", "historia_attr"},
        {"Oficio", "oficio"},
        {"Conhecimento", "conhecimento"},
        {"Aprendizado", "aprendizado"},
        {"Ensinamento", "ensinamento"},
    };

    for i = 1, #pericias, 2 do
        local gridR = ui.grid(scroll2, {cols = 2, totalWidth = 900, height = 28, margins = {top = 1}});
        ui.attribute(gridR._cols[1], {label = pericias[i][1], field = pericias[i][2], labelWidth = 120, valueWidth = 45, onChange = function() calcularAtributos(); end});
        if pericias[i+1] then
            ui.attribute(gridR._cols[2], {label = pericias[i+1][1], field = pericias[i+1][2], labelWidth = 120, valueWidth = 45, onChange = function() calcularAtributos(); end});
        end;
    end;

    -- ==========================================
    -- TAB 3: APARENCIA
    -- ==========================================
    local tab3 = GUI.newTab();
    tab3.parent = tabs;
    tab3.title = "Aparencia";

    local scroll3 = GUI.newScrollBox();
    scroll3.parent = tab3;
    scroll3.align = "client";

    ui.section(scroll3, {text = "Galeria do Personagem", margins = {top = 6, bottom = 4}});

    local imgGrid = ui.grid(scroll3, {cols = 6, totalWidth = 1800, height = 250, margins = {top = 6, left = 4, right = 4}});

    for idx = 1, 6 do
        local col = imgGrid._cols[idx];

        local imgTitle = GUI.newLabel();
        imgTitle.parent = col;
        imgTitle.align = "top";
        imgTitle.height = 20;
        imgTitle.text = "Imagem " .. idx;
        imgTitle.fontColor = "#F97316";
        imgTitle.fontSize = 11;
        imgTitle.fontStyle = "bold";

        local imgBg = GUI.newRectangle();
        imgBg.parent = col;
        imgBg.align = "client";
        imgBg.color = "#0E1420";
        imgBg.strokeColor = "#1E3A5C";
        imgBg.strokeSize = 1;
        imgBg.xradius = 4;
        imgBg.yradius = 4;

        local img = GUI.newImage();
        img.parent = col;
        img.align = "client";
        pcall(function() img.style = "autoFit"; end);
        pcall(function() img.field = "aparencia_img" .. idx; end);
        pcall(function() img.editable = true; end);
    end;

    -- Personalidade section
    ui.section(scroll3, {text = "Personalidade", margins = {top = 10, bottom = 4}});

    local persFields = {
        {"Gostos", "gostos"},
        {"Desgostos", "desgostos"},
        {"Hobbies", "hobbies"},
        {"Sonho", "sonho"},
        {"Objetivo", "objetivo"},
    };
    for _, pf in ipairs(persFields) do
        ui.field(scroll3, {label = pf[1], field = pf[2], labelWidth = 100, margins = {top = 1, left = 6, right = 6}});
    end;

    -- Familia
    ui.section(scroll3, {text = "Familia e Amigos", margins = {top = 10, bottom = 4}});

    local famFields = {
        {"Pais", "familia_pais"},
        {"Irmaos", "familia_irmaos"},
        {"Amigos", "familia_amigos"},
        {"Inimigos", "familia_inimigos"},
    };
    for _, ff in ipairs(famFields) do
        ui.field(scroll3, {label = ff[1], field = ff[2], labelWidth = 100, margins = {top = 1, left = 6, right = 6}});
    end;

    -- ==========================================
    -- TAB 4: TECNICAS
    -- ==========================================
    local tab4 = GUI.newTab();
    tab4.parent = tabs;
    tab4.title = "Tecnicas";

    local scroll4 = GUI.newScrollBox();
    scroll4.parent = tab4;
    scroll4.align = "client";

    -- Pontos de Jutsu Header
    local pJutsuRow = GUI.newLayout();
    pJutsuRow.parent = scroll4;
    pJutsuRow.align = "top";
    pJutsuRow.height = 36;
    pJutsuRow.margins = {left = 10, right = 10, top = 8, bottom = 4};

    local pJutsuBg = GUI.newRectangle();
    pJutsuBg.parent = pJutsuRow;
    pJutsuBg.align = "client";
    pJutsuBg.color = "#0C1828";
    pJutsuBg.strokeColor = "#60A5FA";
    pJutsuBg.strokeSize = 1;
    pJutsuBg.xradius = 8;
    pJutsuBg.yradius = 8;

    ui.label(pJutsuRow, {align = "left", width = 140, text = "  Pontos de Jutsu:", color = "#60A5FA", bold = true});
    local lblJPAtual = ui.label(pJutsuRow, {align = "left", width = 60, field = "jutsu_pontos_atual", color = "#FBBF24", bold = true, textAlign = "center"});
    ui.label(pJutsuRow, {align = "left", width = 20, text = " / ", color = "#7A94B0", textAlign = "center"});
    local lblJPMax = ui.label(pJutsuRow, {align = "left", width = 60, field = "jutsu_pontos_max", color = "#34D399", bold = true, textAlign = "center"});
    local lblJPStatus = ui.label(pJutsuRow, {align = "client", field = "jutsu_status", color = "#F87171", italic = true, margins = {left = 10}});

    local tecTabs = GUI.newTabControl();
    tecTabs.parent = scroll4;
    tecTabs.align = "client";
    tecTabs.margins = {top = 4, left = 2, right = 2, bottom = 2};

    local tecCampos = {
        {"Taijutsu", "tec_taijutsu"},
        {"Bukijutsu", "tec_bukijutsu"},
        {"Ninjutsu", "tec_ninjutsu"},
        {"Genjutsu", "tec_genjutsu"},
        {"Elemental", "tec_elemental"},
        {"Fuinjutsu", "tec_fuinjutsu"},
        {"Kuchiyose", "tec_kuchiyose"},
        {"Kekkei Genkai", "tec_kekkei_genkai"},
        {"Hab. Gerais", "tec_habilidades_gerais"},
    };

    local editsTecnicas = {};
    local tecFieldNames = {};
    for _, tData in ipairs(tecCampos) do
        local tTab = GUI.newTab();
        tTab.parent = tecTabs;
        tTab.title = tData[1];
        local redit = ui.richEdit(tTab, {field = tData[2], align = "client", margins = {top = 4, bottom = 4}, onChange = function() if contarPontosJutsu then contarPontosJutsu(); end; end});
        table.insert(editsTecnicas, redit);
        table.insert(tecFieldNames, tData[2]);
    end;

    -- ==========================================
    -- TAB 5: INVENTARIO
    -- ==========================================
    local tab5 = GUI.newTab();
    tab5.parent = tabs;
    tab5.title = "Inventario";
    ui.richEdit(tab5, {field = "inventario_fmt", margins = {left = 8, right = 8, top = 8, bottom = 8}});

    -- ==========================================
    -- TAB 6: HISTORIA
    -- ==========================================
    local tab6 = GUI.newTab();
    tab6.parent = tabs;
    tab6.title = "Historia";
    ui.richEdit(tab6, {field = "historia_fmt", margins = {left = 8, right = 8, top = 8, bottom = 8}});

    -- ==========================================
    -- TAB 7: KUCHIYOSE
    -- ==========================================
    local tab7 = GUI.newTab();
    tab7.parent = tabs;
    tab7.title = "Kuchiyose";
    
    local scroll7 = GUI.newScrollBox();
    scroll7.parent = tab7;
    scroll7.align = "client";

    ui.section(scroll7, {text = "Ficha de Kuchiyose (Invocacao)", margins = {top = 6, bottom = 6}});
    
    local rowK1 = GUI.newLayout();
    rowK1.parent = scroll7;
    rowK1.align = "top";
    rowK1.height = 100;

    ui.field(rowK1, {label = "Nome", field = "kuchi_nome", labelWidth = 140});
    ui.field(rowK1, {label = "Especie", field = "kuchi_especie", labelWidth = 140});
    ui.field(rowK1, {label = "Rank", field = "kuchi_rank", items = {'D (-5)','C (-4)','B (-4)','A (-3)','S (-2)','SS (-1)','SS+ (0)'}, values = {'-5','-4','-4b','-3','-2','-1','0'}, labelWidth = 140});

    ui.section(scroll7, {text = "Atributos Core da Kuchiyose", margins = {top = 10, bottom = 6}});
    local kuchiCore = {
        {"Forca", "kuchi_forca"}, {"Agilidade", "kuchi_agilidade"},
        {"Constituicao", "kuchi_constituicao"}, {"Destreza", "kuchi_destreza"},
        {"Ctrl Chakra", "kuchi_ctrl_chakra"}, {"Concentracao", "kuchi_concentracao"},
        {"Forca Espiritual", "kuchi_forca_espiritual"}, {"Inteligencia", "kuchi_inteligencia"},
    };
    for i = 1, #kuchiCore, 2 do
        local gridK = ui.grid(scroll7, {cols = 2, totalWidth = 900, height = 30, margins = {top = 1}});
        ui.attribute(gridK._cols[1], {label = kuchiCore[i][1], field = kuchiCore[i][2], labelWidth = 140});
        if kuchiCore[i+1] then
            ui.attribute(gridK._cols[2], {label = kuchiCore[i+1][1], field = kuchiCore[i+1][2], labelWidth = 140});
        end;
    end;

    ui.section(scroll7, {text = "Habilidades e Notas", margins = {top = 10, bottom = 6}});
    ui.richEdit(scroll7, {field = "kuchi_notas", height = 400, align = "top"});

    ui.spacer(scroll3, 20);

    -- ==========================================
    -- LOGICAS E CALCULOS
    -- ==========================================
    validarInterpretativos = function()
        local campos = {'sobrevivencia','armadilha','empatia','intimidacao','ladinagem','enganacao','percepcao','persuasao','seducao','medicina','historia_attr','oficio','conhecimento','aprendizado','ensinamento'}
        local valores = {}
        for i, campo in ipairs(campos) do
            valores[i] = tonumber(sheet[campo]) or 0
        end
        
        local ordenado = {}
        for i, v in ipairs(valores) do
            ordenado[i] = {idx = i, val = v}
        end
        table.sort(ordenado, function(a, b) return a.val > b.val end)
        
        local caps = {}
        for i = 1, #ordenado do
            if i == 1 then caps[ordenado[i].idx] = 10
            elseif i <= 3 then caps[ordenado[i].idx] = 8
            else caps[ordenado[i].idx] = 7 end
        end
        
        local corrigido = false
        for i, campo in ipairs(campos) do
            if valores[i] > caps[i] then
                sheet[campo] = tostring(caps[i])
                valores[i] = caps[i]
                corrigido = true
            end
        end
        
        if corrigido then
            sheet.aviso_interp = "Aviso: Valor corrigido! (max: 1x10, 2x8, demais 7)"
        else
            sheet.aviso_interp = ""
        end
        return valores
    end

    calcularTraits = function()
        if sheet == nil then return; end;

        -- Calcular o maximo baseado no nivel
        local nivel = tonumber(sheet.nivel) or 0;
        local max = 450 + (nivel * 10);

        -- Ler o texto do richEdit de traits (multiplos fallbacks)
        local gasto = 0;
        local texto = "";

        -- Tentativa 1: .text property do controle
        if edtTraits ~= nil and texto == "" then
            pcall(function() texto = edtTraits.text or ""; end);
        end
        -- Tentativa 2: getText() do controle
        if edtTraits ~= nil and texto == "" then
            pcall(function() texto = edtTraits:getText() or ""; end);
        end
        -- Tentativa 3: getPlainText() do controle
        if edtTraits ~= nil and texto == "" then
            pcall(function() texto = edtTraits:getPlainText() or ""; end);
        end
        -- Tentativa 4: ler direto do campo NDB (contem HTML/RTF)
        if texto == "" then
            pcall(function() texto = tostring(sheet.traits) or ""; end);
        end

        -- Strip HTML tags para garantir leitura correta
        if texto ~= nil and texto ~= "" then
            local textoLimpo = texto;
            textoLimpo = textoLimpo:gsub("<br[^>]*>", "\n");
            textoLimpo = textoLimpo:gsub("</p>", "\n");
            textoLimpo = textoLimpo:gsub("</div>", "\n");
            textoLimpo = textoLimpo:gsub("</li>", "\n");
            textoLimpo = textoLimpo:gsub("<[^>]+>", "");
            textoLimpo = textoLimpo:gsub("&nbsp;", " ");
            textoLimpo = textoLimpo:gsub("&amp;", "&");
            textoLimpo = textoLimpo:gsub("&lt;", "<");
            textoLimpo = textoLimpo:gsub("&gt;", ">");
            texto = textoLimpo;
        end

        -- Procura todos os padroes '(NUMERO pontos de Trait)' case insensitive
        if texto ~= nil and texto ~= "" then
            for valor in string.gmatch(texto:lower(), "%((%d+)%s*pontos.-trait%)") do
                gasto = gasto + (tonumber(valor) or 0);
            end
        end

        -- Atualiza o label centralizado
        sheet.trait_resumo = "Trait [ " .. gasto .. " / " .. max .. " ]";

        -- === Parsear bonus de traits ===
        local camposCombate = {'taijutsu','bukijutsu','ninjutsu','genjutsu','genjutsu_kai','fuinjutsu','arremesso','esquiva','bloqueio_fisico','bloqueio_chakra','reflexo','iniciativa','tai_bukijutsu','nin_taijutsu','hiraishin','movimentacao'};
        local camposStatus  = {'pv','pchakra','pestamina'};

        local totaisBonus = {};
        for _, c in ipairs(camposCombate) do totaisBonus[c] = 0; end
        for _, c in ipairs(camposStatus)  do totaisBonus[c] = 0; end

        local textoLower = texto:lower();

        -- Flat: [bonus: CAMPO +/-N]
        for campo, sinal, valor in string.gmatch(textoLower, "%[b%o*nus:%s*([%a_]+)%s*([%+%-])(%d+)%]") do
            if totaisBonus[campo] ~= nil then
                local n = tonumber(valor) or 0;
                if sinal == "-" then n = -n; end
                totaisBonus[campo] = totaisBonus[campo] + n;
            end
        end

        -- Percentual: [bonus: CAMPO +/-N%]
        for campo, sinal, valor in string.gmatch(textoLower, "%[b%o*nus:%s*([%a_]+)%s*([%+%-])(%d+)%%%]") do
            if totaisBonus[campo] ~= nil then
                local n = tonumber(valor) or 0;
                if sinal == "-" then n = -n; end
                totaisBonus[campo] = totaisBonus[campo] + n;
            end
        end

        -- Salvar bonus no sheet
        for campo, v in pairs(totaisBonus) do
            sheet["bonus_" .. campo] = tostring(v);
        end

        -- Gerar resumo dos bonus ativos
        local resumoBonus = "";
        for _, c in ipairs(camposCombate) do
            local v = totaisBonus[c];
            if v ~= 0 then
                local s = v > 0 and "+" or "";
                resumoBonus = resumoBonus .. c .. ": " .. s .. v .. "  ";
            end
        end
        for _, c in ipairs(camposStatus) do
            local v = totaisBonus[c];
            if v ~= 0 then
                local s = v > 0 and "+" or "";
                resumoBonus = resumoBonus .. c .. ": " .. s .. v .. "%  ";
            end
        end
        if resumoBonus ~= "" then
            sheet.trait_bonus_resumo = "Bonus: " .. resumoBonus;
        else
            sheet.trait_bonus_resumo = "";
        end
    end

    contarPontosJutsu = function()
        if sheet == nil then return end
        local totalPontos = 0
        local tecFields = {"tec_taijutsu", "tec_bukijutsu", "tec_ninjutsu", "tec_genjutsu", "tec_elemental", "tec_fuinjutsu", "tec_kuchiyose", "tec_kekkei_genkai", "tec_habilidades_gerais"}
        
        for i, fieldName in ipairs(tecFields) do
            local texto = ""
            
            -- Ler texto puro do RichEdit via API interna
            if editsTecnicas[i] then
                pcall(function()
                    local handle = editsTecnicas[i].handle or editsTecnicas[i]._handle;
                    if handle then
                        texto = _obj_invokeEx(handle, "LGetText") or "";
                    end
                end)
                -- Fallback: getText()
                if texto == "" then
                    pcall(function() texto = editsTecnicas[i]:getText() or ""; end)
                end
            end
            
            -- Fallback NDB com strip HTML
            if texto == "" then
                pcall(function() texto = tostring(sheet[fieldName]) or "" end)
                if texto ~= nil and texto ~= "" then
                    texto = texto:gsub("<br[^>]*>", "\n")
                    texto = texto:gsub("</p>", "\n")
                    texto = texto:gsub("</div>", "\n")
                    texto = texto:gsub("<[^>]+>", "")
                    texto = texto:gsub("&nbsp;", " ")
                    texto = texto:gsub("&amp;", "&")
                end
            end
            
            if texto ~= nil and texto ~= "" then
                for linha in string.gmatch(texto, "[^\r\n]+") do
                    local upper = string.upper(linha)
                    if not string.find(upper, "GRATUITO") then
                        local rankMatch = string.match(upper, "RANK[:%s]*(%S+)")
                        if rankMatch then
                            rankMatch = rankMatch:match("([ABCDSM]+%+?)") or ""
                            if rankMatch == "SSS" or rankMatch == "MSS+" then totalPontos = totalPontos + 400
                            elseif rankMatch == "SS+" then totalPontos = totalPontos + 350
                            elseif rankMatch == "SS" then totalPontos = totalPontos + 300
                            elseif rankMatch == "S" then totalPontos = totalPontos + 250
                            elseif rankMatch == "A" then totalPontos = totalPontos + 200
                            elseif rankMatch == "B" then totalPontos = totalPontos + 150
                            elseif rankMatch == "C" then totalPontos = totalPontos + 100
                            elseif rankMatch == "D" then totalPontos = totalPontos + 50
                            end
                        end
                    end
                end
            end
        end
        
        local nivel = tonumber(sheet.nivel) or 0
        local maxPontos = nivel * 100
        sheet.jutsu_pontos_atual = tostring(totalPontos)
        sheet.jutsu_pontos_max = tostring(maxPontos)
        
        if totalPontos > maxPontos then
            sheet.jutsu_status = "Excedido em " .. (totalPontos - maxPontos) .. " pts!"
        else
            sheet.jutsu_status = "Restam " .. (maxPontos - totalPontos) .. " pts"
        end
    end

    calcularAtributos = function()
        -- Core
        local forca = tonumber(sheet.forca) or 0
        local agilidade = tonumber(sheet.agilidade) or 0
        local constituicao = tonumber(sheet.constituicao) or 0
        local destreza = tonumber(sheet.destreza) or 0
        local ctrl_chakra = tonumber(sheet.ctrl_chakra) or 0
        local concentracao = tonumber(sheet.concentracao) or 0
        local forca_espiritual = tonumber(sheet.forca_espiritual) or 0
        local inteligencia = tonumber(sheet.inteligencia) or 0
        
        -- Multiplicadores de bonus para status
        local pctPv = (tonumber(sheet.bonus_pv) or 0) + (tonumber(sheet.trait_pv) or 0)
        local pctChakra = (tonumber(sheet.bonus_pchakra) or 0) + (tonumber(sheet.trait_pchakra) or 0)
        local pctEstamina = (tonumber(sheet.bonus_pestamina) or 0) + (tonumber(sheet.trait_pestamina) or 0)
        local multPv = 1 + (pctPv / 100)
        local multChakra = 1 + (pctChakra / 100)
        local multEstamina = 1 + (pctEstamina / 100)
        
        -- Nivel e Limite de atributos
        local totalCore = forca + agilidade + constituicao + destreza + ctrl_chakra + concentracao + forca_espiritual + inteligencia
        sheet.pontos_core_resumo = "Pontos Core: " .. totalCore
        sheet.limite_atributo = tostring(math.floor(totalCore / 8) + 3)
        sheet.nivel = tostring(math.floor(totalCore / 2) - 7)
        
        -- Validacao Interpretativos
        local interpVals = validarInterpretativos()
        local totalInterp = 0
        if interpVals then
            for i=1, #interpVals do totalInterp = totalInterp + interpVals[i] end
        end
        local maxInterp = tonumber(sheet.max_pontos_interp) or 0
        sheet.pontos_interp_resumo = "Pontos Interp.: " .. totalInterp .. " / " .. maxInterp
        sheet.interp_uso_resumo = totalInterp .. " / " .. maxInterp
        
        -- PV / Chakra / Estamina Maximos
        sheet.pv = tostring(math.floor((constituicao + forca) * 45 * multPv))
        sheet.pchakra = tostring(math.floor((ctrl_chakra + forca_espiritual + inteligencia) * 34 * multChakra))
        sheet.pestamina = tostring(math.floor((agilidade + destreza + concentracao) * 34 * multEstamina))
        
        -- XP Max = nivel * 100
        local nivel = tonumber(sheet.nivel) or 1
        sheet.xp_max = tostring(nivel * 100)
        
        -- Calcular Rank automaticamente baseado no nivel
        local rank
        if nivel >= 160 then rank = "Fushi"
        elseif nivel >= 140 then rank = "Kage"
        elseif nivel >= 120 then rank = "Sannin"
        elseif nivel >= 90 then rank = "Oinin"
        elseif nivel >= 80 then rank = "Nukenin"
        elseif nivel >= 60 then rank = "Comandante ANBU"
        elseif nivel >= 50 then rank = "ANBU"
        elseif nivel >= 40 then rank = "Capitão Jônin"
        elseif nivel >= 30 then rank = "Jônin"
        elseif nivel >= 20 then rank = "Tokubetsu Jônin"
        elseif nivel >= 10 then rank = "Chunin"
        elseif nivel >= 4 then rank = "Genin"
        else rank = "Estudante"
        end
        sheet.rank_shinobi = rank
        
        -- Max pontos interpretativos por rank
        local maxInterp
        if     rank == "Estudante"       then maxInterp = 20
        elseif rank == "Genin"           then maxInterp = 24
        elseif rank == "Chunin"          then maxInterp = 30
        elseif rank == "Tokubetsu Jônin" then maxInterp = 32
        elseif rank == "Jônin"           then maxInterp = 34
        elseif rank == "Capitão Jônin"   then maxInterp = 36
        elseif rank == "ANBU"            then maxInterp = 38
        elseif rank == "Comandante ANBU" then maxInterp = 40
        elseif rank == "Nukenin"         then maxInterp = 42
        elseif rank == "Oinin"           then maxInterp = 44
        elseif rank == "Sannin"          then maxInterp = 46
        elseif rank == "Kage"            then maxInterp = 48
        elseif rank == "Fushi"           then maxInterp = 50
        else maxInterp = 0
        end
        sheet.max_pontos_interp = tostring(maxInterp)
        
        -- Combate (bases)
        local taijutsu = math.floor(forca + agilidade * 0.5)
        local bukijutsu = math.floor(destreza + forca * 0.5)
        local ninjutsu = math.floor(forca_espiritual + ctrl_chakra * 0.5)
        local genjutsu = math.floor(ctrl_chakra + inteligencia * 0.5)
        local genjutsu_kai = math.floor((inteligencia + ctrl_chakra + concentracao) / 2)
        local fuinjutsu = math.floor(inteligencia + forca_espiritual * 0.5)
        local arremesso = math.floor(concentracao + destreza * 0.5)
        local esquiva = math.floor((agilidade + concentracao + inteligencia + constituicao) / 2.5)
        local bloqueio_fisico = math.floor((forca + destreza + constituicao + agilidade) / 2.5)
        local bloqueio_chakra = math.floor((ctrl_chakra + forca_espiritual + constituicao + concentracao) / 2.5)
        local reflexo = math.floor((concentracao + agilidade + constituicao + inteligencia) / 2.5)
        local iniciativa = math.floor((forca + destreza + concentracao + agilidade) / 2.5)
        
        -- KKG Bonus
        local kkg_bonus = 0
        local kkg_nome = ""
        if tostring(sheet.kkg_sharingan3) == "true" then kkg_bonus = 4; kkg_nome = "Sharingan 3 Estagio"
        elseif tostring(sheet.kkg_sharingan2) == "true" then kkg_bonus = 3; kkg_nome = "Sharingan 2 Estagio"
        elseif tostring(sheet.kkg_sharingan1) == "true" then kkg_bonus = 2; kkg_nome = "Sharingan 1 Estagio"
        end
        sheet.kkg_ativos_label = kkg_nome
        
        -- Traits Combate Bonus
        local n_tc = 0
        if tostring(sheet.trait_combate_s1) == 'true' then n_tc = n_tc + 1 end
        if tostring(sheet.trait_combate_s2) == 'true' then n_tc = n_tc + 1 end
        if tostring(sheet.trait_combate_s3) == 'true' then n_tc = n_tc + 1 end
        if tostring(sheet.trait_combate_s4) == 'true' then n_tc = n_tc + 1 end
        if tostring(sheet.trait_combate_s5) == 'true' then n_tc = n_tc + 1 end
        
        local tc_tipo = tostring(sheet.trait_combate_tipo) or 'nenhum'
        local t_artmarcial, t_domarmas, t_manipchakra, t_ilusionista, t_menteblind, t_bloqueador, t_intuicao = 0,0,0,0,0,0,0
        if n_tc > 0 then
            if tc_tipo == 'artmarcial' then t_artmarcial = 2 + (n_tc - 1)
            elseif tc_tipo == 'domarmas' then t_domarmas = 2 + (n_tc - 1)
            elseif tc_tipo == 'manipchakra' then t_manipchakra = 2 + (n_tc - 1)
            elseif tc_tipo == 'ilusionista' then t_ilusionista = 2 + (n_tc - 1)
            elseif tc_tipo == 'menteblind' then t_menteblind = 4 + (n_tc - 1)
            elseif tc_tipo == 'bloqueador' then t_bloqueador = 1 + (n_tc - 1)
            elseif tc_tipo == 'intuicao' then t_intuicao = 2 + (n_tc - 1)
            end
        end
        
        -- Apply Total Combate
        sheet.taijutsu = tostring(taijutsu + (tonumber(sheet.bonus_taijutsu) or 0) + kkg_bonus + t_artmarcial)
        sheet.bukijutsu = tostring(bukijutsu + (tonumber(sheet.bonus_bukijutsu) or 0) + kkg_bonus + t_domarmas)
        sheet.ninjutsu = tostring(ninjutsu + (tonumber(sheet.bonus_ninjutsu) or 0) + kkg_bonus + t_manipchakra)
        sheet.genjutsu = tostring(genjutsu + (tonumber(sheet.bonus_genjutsu) or 0) + kkg_bonus + t_ilusionista)
        sheet.genjutsu_kai = tostring(genjutsu_kai + (tonumber(sheet.bonus_genjutsu_kai) or 0) + kkg_bonus + t_ilusionista + t_menteblind)
        sheet.fuinjutsu = tostring(fuinjutsu + (tonumber(sheet.bonus_fuinjutsu) or 0) + t_manipchakra)
        sheet.arremesso = tostring(arremesso + (tonumber(sheet.bonus_arremesso) or 0) + kkg_bonus + t_domarmas)
        sheet.esquiva = tostring(esquiva + (tonumber(sheet.bonus_esquiva) or 0) + kkg_bonus + t_intuicao)
        sheet.bloqueio_fisico = tostring(bloqueio_fisico + (tonumber(sheet.bonus_bloqueio_fisico) or 0) + kkg_bonus + t_bloqueador)
        sheet.bloqueio_chakra = tostring(bloqueio_chakra + (tonumber(sheet.bonus_bloqueio_chakra) or 0) + kkg_bonus + t_bloqueador)
        sheet.reflexo = tostring(reflexo + (tonumber(sheet.bonus_reflexo) or 0) + t_intuicao)
        sheet.iniciativa = tostring(iniciativa + (tonumber(sheet.bonus_iniciativa) or 0) + t_intuicao)
        
        -- Unicos
        sheet.tai_bukijutsu = tostring(math.floor((taijutsu + bukijutsu) / 2) + (tonumber(sheet.bonus_tai_bukijutsu) or 0) + t_artmarcial + t_domarmas)
        sheet.nin_taijutsu = tostring(math.floor((taijutsu + ninjutsu) / 2) + (tonumber(sheet.bonus_nin_taijutsu) or 0) + t_artmarcial + t_manipchakra)
        sheet.hiraishin = tostring(math.floor((ninjutsu + fuinjutsu) / 2) + (tonumber(sheet.bonus_hiraishin) or 0))
        sheet.movimentacao = tostring(math.floor(agilidade + inteligencia / 2) + (tonumber(sheet.bonus_movimentacao) or 0) + t_intuicao)
        
        contarPontosJutsu()
        calcularTraits()
    end

    calcularKuchiyose = function()
        local forca = tonumber(sheet.kuchi_forca) or 0
        local agilidade = tonumber(sheet.kuchi_agilidade) or 0
        local constituicao = tonumber(sheet.kuchi_constituicao) or 0
        local destreza = tonumber(sheet.kuchi_destreza) or 0
        local ctrl_chakra = tonumber(sheet.kuchi_ctrl_chakra) or 0
        local concentracao = tonumber(sheet.kuchi_concentracao) or 0
        local forca_espiritual = tonumber(sheet.kuchi_forca_espiritual) or 0
        local inteligencia = tonumber(sheet.kuchi_inteligencia) or 0

        sheet.kuchi_pv = tostring(math.floor((constituicao * 10) + (forca * 5)))
        sheet.kuchi_pchakra = tostring(math.floor((ctrl_chakra * 10) + (forca_espiritual * 5)))
        sheet.kuchi_pestamina = tostring(math.floor((constituicao * 5) + (agilidade * 5) + (forca * 2)))

        local rv = tostring(sheet.kuchi_rank)
        local p = -5
        if rv == '-5' then p = -5 elseif rv == '-4' or rv == '-4b' then p = -4 elseif rv == '-3' then p = -3 elseif rv == '-2' then p = -2 elseif rv == '-1' then p = -1 elseif rv == '0' then p = 0 end

        sheet.kuchi_taijutsu = tostring(math.floor(forca + agilidade * 0.5) + p)
        sheet.kuchi_bukijutsu = tostring(math.floor(destreza + forca * 0.5) + p)
        sheet.kuchi_ninjutsu = tostring(math.floor(forca_espiritual + ctrl_chakra * 0.5) + p)
        sheet.kuchi_genjutsu = tostring(math.floor(ctrl_chakra + inteligencia * 0.5) + p)
        sheet.kuchi_genjutsu_kai = tostring(math.floor((inteligencia + ctrl_chakra + concentracao) / 2) + p)
        sheet.kuchi_fuinjutsu = tostring(math.floor(inteligencia + forca_espiritual * 0.5) + p)
        sheet.kuchi_arremesso = tostring(math.floor(concentracao + destreza * 0.5) + p)
        sheet.kuchi_esquiva = tostring(math.floor((agilidade + concentracao + inteligencia + constituicao) / 2.5) + p)
        sheet.kuchi_bloqueio_fisico = tostring(math.floor((forca + destreza + constituicao + agilidade) / 2.5) + p)
        sheet.kuchi_bloqueio_chakra = tostring(math.floor((ctrl_chakra + forca_espiritual + constituicao + concentracao) / 2.5) + p)
        sheet.kuchi_reflexo = tostring(math.floor((concentracao + agilidade + constituicao + inteligencia) / 2.5) + p)
        sheet.kuchi_iniciativa = tostring(math.floor((forca + destreza + concentracao + agilidade) / 2.5) + p)
    end

    -- ==========================================
    -- DATA LINKS (GATILHOS DE ATUALIZACAO)
    -- usando ndb.newObserver para monitorar
    -- diretamente o banco de dados do personagem
    -- ==========================================
    local ndb = require("ndb.lua");

    atualizarBarras = function()
        local pvMax = tonumber(sheet.pv) or 0
        local pvAtual = tonumber(sheet.pv_atual) or 0
        local chakraMax = tonumber(sheet.pchakra) or 0
        local chakraAtual = tonumber(sheet.pchakra_atual) or 0
        local estMax = tonumber(sheet.pestamina) or 0
        local estAtual = tonumber(sheet.pestamina_atual) or 0
        local xpMax = tonumber(sheet.xp_max) or 100
        local xpAtual = tonumber(sheet.xp_atual) or 0
        
        if hpBar then
            hpBar.max = math.max(pvMax, 1)
            hpBar.position = pvAtual
        end
        if ckBar then
            ckBar.max = math.max(chakraMax, 1)
            ckBar.position = chakraAtual
        end
        if stBar then
            stBar.max = math.max(estMax, 1)
            stBar.position = estAtual
        end
        if xp and xp.bar then
            xp.bar.max = math.max(xpMax, 1)
            xp.bar.position = xpAtual
        end
    end

    local coreFields = {forca=true, agilidade=true, constituicao=true, destreza=true, ctrl_chakra=true, concentracao=true, forca_espiritual=true, inteligencia=true, nivel=true};
    local interpFields = {sobrevivencia=true, armadilha=true, empatia=true, intimidacao=true, ladinagem=true, enganacao=true, percepcao=true, persuasao=true, seducao=true, medicina=true, historia_attr=true, oficio=true, conhecimento=true, aprendizado=true, ensinamento=true};
    local traitFields = {trait_pv=true, trait_pchakra=true, trait_pestamina=true, trait_combate_tipo=true, trait_combate_s1=true, trait_combate_s2=true, trait_combate_s3=true, trait_combate_s4=true, trait_combate_s5=true, kkg_sharingan1=true, kkg_sharingan2=true, kkg_sharingan3=true};
    local barFields = {pv_atual=true, pchakra_atual=true, pestamina_atual=true, pv=true, pchakra=true, pestamina=true, xp_atual=true, xp_max=true};
    local kuchiFields = {kuchi_forca=true, kuchi_agilidade=true, kuchi_constituicao=true, kuchi_destreza=true, kuchi_ctrl_chakra=true, kuchi_concentracao=true, kuchi_forca_espiritual=true, kuchi_inteligencia=true, kuchi_rank=true};

    local obs = ndb.newObserver(sheet);
    if obs then
        obs:addEventListener("onChanged", function(node, attribute, oldValue)
            if coreFields[attribute] or interpFields[attribute] or traitFields[attribute] then
                calcularAtributos();
                atualizarBarras();
            end;
            if barFields[attribute] then
                atualizarBarras();
            end;
            if kuchiFields[attribute] then
                calcularKuchiyose();
            end;
            -- Campos de tecnica (RichEdit) disparam contagem de jutsu
            if string.find(attribute or "", "^tec_") then
                pcall(contarPontosJutsu);
            end;
            -- Campo de traits dispara calculo de traits
            if attribute == "traits" then
                pcall(calcularTraits);
            end;
        end);
    end;

    -- Calculo inicial ao abrir a ficha
    pcall(calcularTraits);
    calcularAtributos();
    pcall(calcularKuchiyose);
    atualizarBarras();

    -- Timer para atualizar jutsus e traits em tempo real (a cada 2s)
    ui.timer({interval = 2000, enabled = true, onTimer = function()
        pcall(contarPontosJutsu);
        pcall(calcularTraits);
    end});

    -- ========== RETORNO ==========
    return "OK";
end;

return criarFichaAvancada;
