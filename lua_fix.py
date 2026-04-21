# -*- coding: utf-8 -*-
fp = r'C:\Users\aaron\Desktop\ND Fichas\Plugin ND\NDCombatPlugin.lfm'
with open(fp, 'rb') as f:
    lines = f.read().decode('utf-8').split('\r\n')

def fl(pat):
    for i, l in enumerate(lines):
        if pat in l: return i
    return -1

# MAX_LINHAS
idx = fl('local MAX_LINHAS = 12;')
lines[idx] = lines[idx].replace('12', '10')

# Replace renderizarTracker -> adicionarJogadores
rs = fl('local function renderizarTracker()')
re = fl('local function adicionarJogadores()')
new = [
'        local function renderizarTracker()',
'            if rodadaAtual == 0 then ordenarCombatentes(); end;',
'            for i = 1, MAX_LINHAS do',
'                local lblArrow = self["lblArrow" .. i];',
'                local btnChk = self["btnChk" .. i];',
'                local lblNome = self["lblNome" .. i];',
'                local lblIni = self["lblIni" .. i];',
'                local btnFof = self["btnFof" .. i];',
'                local btnX = self["btnX" .. i];',
'                local lblEfRow = self["lblEfRow" .. i];',
'                local lblDur = self["lblDur" .. i];',
'                local rowMain = self["rowMain" .. i];',
'                local rowEf = self["rowEf" .. i];',
'                if lblNome ~= nil then',
'                    if i &lt;= #combatentes then',
'                        local co = combatentes[i];',
'                        if rowMain ~= nil then rowMain.visible = true; end;',
'                        if rowEf ~= nil then rowEf.visible = true; end;',
'                        -- Arrow',
'                        if lblArrow ~= nil then',
'                            if i == turnoAtual then lblArrow.text = "&gt;"; lblArrow.fontColor = "#FFFFFF";',
'                            else lblArrow.text = ""; end;',
'                        end;',
'                        -- Checkbox',
'                        if btnChk ~= nil then',
'                            if co.checked == false then btnChk.text = "";',
'                            else btnChk.text = "X"; end;',
'                        end;',
'                        -- Nome',
'                        lblNome.text = co.nome or "?";',
'                        -- Ini',
'                        if lblIni ~= nil then lblIni.text = tostring(co.ini or 0); end;',
'                        -- FoF color',
'                        local fof = co.fof or "aliado";',
'                        local fofC = "#22C55E";',
'                        if fof == "neutro" then fofC = "#EAB308";',
'                        elseif fof == "inimigo" then fofC = "#EF4444"; end;',
'                        if btnFof ~= nil then btnFof.fontColor = fofC; btnFof.text = "@"; end;',
'                        -- Font colors',
'                        if i == turnoAtual then',
'                            lblNome.fontColor = "#FFFFFF";',
'                            if lblIni ~= nil then lblIni.fontColor = "#FFFFFF"; end;',
'                        else',
'                            lblNome.fontColor = "#C0C0C0";',
'                            if lblIni ~= nil then lblIni.fontColor = "#A0A0A0"; end;',
'                        end;',
'                        -- Effects sub-line',
'                        if lblEfRow ~= nil then',
'                            if co.efeitos ~= nil and #co.efeitos &gt; 0 then',
'                                local nomes = {};',
'                                local durTxt = "";',
'                                for ei = 1, #co.efeitos do',
'                                    table.insert(nomes, co.efeitos[ei].nome);',
'                                    local d = co.efeitos[ei].duracao or 0;',
'                                    if d &gt; 0 then durTxt = durTxt .. "[" .. d .. "] ";',
'                                    else durTxt = durTxt .. "[~] "; end;',
'                                end;',
'                                lblEfRow.text = table.concat(nomes, " | ");',
'                                if lblDur ~= nil then lblDur.text = durTxt; end;',
'                            else',
'                                lblEfRow.text = "";',
'                                if lblDur ~= nil then lblDur.text = ""; end;',
'                            end;',
'                        end;',
'                    else',
'                        if rowMain ~= nil then rowMain.visible = false; end;',
'                        if rowEf ~= nil then rowEf.visible = false; end;',
'                    end;',
'                end;',
'            end;',
'            if self.lblStatus ~= nil then',
'                local statusTxt = #combatentes .. " combatentes";',
'                if rodadaAtual &gt; 0 then',
'                    statusTxt = "Rodada " .. rodadaAtual;',
'                    if turnoAtual &gt; 0 and turnoAtual &lt;= #combatentes then',
'                        statusTxt = statusTxt .. " | Turno: " .. combatentes[turnoAtual].nome;',
'                    end;',
'                end;',
'                self.lblStatus.text = statusTxt;',
'            end;',
'            if self.lblRoundNum ~= nil then',
'                self.lblRoundNum.text = tostring(rodadaAtual);',
'            end;',
'        end;',
'',
'        local function toggleCheck(idx)',
'            if idx &gt; #combatentes then return; end;',
'            combatentes[idx].checked = not combatentes[idx].checked;',
'            renderizarTracker();',
'        end;',
'',
'        local function ciclarFoF(idx)',
'            if idx &gt; #combatentes then return; end;',
'            local co = combatentes[idx];',
'            if co.fof == "aliado" then co.fof = "neutro";',
'            elseif co.fof == "neutro" then co.fof = "inimigo";',
'            else co.fof = "aliado"; end;',
'            renderizarTracker();',
'        end;',
'',
'        local function removerCombatente(idx)',
'            if idx &gt; #combatentes then return; end;',
'            table.remove(combatentes, idx);',
'            if turnoAtual &gt; #combatentes then turnoAtual = #combatentes; end;',
'            renderizarTracker();',
'        end;',
'',
'        local function toggleNpcPanel()',
'            if self.pnlNpcInput ~= nil then',
'                self.pnlNpcInput.visible = not self.pnlNpcInput.visible;',
'            end;',
'        end;',
'',
]
lines[rs:re] = new
content = '\r\n'.join(lines)

# fof/checked
content = content.replace('baseIni = ini, bibCode = codPersonagem});', 'baseIni = ini, bibCode = codPersonagem, fof = "aliado", checked = true});')
content = content.replace('baseIni = 0, bibCode = nil});', 'baseIni = 0, bibCode = nil, fof = "aliado", checked = true});')
content = content.replace('tipo = "npc", bibCode = nil, baseIni = ini});', 'tipo = "npc", bibCode = nil, baseIni = ini, fof = "inimigo", checked = true});')

# Filter GM
content = content.replace('if jog ~= nil then\r\n                    local nick', 'if jog ~= nil and not jog.isMestre then\r\n                    local nick', 1)

# Limit 2 effects
content = content.replace(
    'if comb.efeitos == nil then comb.efeitos = {}; end;\r\n            table.insert(comb.efeitos, ef);\r\n            local durTxt',
    'if comb.efeitos == nil then comb.efeitos = {}; end;\r\n            if #comb.efeitos &gt;= 2 then\r\n                chat:enviarMensagem("[AVISO] " .. comb.nome .. " limite de efeitos.");\r\n                table.remove(comb.efeitos, 1);\r\n            end;\r\n            table.insert(comb.efeitos, ef);\r\n            local durTxt', 1)

with open(fp, 'wb') as f:
    f.write(content.encode('utf-8'))
print("Lua done!")
