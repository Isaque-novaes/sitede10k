#!/usr/bin/env python3
"""
Gera o arquivo .rbxlx (um "place" do Roblox) de um jogo, a partir da pasta src/ dele.

Abra o .rbxlx no Roblox Studio (Arquivo > Abrir) e aperte Play: os scripts
já ficam nos lugares certos. É o mesmo resultado de `rojo build`, sem
precisar instalar o Rojo.

Regras (iguais às do Rojo):
  src/shared/X.luau         -> ReplicatedStorage/Shared/X        (ModuleScript)
  src/server/X.server.luau  -> ServerScriptService/Server/X      (Script)
  src/server/X.luau         -> ServerScriptService/Server/X      (ModuleScript)
  src/client/X.client.luau  -> StarterPlayer/StarterPlayerScripts/Client/X (LocalScript)

Uso:  python3 ferramentas/montar_place.py <pasta-do-jogo>
      (ex.: python3 ferramentas/montar_place.py lendas-elementais)
"""

from __future__ import annotations

import argparse
import itertools
import json
import pathlib
import sys
from xml.sax.saxutils import escape

ROBLOX = pathlib.Path(__file__).resolve().parent.parent


def jogos() -> list[str]:
    """Pastas que têm um jogo dentro (src/ + jogo.json)."""
    return sorted(p.name for p in ROBLOX.iterdir() if (p / "jogo.json").exists())


def escolher(nome: str | None) -> pathlib.Path:
    disponiveis = jogos()
    if nome is None:
        if len(disponiveis) == 1:
            nome = disponiveis[0]
        else:
            raise SystemExit("Diga qual jogo: " + ", ".join(disponiveis))
    if nome not in disponiveis:
        raise SystemExit(f"Não achei o jogo '{nome}'. Jogos: " + ", ".join(disponiveis))
    return ROBLOX / nome


# Preenchidos por usar_jogo(); as outras ferramentas leem estas variáveis.
RAIZ = ROBLOX
SRC = ROBLOX / "src"
SAIDA = ROBLOX / "jogo.rbxlx"


def usar_jogo(nome: str | None = None) -> pathlib.Path:
    global RAIZ, SRC, SAIDA
    RAIZ = escolher(nome)
    SRC = RAIZ / "src"
    dados = json.loads((RAIZ / "jogo.json").read_text(encoding="utf-8"))
    SAIDA = RAIZ / dados.get("arquivo", "jogo.rbxlx")
    return RAIZ

GRUPOS = {
    "shared": ("ReplicatedStorage", None, "Shared"),
    "server": ("ServerScriptService", None, "Server"),
    "client": ("StarterPlayer", "StarterPlayerScripts", "Client"),
}


def classe_e_nome(arquivo: pathlib.Path) -> tuple[str, str]:
    nome = arquivo.name
    if nome.endswith(".server.luau"):
        return "Script", nome[: -len(".server.luau")]
    if nome.endswith(".client.luau"):
        return "LocalScript", nome[: -len(".client.luau")]
    return "ModuleScript", nome[: -len(".luau")]


def listar_scripts() -> list[tuple[str, str, str, str]]:
    """Retorna [(grupo, nome, classe, caminho relativo a src)] em ordem estável."""
    itens = []
    for grupo in GRUPOS:
        for arquivo in sorted((SRC / grupo).glob("*.luau")):
            classe, nome = classe_e_nome(arquivo)
            itens.append((grupo, nome, classe, arquivo.relative_to(SRC).as_posix()))
    return itens


_ids = itertools.count(1)


def referencia() -> str:
    return f"RBX{next(_ids):032X}"


def cdata(texto: str) -> str:
    # "]]>" não pode aparecer dentro de CDATA: quebra em dois blocos
    return "<![CDATA[" + texto.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def item(classe: str, nome: str, filhos: list[str], fonte: str | None = None) -> str:
    props = [f'<string name="Name">{escape(nome)}</string>']
    if fonte is not None:
        props.append(f'<ProtectedString name="Source">{cdata(fonte)}</ProtectedString>')
    corpo = "".join(filhos)
    return (
        f'<Item class="{classe}" referent="{referencia()}">'
        f"<Properties>{''.join(props)}</Properties>{corpo}</Item>"
    )


def montar() -> str:
    por_grupo: dict[str, list[str]] = {g: [] for g in GRUPOS}
    for grupo, nome, classe, caminho in listar_scripts():
        fonte = (SRC / caminho).read_text(encoding="utf-8")
        por_grupo[grupo].append(item(classe, nome, [], fonte))

    servicos = []
    for grupo, (servico, intermediario, pasta) in GRUPOS.items():
        conteudo = item("Folder", pasta, por_grupo[grupo])
        if intermediario:
            conteudo = item(intermediario, intermediario, [conteudo])
        servicos.append(item(servico, servico, [conteudo]))

    return (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        + "".join(servicos)
        + "</roblox>\n"
    )


def main() -> int:
    analise = argparse.ArgumentParser(description=__doc__)
    analise.add_argument("jogo", nargs="?", help="pasta do jogo (ex.: rouba-robo)")
    argumentos = analise.parse_args()
    usar_jogo(argumentos.jogo)
    xml = montar()
    SAIDA.write_text(xml, encoding="utf-8")
    total = len(listar_scripts())
    print(f"Gerado {SAIDA.relative_to(ROBLOX)} com {total} scripts.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
