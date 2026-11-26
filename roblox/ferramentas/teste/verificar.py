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

Uso:  python3 ferramentas/teste/verificar.py <pasta-do-jogo>
      (ex.: python3 ferramentas/teste/verificar.py lendas-elementais)
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
import urllib.request

AQUI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))

import montar_place  # noqa: E402
from montar_place import listar_scripts, usar_jogo  # noqa: E402

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
        fonte = (montar_place.SRC / caminho).read_text(encoding="utf-8")
        erro = compilar(fonte, "@" + caminho)
        if erro:
            erros.append(str(erro))
    return erros




# Chaves de texto usadas no código (Textos.luau precisa ter pt e en para todas)
PADROES_CHAVES = [
    r'\bT\("([A-Za-z0-9_]+)"',
    r'Textos\.t\([^,()]+(?:\([^()]*\))?,\s*"([A-Za-z0-9_]+)"',
    r'notificar\([^,]+,\s*"(?:bom|ruim|alerta|info)",\s*"([A-Za-z0-9_]+)"',
    r'notificarTodos\("(?:bom|ruim|alerta|info)",\s*"([A-Za-z0-9_]+)"',
    r'falhar\([^,]+,\s*"([A-Za-z0-9_]+)"',
    r'linhaInfo\([^,]+,\s*\d+,\s*"([A-Za-z0-9_]+)"',
    r'SetAttribute\("Chave",\s*"([A-Za-z0-9_]+)"',
    r'placa\([^,]+,\s*"([A-Za-z0-9_]+)"',
    r'botaoMenu\([^,]+,\s*"([A-Za-z0-9_]+)"',
    r'\{\s*"(teste_[a-z]+)"',
    r'"(aba_[a-z]+)"',
    r'quadroDeAviso\(mapa,\s*"[A-Za-z]+",[^\n]*\n?\s*"([a-z_]+)"',
]



def chaves_usadas() -> set[str]:
    chaves = set()
    for _, _, _, caminho in listar_scripts():
        fonte = (montar_place.SRC / caminho).read_text(encoding="utf-8")
        for padrao in PADROES_CHAVES:
            # ignora prefixos de nomes montados ("melhoria_" .. tipo): esses são conferidos em FAMILIAS
            chaves.update(re.findall(padrao + r'(?!\s*\.\.)', fonte))
    return chaves


def checar_textos(lua, sim) -> list[str]:
    pasta = sim.novaInstancia("Folder", True)
    dados = sim.requerer(sim.criarScript("ModuleScript", "Textos", "shared/Textos.luau", pasta)).dados
    config = sim.requerer(sim.criarScript("ModuleScript", "Config", "shared/Config.luau", pasta))
    familias = montar_place.RAIZ / "teste" / "familias.lua"
    chaves = chaves_usadas()
    if familias.exists():
        chaves |= set(lua.execute(familias.read_text(encoding="utf-8"))(config).values())
    problemas = []
    for chave in sorted(chaves):
        entrada = dados[chave]
        if entrada is None:
            problemas.append(f"texto '{chave}' usado no código mas não existe em Textos.luau")
        elif entrada["pt"] is None or entrada["en"] is None:
            problemas.append(f"texto '{chave}' sem português ou sem inglês")
    return problemas


def rodar(api: dict) -> int:
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.API = lua.table_from(api, recursive=True)
    g.ler_arquivo = lambda caminho: (montar_place.SRC / caminho).read_text(encoding="utf-8")
    g.ARQUIVOS = lua.table_from([list(x) for x in listar_scripts()], recursive=True)

    sim = lua.execute((AQUI / "roblox_simulado.lua").read_text(encoding="utf-8"))

    # testes rápidos do jogo (números, tabelas e contas, sem montar o mundo)
    falhas_rapidas = []
    caminho_rapidos = montar_place.RAIZ / "teste" / "rapidos.lua"
    if caminho_rapidos.exists():
        resultado_rapidos = lua.execute(caminho_rapidos.read_text(encoding="utf-8"))(sim)
        falhas_rapidas = list((resultado_rapidos["falhas"] or {}).values())
        if resultado_rapidos["info"]:
            print(resultado_rapidos["info"])
    problemas_textos = checar_textos(lua, sim)
    print(f"Textos: {len(chaves_usadas())} chaves encontradas no código, {len(problemas_textos)} problema(s)")
    for problema in problemas_textos:
        print("  FALHOU:", problema)
    falhas_rapidas = falhas_rapidas + problemas_textos

    # um Roblox novo para o cenário completo
    lua = luajit21.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.API = lua.table_from(api, recursive=True)
    g.ler_arquivo = lambda caminho: (montar_place.SRC / caminho).read_text(encoding="utf-8")
    g.ARQUIVOS = lua.table_from([list(x) for x in listar_scripts()], recursive=True)
    sim = lua.execute((AQUI / "roblox_simulado.lua").read_text(encoding="utf-8"))
    cenario = lua.execute((montar_place.RAIZ / "teste" / "cenario.lua").read_text(encoding="utf-8"))
    from lupa.luajit21 import LuaError

    try:
        resultado = cenario(sim)
        falhas = list(resultado.falhas.values())
        quantos_ok = resultado.ok
    except LuaError as erro:
        # o roteiro parou no meio (normalmente porque o jogo quebrou antes)
        falhas = [f"o roteiro de teste parou: {erro}".split("\n")[0]]
        quantos_ok = 0

    erros = list(sim.erros.values())
    avisos = list(sim.avisos.values())
    saida = list(sim.saida.values())

    print(f"\nTestes rápidos: {'OK' if not falhas_rapidas else f'{len(falhas_rapidas)} falha(s)'}")
    for f in falhas_rapidas:
        print("  FALHOU:", f)

    print(f"\nCenário: {quantos_ok} verificações OK, {len(falhas)} falha(s)")
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
    analise = argparse.ArgumentParser(description=__doc__)
    analise.add_argument("jogo", nargs="?", help="pasta do jogo (ex.: rouba-robo)")
    argumentos = analise.parse_args()
    raiz = usar_jogo(argumentos.jogo)
    print(f"Jogo: {raiz.name}")
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
