-- ============================================================
-- FCEXT UI Library v1.0
-- High-level UI components for Firecast character sheets
-- Removes design limitations from the LFM system
-- ============================================================

local ui = {};

-- ============ THEME SYSTEM ============
ui.themes = {
    naruto = {
        bg          = "#0A0E17",
        bgAlt       = "#0E1420",
        surface     = "#111827",
        surfaceAlt  = "#1A2233",
        header      = "#0C1828",
        headerBorder= "#F97316",
        accent      = "#F97316",
        accentAlt   = "#FB923C",
        text        = "#E2E8F0",
        textDim     = "#8BA3C4",
        textMuted   = "#5E7FA0",
        hp          = "#EF4444",
        hpBg        = "#1A0A10",
        chakra      = "#818CF8",
        chakraBg    = "#0A0A1A",
        stamina     = "#FBBF24",
        staminaBg   = "#1A1A0A",
        ally        = "#22C55E",
        enemy       = "#EF4444",
        neutral     = "#FBBF24",
        border      = "#1E3A5C",
        separator   = "#1E293B",
        fontFamily  = "Segoe UI",
        fontSize    = 13,
        fontSizeSm  = 11,
        fontSizeLg  = 15,
        fontSizeXl  = 18,
        fontSizeTitle = 24,
        radius      = 8,
        radiusSm    = 4,
    },
    dark = {
        bg          = "#1A1A2E",
        bgAlt       = "#16213E",
        surface     = "#0F3460",
        surfaceAlt  = "#1A1A40",
        header      = "#0F3460",
        headerBorder= "#E94560",
        accent      = "#E94560",
        accentAlt   = "#FF6B6B",
        text        = "#EAEAEA",
        textDim     = "#A0A0B0",
        textMuted   = "#6B6B80",
        hp          = "#E94560",
        hpBg        = "#2A0A15",
        chakra      = "#5C7AEA",
        chakraBg    = "#0A0A2A",
        stamina     = "#F5A623",
        staminaBg   = "#2A1A0A",
        ally        = "#00D9A6",
        enemy       = "#E94560",
        neutral     = "#F5A623",
        border      = "#2A3A5C",
        separator   = "#2A2A4E",
        fontFamily  = "Segoe UI",
        fontSize    = 13,
        fontSizeSm  = 11,
        fontSizeLg  = 15,
        fontSizeXl  = 18,
        fontSizeTitle = 24,
        radius      = 8,
        radiusSm    = 4,
    },
};

ui.currentTheme = ui.themes.naruto;

function ui.setTheme(name)
    if ui.themes[name] then
        ui.currentTheme = ui.themes[name];
    end;
end;

function ui.t()
    return ui.currentTheme;
end;

-- ============ CORE: POPUP WINDOW ============
function ui.window(opts)
    opts = opts or {};
    local t = ui.t();
    local popup = GUI.newPopupForm();
    popup.title = opts.title or "FCEXT Window";
    popup.width = opts.width or 450;
    popup.height = opts.height or 600;
    pcall(function() popup:setResizable(opts.resizable ~= false); end);

    -- Background
    local bg = GUI.newRectangle();
    bg.parent = popup;
    bg.align = "client";
    bg.color = opts.bgColor or t.bg;

    -- Optional scroll
    local content;
    if opts.scroll ~= false then
        content = GUI.newScrollBox();
        content.parent = popup;
        content.align = "client";
    else
        content = popup;
    end;

    popup._content = content;
    popup._bg = bg;

    if opts.show ~= false then
        popup:show();
    end;

    return popup;
end;

-- ============ SECTION HEADER ============
function ui.section(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local text = opts.text or opts[1] or "Section";

    local container = GUI.newLayout();
    container.parent = parent;
    container.align = "top";
    container.height = opts.height or 34;
    container.margins = opts.margins or {top = 18, bottom = 6};

    local bgRect = GUI.newRectangle();
    bgRect.parent = container;
    bgRect.align = "client";
    bgRect.color = opts.bgColor or t.header;
    bgRect.strokeColor = opts.borderColor or t.headerBorder;
    bgRect.strokeSize = opts.borderSize or 2;
    bgRect.xradius = t.radius;
    bgRect.yradius = t.radius;

    local lbl = GUI.newLabel();
    lbl.parent = container;
    lbl.align = "client";
    lbl.text = text;
    lbl.horzTextAlign = "center";
    lbl.fontStyle = "bold";
    lbl.fontColor = opts.fontColor or t.accent;
    lbl.fontSize = opts.fontSize or t.fontSizeLg;

    container._bg = bgRect;
    container._label = lbl;
    return container;
end;

-- ============ CARD COMPONENT ============
function ui.card(parent, opts)
    opts = opts or {};
    local t = ui.t();

    -- Outer container
    local card = GUI.newLayout();
    card.parent = parent;
    card.align = opts.align or "top";
    card.height = opts.height or 200;
    if opts.width then card.width = opts.width; end;
    card.margins = opts.margins or {top = 8, left = 8, right = 8};

    -- Background
    local bgRect = GUI.newRectangle();
    bgRect.parent = card;
    bgRect.align = "client";
    bgRect.color = opts.bgColor or t.surface;
    bgRect.strokeColor = opts.borderColor or t.border;
    bgRect.strokeSize = opts.borderSize or 1;
    bgRect.xradius = t.radius;
    bgRect.yradius = t.radius;

    -- Header (if title provided)
    local headerLayout, headerLabel;
    if opts.title then
        headerLayout = GUI.newLayout();
        headerLayout.parent = card;
        headerLayout.align = "top";
        headerLayout.height = opts.headerHeight or 32;

        local headerBg = GUI.newRectangle();
        headerBg.parent = headerLayout;
        headerBg.align = "client";
        headerBg.color = opts.headerColor or t.header;
        headerBg.strokeColor = opts.headerBorderColor or t.border;
        headerBg.strokeSize = 1;
        headerBg.xradius = t.radius;
        headerBg.yradius = t.radius;

        headerLabel = GUI.newLabel();
        headerLabel.parent = headerLayout;
        headerLabel.align = "client";
        headerLabel.text = "  " .. opts.title;
        headerLabel.fontColor = opts.titleColor or t.accent;
        headerLabel.fontSize = opts.titleFontSize or t.fontSize;
        headerLabel.fontStyle = "bold";
    end;

    -- Content area
    local body = GUI.newLayout();
    body.parent = card;
    body.align = "client";
    body.margins = opts.bodyMargins or {left = 8, right = 8, top = 4, bottom = 4};

    card._bg = bgRect;
    card._header = headerLayout;
    card._headerLabel = headerLabel;
    card._body = body;

    return card;
end;

-- ============ STAT BAR (HP / Chakra / Stamina) ============
function ui.statBar(parent, opts)
    opts = opts or {};
    local t = ui.t();

    local current = opts.current or 0;
    local max = opts.max or 100;
    local label = opts.label or "HP";
    local barColor = opts.color or t.hp;
    local bgColor = opts.bgColor or t.hpBg;

    -- Row
    local row = GUI.newLayout();
    row.parent = parent;
    row.align = "top";
    row.height = opts.height or 28;
    row.margins = opts.margins or {top = 2};

    -- Label
    local lbl = GUI.newLabel();
    lbl.parent = row;
    lbl.align = "left";
    lbl.width = opts.labelWidth or 130;
    lbl.text = label .. ":";
    lbl.horzTextAlign = "trailing";
    lbl.fontColor = barColor;
    lbl.fontSize = t.fontSize;
    lbl.fontStyle = "bold";
    lbl.margins = {right = 10};

    -- Current value (editable)
    local editCurrent = GUI.newEdit();
    editCurrent.parent = row;
    editCurrent.align = "left";
    editCurrent.width = 50;
    editCurrent.text = tostring(current);
    editCurrent.fontColor = "white";
    editCurrent.horzTextAlign = "center";
    if opts.fieldCurrent then
        pcall(function() editCurrent.field = opts.fieldCurrent; end);
    end;

    -- Separator
    local sep = GUI.newLabel();
    sep.parent = row;
    sep.align = "left";
    sep.width = 20;
    sep.text = " / ";
    sep.fontColor = t.textDim;
    sep.fontSize = t.fontSize;
    sep.horzTextAlign = "center";

    -- Max value
    local lblMax = GUI.newLabel();
    lblMax.parent = row;
    lblMax.align = "left";
    lblMax.width = 50;
    lblMax.text = tostring(max);
    lblMax.fontColor = "white";
    lblMax.fontSize = t.fontSize;
    lblMax.fontStyle = "bold";
    lblMax.horzTextAlign = "center";

    -- Spacer
    local spacer = GUI.newLayout();
    spacer.parent = row;
    spacer.align = "left";
    spacer.width = 10;

    -- Progress bar container
    local barContainer = GUI.newLayout();
    barContainer.parent = row;
    barContainer.align = "client";
    barContainer.margins = {top = 4, bottom = 4};

    -- Bar background
    local barBg = GUI.newRectangle();
    barBg.parent = barContainer;
    barBg.align = "client";
    barBg.color = bgColor;
    barBg.strokeColor = bgColor;
    barBg.strokeSize = 1;
    barBg.xradius = 6;
    barBg.yradius = 6;

    -- Progress bar
    local bar = GUI.newProgressBar();
    bar.parent = barContainer;
    bar.align = "client";
    bar.min = 0;
    bar.max = max;
    bar.position = current;
    bar.color = barColor;
    pcall(function() bar.mouseGlow = true; end);

    row._label = lbl;
    row._edit = editCurrent;
    row._max = lblMax;
    row._bar = bar;
    row._barBg = barBg;

    -- Update function
    row.update = function(newCurrent, newMax)
        if newCurrent then
            editCurrent.text = tostring(newCurrent);
            bar.position = newCurrent;
        end;
        if newMax then
            lblMax.text = tostring(newMax);
            bar.max = newMax;
        end;
    end;

    return row;
end;

-- ============ FIELD (Label + Edit) ============
function ui.field(parent, opts)
    opts = opts or {};
    local t = ui.t();

    local row = GUI.newLayout();
    row.parent = parent;
    row.align = "top";
    row.height = opts.height or 30;
    row.margins = opts.margins or {top = 2};

    -- Label
    local lbl = GUI.newLabel();
    lbl.parent = row;
    lbl.align = "left";
    lbl.width = opts.labelWidth or 130;
    lbl.text = (opts.label or opts[1] or "Campo") .. ":";
    lbl.horzTextAlign = "trailing";
    lbl.fontColor = opts.labelColor or t.textDim;
    lbl.fontSize = opts.fontSize or t.fontSize;
    lbl.margins = {right = 10};

    -- Edit or ComboBox
    local input;
    if opts.items then
        -- ComboBox
        input = GUI.newComboBox();
        input.parent = row;
        input.align = opts.inputAlign or "client";
        if opts.inputWidth then input.width = opts.inputWidth; end;
        input.fontColor = "white";
        pcall(function() input.items = opts.items; end);
        pcall(function() input.values = opts.values or opts.items; end);
    else
        -- Edit
        input = GUI.newEdit();
        input.parent = row;
        input.align = opts.inputAlign or "client";
        if opts.inputWidth then input.width = opts.inputWidth; end;
        input.fontColor = opts.inputColor or "white";
        if opts.placeholder then
            pcall(function() input:setTextPrompt(opts.placeholder); end);
        end;
        if opts.readOnly then input.readOnly = true; end;
    end;

    if opts.field then
        pcall(function() input.field = opts.field; end);
    end;

    -- Display label (read-only styled value)
    if opts.display then
        local lblVal = GUI.newLabel();
        lblVal.parent = row;
        lblVal.align = opts.displayAlign or "left";
        lblVal.width = opts.displayWidth or 60;
        lblVal.fontColor = opts.displayColor or t.accent;
        lblVal.fontSize = opts.displayFontSize or t.fontSizeLg;
        lblVal.fontStyle = "bold";
        lblVal.horzTextAlign = "center";
        if opts.displayField then
            pcall(function() lblVal.field = opts.displayField; end);
        end;
        row._display = lblVal;
    end;

    row._label = lbl;
    row._input = input;
    return row;
end;

-- ============ SEPARATOR ============
function ui.separator(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local sep = GUI.newHorzLine();
    sep.parent = parent;
    sep.align = "top";
    sep.color = opts.color or t.separator;
    sep.margins = opts.margins or {top = 4, bottom = 4};
    return sep;
end;

-- ============ SPACER ============
function ui.spacer(parent, height)
    local sp = GUI.newLayout();
    sp.parent = parent;
    sp.align = "top";
    sp.height = height or 10;
    return sp;
end;

-- ============ TEXT LABEL ============
function ui.label(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local lbl = GUI.newLabel();
    lbl.parent = parent;
    lbl.align = opts.align or "top";
    lbl.height = opts.height or 25;
    if opts.width then lbl.width = opts.width; end;
    lbl.text = opts.text or opts[1] or "";
    lbl.fontColor = opts.color or t.text;
    lbl.fontSize = opts.fontSize or t.fontSize;
    if opts.bold then lbl.fontStyle = "bold"; end;
    if opts.italic then lbl.fontStyle = "italic"; end;
    lbl.horzTextAlign = opts.textAlign or "leading";
    lbl.vertTextAlign = opts.vertAlign or "center";
    if opts.margins then lbl.margins = opts.margins; end;
    if opts.field then pcall(function() lbl.field = opts.field; end); end;
    return lbl;
end;

-- ============ BUTTON ============
function ui.button(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local btn = GUI.newButton();
    btn.parent = parent;
    btn.align = opts.align or "top";
    btn.height = opts.height or 32;
    if opts.width then btn.width = opts.width; end;
    btn.text = opts.text or opts[1] or "Button";
    if opts.margins then btn.margins = opts.margins; end;
    if opts.onClick then
        pcall(function() btn.onClick = opts.onClick; end);
    end;
    return btn;
end;

-- ============ BADGE (small colored indicator) ============
function ui.badge(parent, opts)
    opts = opts or {};
    local t = ui.t();

    local container = GUI.newLayout();
    container.parent = parent;
    container.align = opts.align or "left";
    container.width = opts.width or 80;
    container.height = opts.height or 24;
    if opts.margins then container.margins = opts.margins; end;

    local bgRect = GUI.newRectangle();
    bgRect.parent = container;
    bgRect.align = "client";
    bgRect.color = opts.bgColor or t.accent;
    bgRect.xradius = opts.radius or 12;
    bgRect.yradius = opts.radius or 12;

    local lbl = GUI.newLabel();
    lbl.parent = container;
    lbl.align = "client";
    lbl.text = opts.text or opts[1] or "";
    lbl.fontColor = opts.fontColor or "white";
    lbl.fontSize = opts.fontSize or t.fontSizeSm;
    lbl.fontStyle = "bold";
    lbl.horzTextAlign = "center";
    lbl.vertTextAlign = "center";

    container._bg = bgRect;
    container._label = lbl;
    return container;
end;

-- ============ CHECKBOX ROW ============
function ui.checkRow(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local chk = GUI.newCheckBox();
    chk.parent = parent;
    chk.align = opts.align or "top";
    chk.height = opts.height or 25;
    if opts.width then chk.width = opts.width; end;
    chk.text = opts.text or opts[1] or "";
    chk.fontColor = opts.color or t.text;
    chk.fontSize = opts.fontSize or t.fontSize;
    if opts.field then pcall(function() chk.field = opts.field; end); end;
    if opts.margins then chk.margins = opts.margins; end;
    return chk;
end;

-- ============ IMAGE ============
function ui.image(parent, opts)
    opts = opts or {};
    local img = GUI.newImage();
    img.parent = parent;
    img.align = opts.align or "top";
    img.height = opts.height or 200;
    if opts.width then img.width = opts.width; end;
    pcall(function() img.style = opts.style or "autoFit"; end);
    if opts.src then pcall(function() img.src = opts.src; end); end;
    if opts.url then pcall(function() img:setURL(opts.url); end); end;
    if opts.field then pcall(function() img.field = opts.field; end); end;
    if opts.editable then pcall(function() img.editable = true; end); end;
    if opts.margins then img.margins = opts.margins; end;
    return img;
end;

-- ============ TIMER (for animations) ============
function ui.timer(opts)
    opts = opts or {};
    local tmr = GUI.newTimer();
    tmr.interval = opts.interval or 100;
    tmr.enabled = opts.enabled ~= false;
    if opts.onTimer then
        pcall(function() tmr.onTimer = opts.onTimer; end);
    end;
    return tmr;
end;

-- ============ GRID (rows of equal columns) ============
function ui.grid(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local cols = opts.cols or 2;

    local row = GUI.newLayout();
    row.parent = parent;
    row.align = "top";
    row.height = opts.height or 30;
    if opts.margins then row.margins = opts.margins; end;

    local columns = {};
    for i = 1, cols do
        local col = GUI.newLayout();
        col.parent = row;
        col.align = "left";
        col.width = (opts.colWidth or math.floor((opts.totalWidth or 600) / cols));
        col.height = opts.height or 30;
        columns[i] = col;
    end;

    row._cols = columns;
    return row;
end;

-- ============ TOAST NOTIFICATION ============
function ui.toast(text, opts)
    pcall(function()
        GUI.toast(text);
    end);
end;

-- ============ ATTRIBUTE DISPLAY (Naruto-style) ============
function ui.attribute(parent, opts)
    opts = opts or {};
    local t = ui.t();

    local row = GUI.newLayout();
    row.parent = parent;
    row.align = "top";
    row.height = opts.height or 30;
    row.margins = opts.margins or {top = 2};

    -- Label
    local lbl = GUI.newLabel();
    lbl.parent = row;
    lbl.align = "left";
    lbl.width = opts.labelWidth or 130;
    lbl.text = (opts.label or opts[1] or "Atributo") .. ":";
    lbl.horzTextAlign = "trailing";
    lbl.fontColor = opts.labelColor or t.textDim;
    lbl.fontSize = t.fontSize;
    lbl.margins = {right = 10};

    -- Value box
    local valBox = GUI.newLayout();
    valBox.parent = row;
    valBox.align = "left";
    valBox.width = opts.valueWidth or 55;

    local valBg = GUI.newRectangle();
    valBg.parent = valBox;
    valBg.align = "client";
    valBg.color = t.bgAlt;
    valBg.strokeColor = t.border;
    valBg.strokeSize = 1;
    valBg.xradius = t.radiusSm;
    valBg.yradius = t.radiusSm;

    local valEdit = GUI.newEdit();
    valEdit.parent = valBox;
    valEdit.align = "client";
    valEdit.fontColor = opts.valueColor or t.accent;
    valEdit.fontSize = t.fontSizeLg;
    valEdit.horzTextAlign = "center";
    if opts.field then pcall(function() valEdit.field = opts.field; end); end;
    if opts.onChange then
        valEdit:addEventListener("onChange", opts.onChange);
    end;
    if opts.readOnly then
        pcall(function() valEdit.readOnly = true; end);
        valBg.strokeColor = "#334155";
        valEdit.fontColor = "#94A3B8";
    end;

    -- Bonus (optional)
    if opts.bonus then
        local lblBonus = GUI.newLabel();
        lblBonus.parent = row;
        lblBonus.align = "left";
        lblBonus.width = 40;
        lblBonus.fontColor = opts.bonus > 0 and t.ally or t.enemy;
        lblBonus.fontSize = t.fontSizeSm;
        lblBonus.text = (opts.bonus > 0 and "+" or "") .. opts.bonus;
        lblBonus.horzTextAlign = "center";
        row._bonus = lblBonus;
    end;

    -- Description (optional)
    if opts.desc then
        local lblDesc = GUI.newLabel();
        lblDesc.parent = row;
        lblDesc.align = "client";
        lblDesc.text = opts.desc;
        lblDesc.fontColor = t.textMuted;
        lblDesc.fontSize = t.fontSizeSm;
        lblDesc.fontStyle = "italic";
        row._desc = lblDesc;
    end;

    row._label = lbl;
    row._valBg = valBg;
    row._edit = valEdit;
    return row;
end;

-- ============ BANNER / HEADER IMAGE ============
function ui.banner(parent, opts)
    opts = opts or {};
    local t = ui.t();

    local container = GUI.newLayout();
    container.parent = parent;
    container.align = "top";
    container.height = opts.height or 80;
    container.margins = opts.margins or {left = 5, right = 5, top = 8, bottom = 8};

    -- Image background
    if opts.src then
        local img = GUI.newImage();
        img.parent = container;
        img.align = "client";
        pcall(function() img.style = "stretch"; end);
        pcall(function() img.src = opts.src; end);
        container._image = img;
    end;

    -- Border
    local border = GUI.newRectangle();
    border.parent = container;
    border.align = "client";
    border.color = "#0A101800"; -- transparent
    border.strokeColor = opts.borderColor or t.accent;
    border.strokeSize = opts.borderSize or 2;
    border.xradius = t.radius;
    border.yradius = t.radius;

    -- Title overlay
    if opts.title then
        local lbl = GUI.newLabel();
        lbl.parent = container;
        lbl.align = "client";
        lbl.text = opts.title;
        lbl.horzTextAlign = "center";
        lbl.vertTextAlign = "center";
        lbl.fontColor = opts.titleColor or t.accent;
        lbl.fontSize = opts.titleFontSize or t.fontSizeTitle;
        lbl.fontStyle = "bold";
        container._title = lbl;
    end;

    container._border = border;
    return container;
end;

-- ============ DATA LINK (reactive data binding) ============
function ui.dataLink(parent, opts)
    opts = opts or {};
    local dl = GUI.newDataLink();
    dl.parent = parent;
    if opts.field then
        pcall(function() dl.field = opts.field; end);
    end;
    if opts.fields then
        pcall(function() dl.fields = opts.fields; end);
    end;
    if opts.defaultValue then
        pcall(function() dl.defaultValue = opts.defaultValue; end);
    end;
    if opts.defaultValues then
        pcall(function() dl.defaultValues = opts.defaultValues; end);
    end;
    if opts.onChange then
        dl:addEventListener("onChange", opts.onChange);
    end;
    if opts.onPersistedChange then
        dl:addEventListener("onPersistedChange", opts.onPersistedChange);
    end;
    if opts.onUserChange then
        dl:addEventListener("onUserChange", opts.onUserChange);
    end;
    return dl;
end;

-- ============ TEXT EDITOR / RICH EDIT ============
function ui.textEditor(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local ed = GUI.newTextEditor();
    ed.parent = parent;
    ed.align = opts.align or "client";
    if opts.height then ed.height = opts.height; end;
    if opts.width then ed.width = opts.width; end;
    if opts.margins then ed.margins = opts.margins; end;
    
    ed.fontColor = opts.fontColor or t.text;
    pcall(function() ed.transparent = opts.transparent or false; end);
    pcall(function() ed.backgroundColor = opts.backgroundColor or t.bgAlt; end);
    
    if opts.field then pcall(function() ed.field = opts.field; end); end;
    if opts.onChange then pcall(function() ed.onChange = opts.onChange; end); end;
    return ed;
end;

function ui.richEdit(parent, opts)
    opts = opts or {};
    local t = ui.t();
    local ed = GUI.newRichEdit();
    ed.parent = parent;
    ed.align = opts.align or "client";
    if opts.height then ed.height = opts.height; end;
    if opts.width then ed.width = opts.width; end;
    if opts.margins then ed.margins = opts.margins; end;
    
    pcall(function() ed.defaultFontColor = opts.fontColor or t.text; end);
    pcall(function() ed.defaultFontSize = opts.fontSize or t.fontSize; end);
    pcall(function() ed.backgroundColor = opts.backgroundColor or t.bgAlt; end);
    pcall(function() ed.hideSelection = opts.hideSelection ~= false; end);
    pcall(function() ed.animateImages = opts.animateImages ~= false; end);
    
    if opts.field then pcall(function() ed.field = opts.field; end); end;
    if opts.onChange then
        local ok = pcall(function() ed:addEventListener("onChange", opts.onChange); end);
        if not ok then pcall(function() ed.onChange = opts.onChange; end); end;
    end;
    return ed;
end;

return ui;
