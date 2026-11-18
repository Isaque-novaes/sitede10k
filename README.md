# sitede10k

## Demo — Intercâmbios (log·aí Interno)

Protótipo navegável da tela de **Intercâmbios** (devolução de contêineres vazios pós-desova) para apresentação à gerência.
Arquivo único, sem instalação: abra `demo-intercambios/index.html` no navegador (Chrome ou Edge).
Funciona offline; os dados são fictícios e voltam ao estado inicial ao recarregar a página
(ou em **Conta ▸ Restaurar dados da demonstração**).

Fluxo demonstrado (sem conferência manual): o PDF entra no Loga-AI → os dados são extraídos →
o Navis N4 puxa o intercâmbio automaticamente → **Recebido → Aguardando N4 → Cadastrado no N4**.

Roteiro sugerido para a apresentação:

1. Arraste um PDF qualquer para **Enviar PDF do intercâmbio**: o sistema lê o documento e cria o intercâmbio `INT-2026-0457`.
2. Acompanhe o status mudar sozinho de **Recebido** para **Aguardando N4** e **Cadastrado no N4** (com aviso no sino).
3. Clique em **Ver detalhes** para mostrar o histórico de cada etapa.
4. Use os **Filtros de consulta**, ordene as colunas e clique em **Exportar Excel** (gera um `.xlsx`).

## Apresentação — antes e depois das automações

`apresentacao/antes-e-depois-automacoes.pptx` (6 slides, com notas do apresentador) e a versão em PDF.
Conteúdo: cadastro da SDA no PTVV e no Loga-AI (antes e depois das planilhas) e o projeto Intercâmbios (Loga-AI + Navis N4).
Os slides são gerados por `apresentacao/gerar-slides.js` (pptxgenjs).
