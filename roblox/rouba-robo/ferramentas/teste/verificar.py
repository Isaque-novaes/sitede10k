#!/usr/bin/env python3
"""
Verifica o Rouba Robô sem abrir o Roblox Studio.

  1. Sintaxe: compila cada .luau com um Lua 5.1 (o Luau é baseado nele).
  2. Testes rápidos de Format e Config.
  3. Roda o jogo inteiro num Roblox simulado (roblox_simulado.lua) seguindo
     o roteiro de cenario.lua, conferindo cada nome de classe, propriedade,
     método, evento e enum contra a API oficial do Roblox.

Requisitos:  pip install lupa
A lista da API (Full-API-Dump.json) é baixada uma vez e guardada em .cache/.

Uso:  python3 ferramentas/teste/verificar.py
"""

from __future__ import annotations

import json
import pathlib
import sys
import urllib.request

AQUI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

from montar_place import SRC, listar_scripts  # noqa: E402

try:
    from lupa import lua51, luajit21
except ImportError:
    print("Instale o lupa antes:  pip install lupa")
    sys.exit(2)

URL_API = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json"
CACHE = AQUI / ".cache" / "Full-API-Dump.json"

TIPOS = {"Property": "P", "Function": "F", "Event": "E", "Callback": "C"}


def carregar_api() -> dict:
    if not CACHE.exists():
        print("Baixando a lista da API do Roblox...")
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(URL_API, timeout=60) as resposta:
            CACHE.write_bytes(resposta.read())
    bruto = json.loads(CACHE.read_text(encoding="utf-8"))

    classes = {}
    for c in bruto["Classes"]:
        membros = {}
        for m in c["Members"]:
            tipo = TIPOS.get(m["MemberType"])
            if not tipo:
                continue
            tags = {t for t in (m.get("Tags") or []) if isinstance(t, str)}
            info = {"k": tipo}
            seguranca = m.get("Security")
            if isinstance(seguranca, dict):
                if seguranca.get("Read") != "None":
                    info["sec"] = True
                if seguranca.get("Write") != "None":
                    info["ro"] = True
            elif seguranca not in (None, "None"):
                info["sec"] = True
            if "NotScriptable" in tags:
                info["sec"] = True
            if "ReadOnly" in tags:
                info["ro"] = True
            if "Deprecated" in tags:
                info["dep"] = True
            valor = m.get("ValueType")
            if valor:
                info["cat"] = valor.get("Category", "")
                info["tn"] = valor.get("Name", "")
            if "Default" in m and isinstance(m["Default"], str):
                info["def"] = m["Default"]
            membros[m["Name"]] = info
        classes[c["Name"]] = {
            "super": c["Superclass"],
            "tags": {t: True for t in (c.get("Tags") or []) if isinstance(t, str)},
            "m": membros,
        }
    enums = {e["Name"]: {i["Name"]: i["Value"] for i in e["Items"]} for e in bruto["Enums"]}
    return {"classes": classes, "enums": enums}


def checar_sintaxe() -> list[str]:
    lua = lua51.LuaRuntime()
    compilar = lua.eval("function(fonte, nome) local f, e = loadstring(fonte, nome) return e end")
    erros = []
    for _, _, _, caminho in listar_scripts():
        fonte = (SRC / caminho).read_text(encoding="utf-8")
        erro = compilar(fonte, "@" + caminho)
        if erro:
            erros.append(str(erro))
    return erros


TESTES_RAPIDOS = r"""
local Format, Config, Random = ...
local falhas = {}
local function igual(a, b, desc)
  if a ~= b then table.insert(falhas, desc .. ": esperado " .. tostring(b) .. ", veio " .. tostring(a)) end
end
igual(Format.numero(0), "0", "numero 0")
igual(Format.numero(999), "999", "numero 999")
igual(Format.numero(1000), "1K", "numero 1000")
igual(Format.numero(1500), "1,5K", "numero 1500")
igual(Format.numero(12345), "12,3K", "numero 12345")
igual(Format.numero(999999), "999K", "numero 999999")
igual(Format.numero(2300000), "2,3M", "numero 2,3M")
igual(Format.numero(1e9), "1B", "numero 1B")
igual(Format.numero(-1500), "-1,5K", "numero negativo")
igual(Format.dinheiro(25), "$25", "dinheiro")
igual(Format.tempo(65), "1:05", "tempo")
igual(Format.tempo(0.2), "0:01", "tempo arredonda pra cima")
igual(Format.multiplicador(1), "x1", "mult 1")
igual(Format.multiplicador(1.5), "x1,5", "mult 1,5")

-- catálogo consistente
local ids = {}
for i, r in ipairs(Config.Robos) do
  if ids[r.id] then table.insert(falhas, "id repetido: " .. r.id) end
  ids[r.id] = true
  if not Config.Raridades[r.raridade] then table.insert(falhas, "raridade inválida: " .. r.id) end
  if r.forma ~= "caixa" and r.forma ~= "barril" and r.forma ~= "bola" then table.insert(falhas, "forma inválida: " .. r.id) end
  if r.preco <= 0 or r.renda <= 0 then table.insert(falhas, "preço/renda inválidos: " .. r.id) end
  local anterior = Config.Robos[i - 1]
  if anterior and anterior.preco >= r.preco then table.insert(falhas, "preço fora de ordem: " .. r.id) end
end
for raridade = 1, #Config.Raridades do
  local tem = false
  for _, r in ipairs(Config.Robos) do if r.raridade == raridade then tem = true end end
  if not tem then table.insert(falhas, "raridade sem robôs: " .. raridade) end
end

-- sorteio: Comum aparece mais que Secreto, e a sorte aumenta os raros
local function contar(sorte)
  local aleatorio = Random.new(42)
  local c = {}
  for _ = 1, 20000 do
    local r, mut = Config.sortear(sorte, aleatorio)
    c[r.raridade] = (c[r.raridade] or 0) + 1
    if mut then c.mut = (c.mut or 0) + 1 end
  end
  return c
end
local normal, sorte = contar(1), contar(3)
if not ((normal[1] or 0) > (normal[7] or 0) * 20) then table.insert(falhas, "Comum deveria ser muito mais frequente que Secreto") end
if not ((sorte[5] or 0) > (normal[5] or 0) * 1.8) then table.insert(falhas, "Hora da Sorte deveria aumentar os Lendários") end
local taxaMut = (normal.mut or 0) / 20000
if taxaMut < 0.05 or taxaMut > 0.11 then table.insert(falhas, "taxa de mutação estranha: " .. taxaMut) end
igual(Config.custoRenascer(0), 1000000, "custo renascer 0")
igual(Config.custoRenascer(1), 5000000, "custo renascer 1")
igual(Config.precoDe(Config.RoboPorId.parafusinho, "dourado"), 50, "preço com mutação")
return falhas, normal
"""


def rodar(api: dict) -> int:
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.API = lua.table_from(api, recursive=True)
    g.ler_arquivo = lambda caminho: (SRC / caminho).read_text(encoding="utf-8")
    g.ARQUIVOS = lua.table_from([list(x) for x in listar_scripts()], recursive=True)

    sim = lua.execute((AQUI / "roblox_simulado.lua").read_text(encoding="utf-8"))

    # testes rápidos de módulos puros
    G = sim.G
    shared = sim.novaInstancia("Folder", True)
    config_mod = sim.criarScript("ModuleScript", "Config", "shared/Config.luau", shared)
    format_mod = sim.criarScript("ModuleScript", "Format", "shared/Format.luau", shared)
    falhas_rapidas, contagem = lua.execute(TESTES_RAPIDOS, sim.requerer(format_mod), sim.requerer(config_mod), G.Random)
    falhas_rapidas = list(falhas_rapidas.values())
    distribuicao = {int(k): v for k, v in contagem.items() if k != "mut"}
    print(f"Sorteio em 20000 robôs (por raridade 1..7): {dict(sorted(distribuicao.items()))}")

    # um Roblox novo para o cenário completo
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.API = lua.table_from(api, recursive=True)
    g.ler_arquivo = lambda caminho: (SRC / caminho).read_text(encoding="utf-8")
    g.ARQUIVOS = lua.table_from([list(x) for x in listar_scripts()], recursive=True)
    sim = lua.execute((AQUI / "roblox_simulado.lua").read_text(encoding="utf-8"))
    cenario = lua.execute((AQUI / "cenario.lua").read_text(encoding="utf-8"))
    resultado = cenario(sim)

    erros = list(sim.erros.values())
    avisos = list(sim.avisos.values())
    falhas = list(resultado.falhas.values())
    saida = list(sim.saida.values())

    print(f"\nTestes rápidos: {'OK' if not falhas_rapidas else f'{len(falhas_rapidas)} falha(s)'}")
    for f in falhas_rapidas:
        print("  FALHOU:", f)

    print(f"\nCenário: {resultado.ok} verificações OK, {len(falhas)} falha(s)")
    for f in falhas:
        print("  FALHOU:", f)

    if erros:
        print(f"\nErros de script ({len(erros)}):")
        for e in erros[:15]:
            print("  ---\n  " + e.replace("\n", "\n  "))
    if avisos:
        print(f"\nAvisos ({len(avisos)}):")
        for a in avisos:
            print("  -", a)
    avisos_jogo = [s for s in saida if s.startswith("AVISO")]
    if avisos_jogo:
        print(f"\nwarn() do jogo ({len(avisos_jogo)}):")
        for s in avisos_jogo[:10]:
            print("  -", s)

    return 1 if (falhas_rapidas or falhas or erros) else 0


def main() -> int:
    erros = checar_sintaxe()
    print(f"Sintaxe: {len(listar_scripts())} arquivos, {len(erros)} erro(s)")
    for e in erros:
        print("  ", e)
    if erros:
        return 1
    api = carregar_api()
    print(f"API do Roblox: {len(api['classes'])} classes, {len(api['enums'])} enums")
    codigo = rodar(api)
    print("\nRESULTADO:", "TUDO CERTO" if codigo == 0 else "HÁ PROBLEMAS")
    return codigo


if __name__ == "__main__":
    sys.exit(main())
