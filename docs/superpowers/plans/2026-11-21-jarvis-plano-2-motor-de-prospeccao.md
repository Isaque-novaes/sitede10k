# Jarvis, plano 2 de 3: motor de prospecção

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Encontrar negócios locais no Google Maps, classificar e priorizar, preparar cada um (detalhes, Instagram, material, diagnóstico, textos, direção de arte, prévia publicada, mensagens) e acompanhar o funil, tudo com custo zero e funcionando sem a interface (linha de comando).

**Architecture:** Clientes finos para cada serviço externo (`src/externo/`) recebem um `fetch` injetável, então os testes usam respostas gravadas à mão e nunca chamam a internet. A lógica de negócio (`src/prospeccao/`, `src/ia/`, `src/vendas/`, `src/funil/`) só fala com esses clientes por meio de um objeto `servicos`. Os dados ficam em arquivos JSON locais com escrita atômica (`src/dados/`). A prévia é gerada pelo `gerarPrevia` do plano 1. O plano 3 vai construir a interface em cima das funções deste plano.

**Tech Stack:** Node.js 22 (ESM), `fetch` nativo, `node:test`, as dependências do plano 1 (sharp, playwright-core). Nenhuma dependência nova.

**Spec:** `docs/superpowers/specs/2026-11-21-jarvis-prospeccao-design.md` (seções 5.2, 5.3 "Busca", "Preparar um negócio", "Abordar", "Funil e acompanhamento", "Objeções", "Preço", "Falhas e casos de borda", 5.4 e 5.5). Plano 1: `docs/superpowers/plans/2026-11-21-jarvis-plano-1-kit-de-previas.md` (já na main).

## Global Constraints

- Tudo dentro de `jarvis/`. Node `>=22`, ESM, sem build, sem dependência nova. Caminhos com `node:path`.
- Nenhum teste chama a internet: todo cliente recebe `fetch` por injeção (`opcoes.fetch`), e os testes passam um `fetch` falso que devolve `new Response(...)` a partir de arquivos em `test/fixtures/apis/`.
- Chaves e segredos só no `.env` (fora do git). Configurações do usuário em `dados/config.json` (fora do git). Nunca gravar chave em log, aviso ou mensagem de erro.
- Custo zero: limites mensais no app de 800 chamadas por tipo do Google (`places_busca`, `places_detalhes`, `places_foto`); ao chegar no limite, a ação é bloqueada com `ErroCota` e aviso claro.
- Gemini: chave do AI Studio num projeto **sem faturamento**. Modelo configurável, padrão `gemini-flash-latest`, reserva `gemini-flash-lite-latest` quando o padrão devolver 429 ou 404. Sem busca no Google pelo Gemini (não é grátis): o @ do Instagram vem do site do Google Maps ou de nomes prováveis testados no Business Discovery, e o usuário sempre confirma.
- Instagram só pelo Business Discovery oficial (Graph API, versão configurável, padrão `v23.0`). Nada de raspagem, login automatizado ou acesso à página do Instagram.
- Envio de mensagem nunca é automático: o Jarvis só monta o texto e o link `wa.me`. No máximo 2 acompanhamentos por negócio. `naoContatar` é permanente e tira o negócio de buscas futuras.
- Toda escrita de dados é atômica (arquivo temporário e depois rename). Dados em `dados/` (já no `.gitignore`).
- Textos em português do Brasil, sem travessão nem meia-risca (usar `limparTracos` do plano 1 em tudo que vem da IA).
- Primeira mensagem de abordagem: até 400 caracteres, um achado concreto do diagnóstico, o link da prévia, sem pressão, assinada com o nome do usuário e o nome do estúdio.
- Prévia publicada: só `index.html` e `midias/` (as capturas de `conferencia/` ficam locais). Endereço `{baseUrlPrevias}/{slug}/`, com `baseUrlPrevias` padrão `https://{dono}.github.io/{repo}`.
- Remoção automática da prévia publicada quando o negócio vira `perdido`, `descartado` ou `naoContatar`, ou 45 dias depois da publicação se continua em `preparado` ou `abordado`.

## Review Focus

- **Chave ausente, inválida ou vencida** (Gemini, Meta, Pexels, GitHub): o passo que depende dela é pulado com um aviso que nomeia o serviço, e o resto do preparo continua. Só a falta da chave do Google bloqueia a busca. Testes nas Tarefas 2 e 13.
- **IA devolvendo lixo** (JSON quebrado, campos faltando, assinatura inválida, travessão, mensagem longa demais): cai na alternativa sem IA, sem travar. Testes nas Tarefas 6, 8 e 11.
- **Limite atingido no meio do preparo** (429 do Gemini, cota local do Google): o que já foi feito fica salvo, os passos seguintes usam alternativas e o negócio não fica corrompido. Testes nas Tarefas 1, 6 e 13.
- **Dados estranhos do Google** (sem telefone, só fixo, "site" que é Instagram, Linktree, Facebook ou `wa.me`, fechado temporariamente, o mesmo lugar em duas buscas): classificação certa, sem duplicar, fechados de fora. Testes nas Tarefas 3 e 4.
- **Preparar o mesmo negócio de novo**: nova versão da prévia, a anterior removida do GitHub, nenhum registro duplicado. Teste na Tarefa 13.

---

## Estrutura de arquivos

```
jarvis/
  .env.exemplo                     modelo das chaves (sem valores)
  src/
    config.js                      carregarConfig (.env + dados/config.json + padrões)
    dados/loja.js                  loja JSON atômica (negocios, buscas, uso)
    dados/uso.js                   contador mensal e limites
    externo/http.js                requisitarJson, requisitarBinario, ErroExterno
    externo/google-places.js       buscarLugares, detalharLugar, baixarFotoLugar
    externo/pagespeed.js           testarSite
    externo/gemini.js              gerarJson, ErroLimiteIA
    externo/instagram.js           descobrirPerfil, candidatosDeUsuario, encontrarInstagram
    externo/pexels.js              buscarFotosPexels
    externo/github.js              publicarPasta, removerPasta
    externo/baixar.js              baixarArquivo
    externo/servicos.js            criarServicos(config, {fetch})
    prospeccao/classificar.js      lugarParaNegocio, classificarPresenca, calcularPrioridade
    prospeccao/buscar.js           buscarNegocios
    prospeccao/diagnostico.js      diagnosticar
    prospeccao/preparar.js         prepararNegocio
    prospeccao/manutencao.js       limparPreviasVencidas, exportarDados, copiaSemanal
    ia/clima.js                    extrairClima
    ia/material.js                 escolherMaterial
    ia/arte.js                     sugerirAssinatura
    ia/textos.js                   escreverTextosPrevia
    ia/abordagem.js                escreverAbordagem
    vendas/mensagens.js            mensagensPadrao, ROTEIRO_OBJECOES, linkAbordagem
    vendas/precos.js               TABELA_PRECOS, sugerirPreco
    funil/funil.js                 ETAPAS, mudarEtapa, registrarAcompanhamento, cobrarHoje, marcarNaoContatar
    cli.js                         linha de comando para usar com chaves reais
  test/
    fixtures/apis/*.json           respostas gravadas à mão no formato documentado de cada API
    falsos.js                      criarFetchFalso, criarServicosFalsos
    *.test.js
```

## Tipos deste plano

Ficam em `src/prospeccao/tipos.js` (JSDoc), criados na Tarefa 1. O `Negocio` do plano 1 continua valendo para gerar a prévia; o `Registro` abaixo é o que fica guardado.

```js
/** @typedef {'encontrado'|'preparado'|'abordado'|'respondeu'|'reuniao'|'proposta'|'fechou'|'perdido'|'descartado'} Etapa */
/** @typedef {'sem_site'|'so_rede_social'|'site_fraco'|'site_ok'} Presenca */
/** @typedef {{id:string, nome:string, endereco?:string, bairro?:string, cidade?:string, local?:{lat:number,lng:number},
 *   tipos:string[], tipoPrincipal?:string, situacao:string, mapsUrl?:string, site?:string, telefone?:string,
 *   telefoneInternacional?:string, nota?:number, totalAvaliacoes?:number}} Lugar */
/** @typedef {{desempenho:number, lcpMs:number, https:boolean}} ResultadoSite */
/** @typedef {{data:string, desempenho?:ResultadoSite, temSite:boolean, https?:boolean, nota?:number, totalAvaliacoes?:number,
 *   instagram?:{seguidores:number, postsUltimos30Dias:number}, concorrentes:{total:number, comSite:number, melhorComSite?:string},
 *   resumo:string, achadoPrincipal:string}} Diagnostico */
/** @typedef {{primeira:string, acompanhamento1:string, acompanhamento2:string, objecoes:Record<string,string>}} Abordagem */
/** @typedef {{tipo:string, data:string, detalhe?:string}} Interacao */
/** @typedef {Lugar & {nicho:string, presenca:Presenca, prioridade:number, whatsappProvavel:boolean, etapa:Etapa,
 *   datas:Partial<Record<Etapa,string>>, acompanhamentos:number, ultimoAcompanhamento?:string, naoContatar:boolean,
 *   notas:string, historico:Interacao[], desempenhoSite?:ResultadoSite, clima?:string[], horarios?:string[],
 *   avaliacoes?:{autor:string,nota:number,texto:string}[], fotosGoogle?:{nome:string,largura:number,altura:number,credito:string}[],
 *   instagram?:{usuario:string, confirmado:boolean, bio?:string, seguidores?:number},
 *   diagnostico?:Diagnostico, previa?:{slug:string, url?:string, assinatura:object, publicadaEm?:string, versao:number, podeMostrar:boolean, problemas?:string[]},
 *   abordagem?:Abordagem, preco?:object}} Registro */
export {};
```

## Respostas das APIs (formato que as fixtures seguem)

Cada fixture em `test/fixtures/apis/` imita o formato documentado. Campos que o código lê:

- **Places Text Search** `POST https://places.googleapis.com/v1/places:searchText`, cabeçalhos `X-Goog-Api-Key` e `X-Goog-FieldMask`, corpo `{textQuery, languageCode:'pt-BR', regionCode:'BR', pageSize:20}` (concorrentes: `pageSize:10` e `locationBias:{circle:{center:{latitude,longitude}, radius:2000}}`). Resposta `{places:[{id, displayName:{text}, formattedAddress, addressComponents:[{longText, types}], location:{latitude,longitude}, types, primaryTypeDisplayName:{text}, businessStatus, googleMapsUri, websiteUri, nationalPhoneNumber, internationalPhoneNumber, rating, userRatingCount}]}`. Máscara da busca: `places.id,places.displayName,places.formattedAddress,places.addressComponents,places.location,places.types,places.primaryTypeDisplayName,places.businessStatus,places.googleMapsUri,places.websiteUri,places.nationalPhoneNumber,places.internationalPhoneNumber,places.rating,places.userRatingCount`.
- **Place Details** `GET https://places.googleapis.com/v1/places/{id}?languageCode=pt-BR`, máscara `id,regularOpeningHours,reviews,photos`. Resposta `{regularOpeningHours:{weekdayDescriptions:[...]}, reviews:[{rating, text:{text}, authorAttribution:{displayName}}], photos:[{name, widthPx, heightPx, authorAttributions:[{displayName}]}]}`.
- **Place Photo** `GET https://places.googleapis.com/v1/{photo.name}/media?maxWidthPx=1600&key=...` devolve os bytes da imagem.
- **PageSpeed** `GET https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=...&strategy=mobile&category=performance&key=...`. Resposta `{lighthouseResult:{finalUrl, categories:{performance:{score}}, audits:{'largest-contentful-paint':{numericValue}}}}`.
- **Gemini** `POST https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent`, cabeçalho `x-goog-api-key`, corpo `{contents:[{role:'user', parts:[{text}, {inline_data:{mime_type, data}}]}], generationConfig:{responseMimeType:'application/json', responseSchema, temperature}}`. Resposta `{candidates:[{content:{parts:[{text:'<json>'}]}}]}`. Limite: status 429.
- **Instagram Business Discovery** `GET https://graph.facebook.com/{versao}/{igUserId}?fields=business_discovery.username({usuario}){username,name,biography,followers_count,media_count,profile_picture_url,media.limit(30){media_type,media_url,thumbnail_url,caption,permalink,timestamp,like_count}}&access_token=...`. Resposta `{business_discovery:{username, name, biography, followers_count, media_count, media:{data:[{media_type:'IMAGE'|'VIDEO'|'CAROUSEL_ALBUM', media_url, thumbnail_url, caption, permalink, timestamp, like_count}]}}}`. Conta inexistente ou pessoal: status 400 com `{error:{code:110}}`. Token vencido: `{error:{code:190}}`.
- **Pexels** `GET https://api.pexels.com/v1/search?query=...&per_page=10&orientation=landscape&locale=pt-BR`, cabeçalho `Authorization: {chave}`. Resposta `{photos:[{id, width, height, photographer, src:{large2x}}]}`.
- **GitHub Git Data** (cabeçalhos `Authorization: Bearer {token}`, `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`): `GET /repos/{dono}/{repo}/git/ref/heads/{ramo}` → `{object:{sha}}`; `GET .../git/commits/{sha}` → `{tree:{sha}}`; `GET .../git/trees/{sha}?recursive=1` → `{tree:[{path,type,sha}]}`; `POST .../git/blobs {content, encoding:'base64'}` → `{sha}`; `POST .../git/trees {base_tree, tree:[{path, mode:'100644', type:'blob', sha}]}` (apagar: `sha:null`) → `{sha}`; `POST .../git/commits {message, tree, parents}` → `{sha}`; `PATCH .../git/refs/heads/{ramo} {sha}`.

---

### Task 1: Configuração, loja de dados e contador de uso

**Files:**
- Create: `jarvis/.env.exemplo`, `jarvis/src/config.js`, `jarvis/src/dados/loja.js`, `jarvis/src/dados/uso.js`, `jarvis/src/prospeccao/tipos.js`
- Test: `jarvis/test/dados.test.js`

**Interfaces:**
- Produces:
  - `carregarConfig({raiz?: string, env?: Record<string,string>}) -> Config`. `Config` tem: `chaves: {google?, gemini?, meta?, metaIgUserId?, pexels?, github?}`, `githubRepo?: 'dono/repo'`, `githubRamo: 'main'`, `baseUrlPrevias?: string`, `geminiModelo: 'gemini-flash-latest'`, `geminiReserva: 'gemini-flash-lite-latest'`, `metaVersao: 'v23.0'`, `pastaDados: '<raiz>/dados'`, e as preferências do usuário com padrões: `nomeUsuario: ''`, `estudio: 'Estúdio Dez'`, `whatsappUsuario: ''`, `cidadePadrao: ''`, `metaSemanal: 10`, `diasAcompanhamento: [3, 7]`, `nomeAssistente: 'Jarvis'`, `precos: {}` (sobrescreve a tabela). Lê `.env` (formato `CHAVE=valor`, ignora linhas vazias e `#`) e `dados/config.json`. Nomes no `.env`: `GOOGLE_API_KEY`, `GEMINI_API_KEY`, `META_TOKEN`, `META_IG_USER_ID`, `PEXELS_API_KEY`, `GITHUB_TOKEN`, `GITHUB_REPO`, `GITHUB_RAMO`, `BASE_URL_PREVIAS`, `GEMINI_MODELO`, `META_VERSAO`. `env` injetável para testes. `baseUrlPrevias` padrão `https://{dono}.github.io/{repo}` quando há `githubRepo`.
  - `salvarPreferencias(config, parcial) -> Promise<Config>` (grava em `dados/config.json`, nunca as chaves).
  - `criarLoja(pasta: string) -> {ler(colecao: string, padrao?: any): Promise<any>, gravar(colecao: string, valor: any): Promise<void>, atualizar(colecao: string, fn: (atual) => any, padrao?: any): Promise<any>}`. Coleção = arquivo `{pasta}/{colecao}.json`. `gravar` escreve em `{arquivo}.{pid}.{aleatorio}.tmp` e renomeia. `atualizar` serializa chamadas por coleção (fila em memória) para duas atualizações seguidas não se perderem.
  - `class ErroCota extends Error` com `servico`; `registrarUso(loja, api: string, quantidade = 1, hoje = new Date()) -> Promise<number>` (total do mês); `podeUsar(loja, api, quantidade = 1, hoje) -> Promise<boolean>`; `garantirCota(loja, api, quantidade = 1, hoje) -> Promise<void>` (lança `ErroCota` com mensagem "Limite mensal de segurança do Google atingido. Novas buscas voltam no dia 1."). `LIMITES = {places_busca: 800, places_detalhes: 800, places_foto: 800}`. Chave do mês `AAAA-MM` no fuso `America/Sao_Paulo`.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('carregarConfig lê .env injetado e aplica padrões', async () => {
  const c = await carregarConfig({ raiz: tmp, env: { GOOGLE_API_KEY: 'g', GITHUB_REPO: 'isaque/previas' } });
  assert.equal(c.chaves.google, 'g'); assert.equal(c.estudio, 'Estúdio Dez');
  assert.deepEqual(c.diasAcompanhamento, [3, 7]); assert.equal(c.geminiModelo, 'gemini-flash-latest');
  assert.equal(c.baseUrlPrevias, 'https://isaque.github.io/previas');
});
test('carregarConfig lê o arquivo .env da raiz', async () => {
  await writeFile(join(tmp, '.env'), '# comentário\nGEMINI_API_KEY=abc\n\nPEXELS_API_KEY = xyz\n');
  const c = await carregarConfig({ raiz: tmp, env: {} });
  assert.equal(c.chaves.gemini, 'abc'); assert.equal(c.chaves.pexels, 'xyz');
});
test('salvarPreferencias grava preferências e nunca chaves', async () => {
  const c = await carregarConfig({ raiz: tmp, env: { GOOGLE_API_KEY: 'segredo' } });
  await salvarPreferencias(c, { nomeUsuario: 'Isaque', cidadePadrao: 'Campinas' });
  const bruto = await readFile(join(tmp, 'dados', 'config.json'), 'utf8');
  assert.ok(!bruto.includes('segredo'));
  assert.equal((await carregarConfig({ raiz: tmp, env: {} })).nomeUsuario, 'Isaque');
});
test('loja grava e lê de forma atômica, sem sobrar temporário', async () => {
  const loja = criarLoja(join(tmp, 'd')); await loja.gravar('negocios', [{ id: 'a' }]);
  assert.deepEqual(await loja.ler('negocios'), [{ id: 'a' }]);
  assert.deepEqual((await readdir(join(tmp, 'd'))).filter((f) => f.endsWith('.tmp')), []);
  assert.deepEqual(await loja.ler('inexistente', []), []);
});
test('atualizações simultâneas não se perdem', async () => {
  const loja = criarLoja(join(tmp, 'e'));
  await Promise.all(Array.from({ length: 20 }, (_, i) => loja.atualizar('n', (v) => [...v, i], [])));
  assert.equal((await loja.ler('n')).length, 20);
});
test('cota mensal bloqueia ao chegar no limite e zera no mês seguinte', async () => {
  const loja = criarLoja(join(tmp, 'f')); const nov = new Date('2026-11-20T12:00:00-03:00');
  await registrarUso(loja, 'places_busca', 800, nov);
  assert.equal(await podeUsar(loja, 'places_busca', 1, nov), false);
  await assert.rejects(garantirCota(loja, 'places_busca', 1, nov), ErroCota);
  assert.equal(await podeUsar(loja, 'places_busca', 1, new Date('2026-12-01T09:00:00-03:00')), true);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/dados.test.js`. Expected: FAIL (módulos não existem).
- [ ] **Step 3: Implementar** os arquivos da lista (e `tipos.js` como na seção "Tipos"). `.env.exemplo` lista os nomes do `.env` com valor vazio e um comentário de uma linha por chave dizendo onde criá-la.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/dados.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): configuração, loja de dados e cota"`

---

### Task 2: HTTP, fetch falso, download e o objeto de serviços

**Files:**
- Create: `jarvis/src/externo/http.js`, `jarvis/src/externo/baixar.js`, `jarvis/src/externo/servicos.js`, `jarvis/test/falsos.js`
- Test: `jarvis/test/http.test.js`

**Interfaces:**
- Produces:
  - `class ErroExterno extends Error` com `servico: string`, `status: number`, `codigo?: string|number`, `temporario: boolean`. A `message` é uma frase curta em português que nomeia o serviço e nunca contém a chave (ex.: "O Google Maps recusou a chave. Confira a chave do Google nas configurações.").
  - `requisitarJson(url, {servico, metodo='GET', cabecalhos={}, corpo, fetch=globalThis.fetch, tentativas=2, tempoLimiteMs=20000}) -> Promise<any>`: 5xx e falha de rede repetem com espera de 500 ms e 1500 ms; 4xx não repete; 401/403 viram `ErroExterno` "recusou a chave"; 429 vira `temporario: true`. A URL nunca aparece na mensagem (pode conter chave).
  - `requisitarBinario(url, mesmas opcoes) -> Promise<Buffer>`.
  - `baixarArquivo(url, destino, opcoes) -> Promise<string>` (cria a pasta, grava os bytes, devolve `destino`).
  - Log local: `requisitarJson` e `requisitarBinario` aceitam `registrar?: (evento) => void` e chamam com `{data, servico, metodo, status, ms, erro?}`, sem URL nem chave. `criarRegistroLocal(pasta) -> (evento) => void` acrescenta uma linha JSON em `{pasta}/log.txt`.
  - `criarServicos(config, {fetch, registrar}) -> {places, pagespeed, gemini, instagram, pexels, github, baixar}`: cada propriedade é `null` quando falta a chave dela; as funções das Tarefas 3 a 10 recebem a `config` e o `fetch` já aplicados (por exemplo `servicos.places.buscar(texto)`). Esta tarefa cria o esqueleto e liga cada serviço quando a tarefa dele existir.
  - Em `test/falsos.js`: `criarFetchFalso(rotas: {metodo?: string, contem: string, status?: number, json?: any, arquivo?: string, bytes?: Buffer}[]) -> fetch` (a primeira rota cuja `contem` está na URL e cujo método bate responde; sem rota, lança erro "rota não gravada: {metodo} {url}"; guarda `fetch.chamadas = [{metodo, url, cabecalhos, corpo}]`), e `fixture(nome) -> any` (lê `test/fixtures/apis/{nome}.json`).

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('requisitarJson devolve o JSON e manda os cabeçalhos', async () => {
  const f = criarFetchFalso([{ contem: '/ok', json: { a: 1 } }]);
  assert.deepEqual(await requisitarJson('https://x/ok', { servico: 'Teste', cabecalhos: { 'X-K': '1' }, fetch: f }), { a: 1 });
  assert.equal(f.chamadas[0].cabecalhos['X-K'], '1');
});
test('5xx repete e depois funciona', async () => {
  let n = 0; const f = async () => (++n < 2 ? new Response('x', { status: 503 }) : Response.json({ ok: true }));
  assert.deepEqual(await requisitarJson('https://x/y', { servico: 'Teste', fetch: f }), { ok: true });
});
test('chave recusada vira erro em português sem a chave', async () => {
  const f = criarFetchFalso([{ contem: 'key=SEGREDO', status: 403, json: { error: { message: 'API key not valid' } } }]);
  await assert.rejects(requisitarJson('https://x/y?key=SEGREDO', { servico: 'Google Maps', fetch: f }), (e) =>
    e instanceof ErroExterno && e.message.includes('Google Maps') && !e.message.includes('SEGREDO') && e.status === 403);
});
test('429 é temporário', async () => {
  const f = criarFetchFalso([{ contem: '/', status: 429, json: {} }]);
  await assert.rejects(requisitarJson('https://x/', { servico: 'Gemini', fetch: f }), (e) => e.temporario === true);
});
test('baixarArquivo grava os bytes', async () => {
  const f = criarFetchFalso([{ contem: '/img', bytes: Buffer.from([1, 2, 3]) }]);
  const destino = await baixarArquivo('https://x/img', join(tmp, 'a', 'b.jpg'), { servico: 'Teste', fetch: f });
  assert.deepEqual([...await readFile(destino)], [1, 2, 3]);
});
test('o log registra serviço e status, nunca a chave', async () => {
  const eventos = []; const f = criarFetchFalso([{ contem: '/ok', json: {} }]);
  await requisitarJson('https://x/ok?key=SEGREDO', { servico: 'Google Maps', fetch: f, registrar: (e) => eventos.push(e) });
  assert.equal(eventos[0].servico, 'Google Maps'); assert.equal(eventos[0].status, 200);
  assert.ok(!JSON.stringify(eventos).includes('SEGREDO'));
});
test('criarServicos deixa nulo o serviço sem chave', () => {
  const s = criarServicos({ chaves: { google: 'g' } }, { fetch: criarFetchFalso([]) });
  assert.ok(s.places); assert.equal(s.gemini, null); assert.equal(s.github, null);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/http.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.** Tempo limite com `AbortSignal.timeout`.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/http.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): http, downloads e serviços injetáveis"`

---

### Task 3: Google Places (busca), classificação e prioridade

**Files:**
- Create: `jarvis/src/externo/google-places.js`, `jarvis/src/prospeccao/classificar.js`, `jarvis/test/fixtures/apis/places-busca.json`
- Test: `jarvis/test/places.test.js`

**Interfaces:**
- Consumes: `requisitarJson` (Tarefa 2), `normalizarTelefoneBR`, `provavelCelular` (plano 1), `identificarNicho` (plano 1).
- Produces:
  - `buscarLugares(texto, {chave, fetch, local?: {lat, lng}, raioM = 2000, quantidade = 20}) -> Promise<Lugar[]>` (máscara e corpo da seção "Respostas das APIs"; com `local`, manda `locationBias`). Converte cada resultado em `Lugar`: `bairro` vem do `addressComponents` com tipo `sublocality_level_1` ou `sublocality`, `cidade` do tipo `administrative_area_level_2`.
  - `classificarPresenca(site?: string, resultado?: ResultadoSite) -> Presenca`: sem site é `sem_site`; site em `instagram.com`, `facebook.com`, `fb.com`, `linktr.ee`, `wa.me`, `api.whatsapp.com`, `beacons.ai`, `bio.link` ou `linkbio` é `so_rede_social`; com `resultado` e (`desempenho < 50` ou `!https`) é `site_fraco`; senão `site_ok`.
  - `usuarioDoInstagramNoSite(site?: string) -> string|null` (`https://www.instagram.com/barbeariax/?hl=pt` → `barbeariax`).
  - `calcularPrioridade({presenca, nota, totalAvaliacoes}) -> number`: base `sem_site` 300, `so_rede_social` 250, `site_fraco` 150, `site_ok` 0; mais `min(totalAvaliacoes, 500) / 5` (até 100); mais `(nota - 4) * 40` quando há nota (pode ser negativo); o total é arredondado para inteiro.
  - `lugarParaRegistro(lugar, {nicho}, agora = new Date()) -> Registro` com `etapa: 'encontrado'`, `datas: {encontrado: agora.toISOString()}`, `acompanhamentos: 0`, `naoContatar: false`, `notas: ''`, `historico: []`, `whatsappProvavel: provavelCelular(telefone)`, `nicho: identificarNicho(nicho)`, `presenca` e `prioridade` calculados sem resultado de site.

A fixture `places-busca.json` tem 6 lugares: sem site com celular e 230 avaliações; "site" de Instagram; Linktree com fixo; site próprio; `businessStatus: 'CLOSED_TEMPORARILY'`; sem telefone e sem nota.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('buscarLugares manda máscara, corpo e chave e converte', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: fixture('places-busca') }]);
  const lugares = await buscarLugares('barbearias em Campinas', { chave: 'K', fetch: f });
  const { cabecalhos, corpo } = f.chamadas[0];
  assert.equal(cabecalhos['X-Goog-Api-Key'], 'K');
  assert.match(cabecalhos['X-Goog-FieldMask'], /places\.websiteUri/);
  assert.deepEqual(JSON.parse(corpo), { textQuery: 'barbearias em Campinas', languageCode: 'pt-BR', regionCode: 'BR', pageSize: 20 });
  assert.equal(lugares.length, 6); assert.equal(lugares[0].bairro, 'Cambuí'); assert.equal(lugares[0].cidade, 'Campinas');
});
test('concorrentes mandam locationBias de 2 km', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'places:searchText', json: { places: [] } }]);
  await buscarLugares('barbearia', { chave: 'K', fetch: f, local: { lat: -22.9, lng: -47.06 }, quantidade: 10 });
  assert.deepEqual(JSON.parse(f.chamadas[0].corpo).locationBias, { circle: { center: { latitude: -22.9, longitude: -47.06 }, radius: 2000 } });
});
test('classificarPresenca', () => {
  assert.equal(classificarPresenca(undefined), 'sem_site');
  for (const s of ['https://instagram.com/x', 'https://linktr.ee/x', 'https://wa.me/5519', 'http://facebook.com/x']) assert.equal(classificarPresenca(s), 'so_rede_social', s);
  assert.equal(classificarPresenca('https://x.com.br', { desempenho: 35, lcpMs: 9000, https: true }), 'site_fraco');
  assert.equal(classificarPresenca('http://x.com.br', { desempenho: 90, lcpMs: 1000, https: false }), 'site_fraco');
  assert.equal(classificarPresenca('https://x.com.br', { desempenho: 90, lcpMs: 1000, https: true }), 'site_ok');
});
test('usuarioDoInstagramNoSite', () => {
  assert.equal(usuarioDoInstagramNoSite('https://www.instagram.com/barbeariax/?hl=pt'), 'barbeariax');
  assert.equal(usuarioDoInstagramNoSite('https://linktr.ee/x'), null);
});
test('prioridade: sem site e muitas avaliações vem primeiro', () => {
  const a = calcularPrioridade({ presenca: 'sem_site', nota: 4.8, totalAvaliacoes: 230 });
  const b = calcularPrioridade({ presenca: 'site_fraco', nota: 4.9, totalAvaliacoes: 500 });
  const c = calcularPrioridade({ presenca: 'sem_site' });
  assert.ok(a > b && a > c); assert.equal(a, 378);
});
test('lugarParaRegistro marca WhatsApp provável e etapa inicial', () => {
  const r = lugarParaRegistro({ id: 'p1', nome: 'X', telefone: '(19) 99876-5432', tipos: [], situacao: 'OPERATIONAL' }, { nicho: 'Barbearia' }, new Date('2026-11-21T10:00:00Z'));
  assert.equal(r.whatsappProvavel, true); assert.equal(r.etapa, 'encontrado'); assert.equal(r.nicho, 'barbearia');
  assert.equal(r.datas.encontrado, '2026-11-21T10:00:00.000Z');
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/places.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar a fixture.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/places.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): busca no Google Maps e classificação"`

---

### Task 4: PageSpeed e o fluxo de busca

**Files:**
- Create: `jarvis/src/externo/pagespeed.js`, `jarvis/src/prospeccao/buscar.js`, `jarvis/test/fixtures/apis/pagespeed-lento.json`, `jarvis/test/fixtures/apis/pagespeed-rapido.json`
- Test: `jarvis/test/buscar.test.js`

**Interfaces:**
- Consumes: Tarefas 1 a 3.
- Produces:
  - `testarSite(url, {chave, fetch}) -> Promise<ResultadoSite>`: `desempenho = round(score * 100)`, `lcpMs = round(numericValue)`, `https = finalUrl.startsWith('https:')`.
  - `buscarNegocios({nicho, cidade}, {loja, servicos, agora?}) -> Promise<{novos: Registro[], ignorados: {fechados: number, jaConhecidos: number, naoContatar: number}, resumo: string}>`:
    1. `garantirCota(loja, 'places_busca')`; texto da busca `${nicho} em ${cidade}`; `registrarUso`.
    2. Descarta `situacao !== 'OPERATIONAL'`, ids já na coleção `negocios` (conta em `jaConhecidos`) e ids marcados `naoContatar`.
    3. Converte com `lugarParaRegistro`. Para quem tem site que não é rede social, roda `testarSite` com no máximo 3 ao mesmo tempo, guarda `desempenhoSite` e reclassifica. Falha no PageSpeed vira aviso e o negócio fica `site_ok` sem desempenho.
    4. Ordena por `prioridade` decrescente, acrescenta na coleção `negocios`, registra a busca na coleção `buscas` (`{nicho, cidade, data, total}`).
    5. `resumo`: "Encontrei {n} {nicho}. {k} não têm site. A melhor oportunidade é {nome}, nota {nota} com {total} avaliações e {descrição da presença}." (`sem_site` "sem site", `so_rede_social` "só com rede social", `site_fraco` "com um site fraco", `site_ok` "com site"; sem nota: omite o trecho da nota; nenhum novo: "Não encontrei negócios novos de {nicho} em {cidade}. Tente outra cidade ou outro nicho.").

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('testarSite lê nota, LCP e https', async () => {
  const f = criarFetchFalso([{ contem: 'runPagespeed', json: fixture('pagespeed-lento') }]);
  assert.deepEqual(await testarSite('https://x.com.br', { chave: 'K', fetch: f }), { desempenho: 31, lcpMs: 8400, https: true });
  assert.match(f.chamadas[0].url, /strategy=mobile/);
});
test('buscarNegocios filtra, testa sites, ordena e salva sem duplicar', async () => {
  const { loja, servicos } = await ambienteBusca(); // fixtures places-busca e pagespeed-lento
  const r1 = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r1.novos.length, 5); assert.equal(r1.ignorados.fechados, 1);
  assert.equal(r1.novos[0].presenca, 'sem_site');
  assert.ok(r1.novos.every((n, i, a) => i === 0 || a[i - 1].prioridade >= n.prioridade));
  assert.equal(r1.novos.find((n) => n.site === 'https://barbeariaprop.com.br').presenca, 'site_fraco');
  assert.match(r1.resumo, /^Encontrei 5 barbearias\. \d+ não têm site\./);
  const r2 = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r2.novos.length, 0); assert.equal(r2.ignorados.jaConhecidos, 5);
  assert.equal((await loja.ler('negocios')).length, 5);
});
test('negócio marcado não contatar nunca volta', async () => {
  const { loja, servicos } = await ambienteBusca();
  await loja.gravar('negocios', [{ id: 'sem-site-1', naoContatar: true }]);
  const r = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r.ignorados.naoContatar, 1); assert.ok(!r.novos.some((n) => n.id === 'sem-site-1'));
});
test('PageSpeed fora do ar não derruba a busca', async () => {
  const { loja, servicos } = await ambienteBusca({ pagespeedStatus: 500 });
  const r = await buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos });
  assert.equal(r.novos.length, 5);
});
test('cota esgotada bloqueia a busca com ErroCota', async () => {
  const { loja, servicos } = await ambienteBusca();
  await registrarUso(loja, 'places_busca', 800);
  await assert.rejects(buscarNegocios({ nicho: 'barbearias', cidade: 'Campinas' }, { loja, servicos }), ErroCota);
});
```

`ambienteBusca(opcoes)` fica em `test/falsos.js` e monta loja temporária mais `criarServicos` com o fetch falso.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/buscar.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar as fixtures.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/buscar.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): fluxo de busca com teste de site"`

---

### Task 5: Detalhes do Google, fotos e diagnóstico

**Files:**
- Create: `jarvis/src/prospeccao/diagnostico.js`, `jarvis/test/fixtures/apis/places-detalhes.json`, `jarvis/test/fixtures/apis/places-concorrentes.json`
- Modify: `jarvis/src/externo/google-places.js` (detalhes e fotos)
- Test: `jarvis/test/diagnostico.test.js`

**Interfaces:**
- Produces:
  - `detalharLugar(id, {chave, fetch}) -> Promise<{horarios: string[], avaliacoes: {autor, nota, texto}[], fotos: {nome, largura, altura, credito}[]}>` (até 5 avaliações com texto, até 10 fotos; crédito "Foto: {autor} (Google Maps)" ou "Foto: Google Maps").
  - `baixarFotoLugar(nome, destino, {chave, fetch, larguraMax = 1600}) -> Promise<string>`.
  - `diagnosticar(registro, {loja, servicos, agora?}) -> Promise<Diagnostico>`: concorrentes pela busca com `local` (10 resultados, sem o próprio negócio, conta `places_busca`), `melhorComSite` = o de maior nota com site próprio; `instagram` a partir de `registro.instagram` quando houver (posts dos últimos 30 dias contados pelo `timestamp`). `achadoPrincipal` é uma frase curta, escolhida nesta ordem: sem site e concorrente com site ("A {concorrente}, aqui perto, já tem site e aparece melhor no Google."), sem site ("Vocês não têm site, e quem procura no Google acaba só no Instagram."), site lento ("O site de vocês leva {s} segundos para abrir no celular."), sem https ("O site de vocês aparece como não seguro no navegador."), padrão ("Vocês têm nota {nota} no Google, e um site pode mostrar isso para quem ainda não conhece."). `resumo` junta 2 ou 3 frases em linguagem de dono de negócio.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('detalharLugar traz horários, até 5 avaliações e até 10 fotos', async () => {
  const f = criarFetchFalso([{ contem: '/v1/places/sem-site-1', json: fixture('places-detalhes') }]);
  const d = await detalharLugar('sem-site-1', { chave: 'K', fetch: f });
  assert.equal(d.horarios[0], 'segunda-feira: 09:00–19:00');
  assert.ok(d.avaliacoes.length <= 5 && d.avaliacoes.every((a) => a.texto));
  assert.ok(d.fotos.length <= 10); assert.match(d.fotos[0].credito, /Google Maps/);
  assert.equal(f.chamadas[0].cabecalhos['X-Goog-FieldMask'], 'id,regularOpeningHours,reviews,photos');
});
test('baixarFotoLugar pede 1600 px', async () => {
  const f = criarFetchFalso([{ contem: '/media?maxWidthPx=1600', bytes: Buffer.from([9]) }]);
  await baixarFotoLugar('places/x/photos/y', join(tmp, 'f.jpg'), { chave: 'K', fetch: f });
  assert.ok(existsSync(join(tmp, 'f.jpg')));
});
test('diagnóstico de negócio sem site com concorrente com site', async () => {
  const { loja, servicos } = await ambienteDiagnostico();
  const d = await diagnosticar(registroSemSite, { loja, servicos });
  assert.equal(d.temSite, false); assert.ok(d.concorrentes.total > 0);
  assert.match(d.achadoPrincipal, /já tem site/); assert.ok(!/[—–]/.test(d.resumo));
});
test('diagnóstico de site lento cita os segundos', async () => {
  const { loja, servicos } = await ambienteDiagnostico({ concorrentes: [] });
  const d = await diagnosticar({ ...registroSemSite, site: 'https://x.com.br', presenca: 'site_fraco', desempenhoSite: { desempenho: 30, lcpMs: 8400, https: true } }, { loja, servicos });
  assert.match(d.achadoPrincipal, /8,4 segundos/);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/diagnostico.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar as fixtures. `places-detalhes.json` inclui um horário com "–", 7 avaliações (uma sem texto) e 12 fotos.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/diagnostico.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): detalhes do Google e diagnóstico"`

---

### Task 6: Cliente do Gemini

**Files:**
- Create: `jarvis/src/externo/gemini.js`, `jarvis/test/fixtures/apis/gemini-ok.json`
- Test: `jarvis/test/gemini.test.js`

**Interfaces:**
- Produces:
  - `class ErroLimiteIA extends Error`.
  - `gerarJson({prompt: string, esquema: object, imagens?: {mime: string, base64: string}[], temperatura = 0.8}, {chave, fetch, modelo, reserva}) -> Promise<any>`: tenta `modelo`; em 429 ou 404 tenta `reserva`; se a reserva também der 429, lança `ErroLimiteIA`. Lê `candidates[0].content.parts[0].text`, faz `JSON.parse` e valida com `validarEsquema`; JSON inválido ou fora do esquema repete uma vez e depois lança `ErroExterno` com `servico: 'Gemini'`.
  - `validarEsquema(valor, esquema) -> boolean`: subconjunto do formato `responseSchema` do Gemini (`type` OBJECT, ARRAY, STRING, NUMBER, INTEGER, BOOLEAN; `properties`; `required`; `items`; `enum`; `maxItems`).
  - `prepararImagem(caminho, larguraMax = 512) -> Promise<{mime: 'image/jpeg', base64: string}>` (reduz com sharp antes de enviar, para gastar menos limite).

- [ ] **Step 1: Escrever os testes que falham:**

```js
const esquema = { type: 'OBJECT', properties: { titulo: { type: 'STRING' }, notas: { type: 'ARRAY', items: { type: 'NUMBER' } } }, required: ['titulo'] };
test('gerarJson manda esquema e chave e devolve o objeto', async () => {
  const f = criarFetchFalso([{ metodo: 'POST', contem: 'gemini-flash-latest:generateContent', json: fixture('gemini-ok') }]);
  const r = await gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'gemini-flash-latest', reserva: 'gemini-flash-lite-latest' });
  assert.deepEqual(r, { titulo: 'Seu estilo', notas: [4.8] });
  const corpo = JSON.parse(f.chamadas[0].corpo);
  assert.equal(corpo.generationConfig.responseMimeType, 'application/json'); assert.deepEqual(corpo.generationConfig.responseSchema, esquema);
  assert.equal(f.chamadas[0].cabecalhos['x-goog-api-key'], 'K');
});
test('429 no modelo principal usa a reserva', async () => {
  const f = criarFetchFalso([{ contem: 'gemini-flash-latest:', status: 429, json: {} }, { contem: 'gemini-flash-lite-latest:', json: fixture('gemini-ok') }]);
  assert.equal((await gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'gemini-flash-latest', reserva: 'gemini-flash-lite-latest' })).titulo, 'Seu estilo');
});
test('429 nos dois vira ErroLimiteIA', async () => {
  const f = criarFetchFalso([{ contem: 'generateContent', status: 429, json: {} }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), ErroLimiteIA);
});
test('JSON fora do esquema repete uma vez e depois falha', async () => {
  const ruim = { candidates: [{ content: { parts: [{ text: '{"notas":"x"}' }] } }] };
  const f = criarFetchFalso([{ contem: 'generateContent', json: ruim }]);
  await assert.rejects(gerarJson({ prompt: 'oi', esquema }, { chave: 'K', fetch: f, modelo: 'a', reserva: 'b' }), ErroExterno);
  assert.equal(f.chamadas.length, 2);
});
test('validarEsquema confere enum, required e maxItems', () => {
  const e = { type: 'OBJECT', properties: { t: { type: 'STRING', enum: ['a', 'b'] }, l: { type: 'ARRAY', maxItems: 2, items: { type: 'STRING' } } }, required: ['t'] };
  assert.equal(validarEsquema({ t: 'a', l: ['x'] }, e), true);
  assert.equal(validarEsquema({ t: 'c' }, e), false); assert.equal(validarEsquema({ l: [] }, e), false);
  assert.equal(validarEsquema({ t: 'a', l: ['1', '2', '3'] }, e), false);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/gemini.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar a fixture.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/gemini.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): cliente do Gemini com reserva e validação"`

---

### Task 7: Instagram (Business Discovery, achar o @, mídias)

**Files:**
- Create: `jarvis/src/externo/instagram.js`, `jarvis/test/fixtures/apis/instagram-perfil.json`, `jarvis/test/fixtures/apis/instagram-erro-110.json`, `jarvis/test/fixtures/apis/instagram-erro-190.json`
- Test: `jarvis/test/instagram.test.js`

**Interfaces:**
- Consumes: `requisitarJson`, `baixarArquivo` (Tarefa 2), `normalizar` (plano 1), `usuarioDoInstagramNoSite` (Tarefa 3).
- Produces:
  - `descobrirPerfil(usuario, {token, igUserId, versao, fetch}) -> Promise<PerfilInstagram|null>` com `PerfilInstagram = {usuario, nome, bio, seguidores, totalPosts, midias: {tipo: 'foto'|'video', url, legenda, data, curtidas, link}[]}`. Carrossel vira foto (usa `media_url`); vídeo sem `media_url` (download bloqueado pelo dono) é ignorado. Erro 110 devolve `null` (conta pessoal ou inexistente). Erro 190 lança `ErroExterno` "A chave da Meta venceu. Renove nas configurações." com `codigo: 190`.
  - `candidatosDeUsuario(registro) -> string[]` (até 8, sem repetir): o @ do site (quando houver) primeiro; depois variações do nome normalizado sem espaço, com ponto e com sublinhado entre palavras, sem a palavra do nicho, e com a cidade no fim (ex.: "Barbearia Navalha de Ouro", Campinas: `barbearianavalhadeouro`, `barbearia.navalhadeouro`, `barbearia_navalhadeouro`, `navalhadeouro`, `navalhadeouro.campinas`...). Remove "de", "da", "do", "das", "dos", "e" ao juntar.
  - `encontrarInstagram(registro, {descobrir}) -> Promise<{usuario, confianca: number, perfil}[]>`: chama `descobrir` em sequência para os candidatos (para no primeiro com confiança `>= 0.8`), ordena por confiança. Confiança: 0.5 pela semelhança do nome do perfil com o nome do negócio (palavras em comum / palavras do negócio, sem nicho e sem palavras curtas), +0.3 se a cidade ou o bairro aparece na bio ou no nome, +0.2 se veio do site do Google. Máximo 1.
  - `baixarMidiasInstagram(perfil, pasta, {fetch, maxFotos = 12}) -> Promise<Midia[]>` (formato `Midia` do plano 1, `origem: 'instagram'`, `credito: '@usuario'`): as fotos mais curtidas primeiro e no máximo 1 vídeo (o mais recente), com no máximo 4 downloads ao mesmo tempo. Download que falha vira aviso e a mídia é pulada.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('descobrirPerfil monta a consulta e converte', async () => {
  const f = criarFetchFalso([{ contem: 'business_discovery.username(navalhadeouro)', json: fixture('instagram-perfil') }]);
  const p = await descobrirPerfil('navalhadeouro', { token: 'T', igUserId: '178', versao: 'v23.0', fetch: f });
  assert.match(f.chamadas[0].url, /graph\.facebook\.com\/v23\.0\/178\?fields=/);
  assert.equal(p.usuario, 'navalhadeouro'); assert.ok(p.midias.some((m) => m.tipo === 'video'));
  assert.ok(p.midias.every((m) => m.url));
});
test('conta pessoal devolve null e token vencido avisa', async () => {
  const f110 = criarFetchFalso([{ contem: 'graph.facebook.com', status: 400, json: fixture('instagram-erro-110') }]);
  assert.equal(await descobrirPerfil('pessoal', { token: 'T', igUserId: '1', versao: 'v23.0', fetch: f110 }), null);
  const f190 = criarFetchFalso([{ contem: 'graph.facebook.com', status: 400, json: fixture('instagram-erro-190') }]);
  await assert.rejects(descobrirPerfil('x', { token: 'T', igUserId: '1', versao: 'v23.0', fetch: f190 }), (e) => e.codigo === 190 && /venceu/.test(e.message));
});
test('candidatosDeUsuario', () => {
  const c = candidatosDeUsuario({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas', site: 'https://instagram.com/navalha.oficial' });
  assert.equal(c[0], 'navalha.oficial');
  for (const u of ['barbearianavalhaouro', 'barbearia.navalhaouro', 'navalhaouro', 'navalhaouro.campinas']) assert.ok(c.includes(u), u);
  assert.ok(c.length <= 8 && new Set(c).size === c.length);
});
test('encontrarInstagram para no primeiro candidato confiável', async () => {
  const chamados = [];
  const descobrir = async (u) => { chamados.push(u); return u === 'navalhaouro' ? { usuario: u, nome: 'Navalha de Ouro Barbearia', bio: 'Barbearia em Campinas', midias: [] } : null; };
  const r = await encontrarInstagram({ nome: 'Barbearia Navalha de Ouro', nicho: 'barbearia', cidade: 'Campinas' }, { descobrir });
  assert.equal(r[0].usuario, 'navalhaouro'); assert.ok(r[0].confianca >= 0.8); assert.equal(chamados.at(-1), 'navalhaouro');
});
test('baixarMidiasInstagram baixa as mais curtidas e um vídeo só', async () => {
  const f = criarFetchFalso([{ contem: 'cdninstagram', bytes: Buffer.from([1]) }]);
  const ms = await baixarMidiasInstagram(perfilComMidias(15, 2), tmp, { fetch: f, maxFotos: 12 });
  assert.equal(ms.filter((m) => m.tipo === 'foto').length, 12); assert.equal(ms.filter((m) => m.tipo === 'video').length, 1);
  assert.ok(ms.every((m) => m.credito === '@navalhadeouro' && m.origem === 'instagram'));
});
```

`perfilComMidias(fotos, videos)` fica em `test/falsos.js`.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/instagram.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar as fixtures. Na consulta, o `usuario` entra sem `@` e só com `[a-z0-9._]`; qualquer outro caractere faz `descobrirPerfil` devolver `null` sem chamar a API.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/instagram.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): Instagram pelo Business Discovery"`

---

### Task 8: IA que prepara a prévia (clima, material, arte, textos)

**Files:**
- Create: `jarvis/src/ia/clima.js`, `jarvis/src/ia/material.js`, `jarvis/src/ia/arte.js`, `jarvis/src/ia/textos.js`
- Test: `jarvis/test/ia-previa.test.js`

**Interfaces:**
- Consumes: `gerarJson`, `ErroLimiteIA`, `prepararImagem` (Tarefa 6); do plano 1: `textosBase`, `validarAssinatura`, `opcoesPossiveis`, catálogo (`TOPOS`, `SECOES`, `VARIANTES`, `MOVIMENTOS`, `FONTES`), `limparTextos`.
- Produces (todas recebem `gemini` = `servicos.gemini` ou `null`; com `null`, com `ErroLimiteIA` ou com `ErroExterno`, usam a alternativa e devolvem `{..., porIA: false, aviso}`):
  - `extrairClima(registro, perfil?, {gemini}) -> Promise<{clima: string[], porIA: boolean, aviso?: string}>`: de 2 a 4 palavras do vocabulário fixo `['acolhedor','familiar','classico','elegante','sofisticado','premium','moderno','jovem','urbano','forte','esportivo','energico','divertido','criativo','artesanal','gastronomia','natureza','discreto','profissional','clinico','noturno']` (esquema com `enum`). Alternativa: `CLIMA_POR_NICHO` (barbearia `['urbano','classico']`, salao `['elegante','acolhedor']`, estetica `['sofisticado','discreto']`, restaurante `['acolhedor','gastronomia']`, pizzaria `['familiar','gastronomia']`, hamburgueria `['jovem','urbano']`, cafeteria `['acolhedor','artesanal']`, padaria `['familiar','artesanal']`, clinica `['profissional','clinico']`, odontologia `['profissional','discreto']`, academia `['energico','esportivo']`, petshop `['divertido','familiar']`, oficina `['forte','profissional']`, imobiliaria `['sofisticado','profissional']`, generico `['acolhedor','profissional']`).
  - `escolherMaterial(midias: Midia[], {gemini, maxFotos = 10}) -> Promise<{midias: Midia[], porIA, aviso?}>`: manda até 20 fotos reduzidas (Tarefa 6) e pede os índices das melhores (nítidas, sem texto grande, variadas). Índices inválidos são ignorados. O vídeo (se houver) é mantido sempre. Alternativa: fotos do Instagram primeiro, depois as do Google, até `maxFotos`.
  - `sugerirAssinatura(contexto, usadas, {gemini}) -> Promise<{assinatura: Assinatura|null, porIA, aviso?}>`: o esquema limita `topo`, `fontes`, `movimento` e variantes ao catálogo; a paleta vem pronta do plano 1 (a IA não escolhe cores). Resultado que não passa em `validarAssinatura` devolve `assinatura: null` com aviso (o `gerarPrevia` escolhe por regras).
  - `escreverTextosPrevia(registro, diagnostico, {gemini}) -> Promise<{textos: TextosPrevia, porIA, aviso?}>`: na voz do negócio, com palavras das avaliações; esquema com `servicos` 3 a 6 e `perguntas` 2 a 5; passa por `limparTextos`. Título com mais de 60 caracteres ou serviços com menos de 3 caem na alternativa `textosBase`.

- [ ] **Step 1: Escrever os testes que falham** (com um `gemini` falso que devolve objetos fixos ou lança):

```js
test('clima pela IA usa só o vocabulário', async () => {
  const r = await extrairClima(registro, null, { gemini: geminiQueDevolve({ clima: ['urbano', 'classico'] }) });
  assert.deepEqual(r.clima, ['urbano', 'classico']); assert.equal(r.porIA, true);
});
test('sem IA, o clima vem do nicho', async () => {
  const r = await extrairClima({ ...registro, nicho: 'pizzaria' }, null, { gemini: null });
  assert.deepEqual(r.clima, ['familiar', 'gastronomia']); assert.equal(r.porIA, false);
});
test('limite da IA vira alternativa com aviso', async () => {
  const r = await extrairClima(registro, null, { gemini: geminiQueLanca(new ErroLimiteIA('limite')) });
  assert.equal(r.porIA, false); assert.match(r.aviso, /limite/i);
});
test('escolherMaterial respeita índices válidos e mantém o vídeo', async () => {
  const midias = [...fotosFalsasMidia(6, 'instagram'), videoMidia, ...fotosFalsasMidia(4, 'google')];
  const r = await escolherMaterial(midias, { gemini: geminiQueDevolve({ indices: [2, 0, 99, 2] }) });
  assert.deepEqual(r.midias.filter((m) => m.tipo === 'foto').map((m) => m.arquivo), [midias[2].arquivo, midias[0].arquivo]);
  assert.ok(r.midias.some((m) => m.tipo === 'video'));
});
test('sugestão de arte inválida volta nula com aviso', async () => {
  const r = await sugerirAssinatura(contexto, [], { gemini: geminiQueDevolve({ topo: 'foto-cheia', fontes: 'comic', movimento: 'suave', secoes: [] }) });
  assert.equal(r.assinatura, null); assert.match(r.aviso, /assinatura/);
});
test('textos da IA passam pela limpeza de travessões', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueDevolve({ ...textosIA, titulo: 'Corte — barba' }) });
  assert.ok(!/[—–]/.test(JSON.stringify(r.textos)));
});
test('título longo demais cai na alternativa', async () => {
  const r = await escreverTextosPrevia(registro, diagnostico, { gemini: geminiQueDevolve({ ...textosIA, titulo: 'x'.repeat(80) }) });
  assert.equal(r.porIA, false);
});
```

`geminiQueDevolve`, `geminiQueLanca`, `fotosFalsasMidia`, `videoMidia`, `registro`, `diagnostico`, `contexto` e `textosIA` ficam em `test/falsos.js`.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/ia-previa.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.** Cada prompt em português, curto, com o pedido de não usar travessão e de não inventar fatos (preço, horário, endereço) que não estejam nos dados enviados.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/ia-previa.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): IA para clima, material, arte e textos"`

---

### Task 9: Pexels para completar fotos

**Files:**
- Create: `jarvis/src/externo/pexels.js`, `jarvis/test/fixtures/apis/pexels-busca.json`
- Test: `jarvis/test/pexels.test.js`

**Interfaces:**
- Produces:
  - `CONSULTA_PEXELS` por nicho (inglês, que dá mais resultado): barbearia `barbershop interior`, salao `hair salon`, estetica `spa facial treatment`, restaurante `restaurant food`, pizzaria `wood fired pizza`, hamburgueria `burger restaurant`, cafeteria `coffee shop`, padaria `bakery bread`, clinica `medical clinic`, odontologia `dental clinic`, academia `gym workout`, petshop `dog grooming`, oficina `car mechanic`, imobiliaria `modern house interior`, generico `small business`.
  - `completarComPexels(midias: Midia[], nicho, pasta, {chave, fetch, minimo = 4}) -> Promise<{midias: Midia[], aviso?: string}>`: se já há `minimo` fotos, devolve igual; senão baixa as que faltam (`src.large2x`) com `origem: 'pexels'` e `credito: 'Foto: {photographer} (Pexels)'`, e devolve o aviso "Esta prévia tem poucas fotos reais do negócio."

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('completa até 4 fotos com crédito do Pexels e avisa', async () => {
  const f = criarFetchFalso([{ contem: 'api.pexels.com/v1/search', json: fixture('pexels-busca') }, { contem: 'images.pexels.com', bytes: Buffer.from([1]) }]);
  const r = await completarComPexels(fotosFalsasMidia(1, 'google'), 'pizzaria', tmp, { chave: 'P', fetch: f });
  assert.equal(r.midias.length, 4); assert.ok(r.midias.slice(1).every((m) => m.origem === 'pexels' && /\(Pexels\)$/.test(m.credito)));
  assert.match(f.chamadas[0].url, /query=wood%20fired%20pizza/); assert.equal(f.chamadas[0].cabecalhos.Authorization, 'P');
  assert.match(r.aviso, /poucas fotos reais/);
});
test('com fotos suficientes não chama o Pexels', async () => {
  const f = criarFetchFalso([]);
  const r = await completarComPexels(fotosFalsasMidia(5, 'instagram'), 'pizzaria', tmp, { chave: 'P', fetch: f });
  assert.equal(r.midias.length, 5); assert.equal(f.chamadas.length, 0);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/pexels.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar** e criar a fixture.
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/pexels.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): fotos do Pexels para completar prévias"`

---

### Task 10: Publicação no GitHub Pages

**Files:**
- Create: `jarvis/src/externo/github.js`
- Test: `jarvis/test/github.test.js`

**Interfaces:**
- Produces:
  - `publicarPasta(pastaLocal, destinoRemoto, {token, repo, ramo = 'main', fetch, mensagem}) -> Promise<{commit: string, arquivos: number}>`: publica só `index.html` e o que está em `midias/` (ignora `conferencia/`), num commit só, pela sequência da seção "Respostas das APIs" (ref, commit, blobs, tree com `base_tree`, commit, PATCH da ref).
  - `removerPasta(destinoRemoto, {token, repo, ramo, fetch, mensagem}) -> Promise<{commit: string|null, removidos: number}>`: lista a árvore recursiva, cria uma tree com `sha: null` para cada arquivo sob `destinoRemoto/`; sem arquivos, não faz commit e devolve `commit: null`.
  - `urlDaPrevia(baseUrlPrevias, slug) -> string` (`https://isaque.github.io/previas` + `abc-1234` → `https://isaque.github.io/previas/abc-1234/`).

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('publicarPasta manda só index e mídias num commit', async () => {
  await escreverPrevia(tmp); // index.html, midias/a.webp, midias/b.webp, conferencia/pc.png
  const f = fetchGitHubFalso();
  const r = await publicarPasta(tmp, 'barbearia-x-1a2b', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'Prévia' });
  assert.equal(r.arquivos, 3); assert.equal(r.commit, 'commit-novo');
  const arvore = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').corpo);
  assert.equal(arvore.base_tree, 'arvore-base');
  assert.deepEqual(arvore.tree.map((t) => t.path).sort(), ['barbearia-x-1a2b/index.html', 'barbearia-x-1a2b/midias/a.webp', 'barbearia-x-1a2b/midias/b.webp']);
  assert.ok(f.chamadas.some((c) => c.metodo === 'PATCH' && c.url.endsWith('/git/refs/heads/main')));
  assert.equal(f.chamadas[0].cabecalhos.Authorization, 'Bearer T');
});
test('removerPasta apaga só os arquivos da prévia', async () => {
  const f = fetchGitHubFalso({ arvore: ['barbearia-x-1a2b/index.html', 'barbearia-x-1a2b/midias/a.webp', 'outra-9z9z/index.html'] });
  const r = await removerPasta('barbearia-x-1a2b', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'Remove' });
  const arvore = JSON.parse(f.chamadas.find((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').corpo);
  assert.equal(r.removidos, 2); assert.ok(arvore.tree.every((t) => t.sha === null && t.path.startsWith('barbearia-x-1a2b/')));
});
test('removerPasta sem arquivos não faz commit', async () => {
  const f = fetchGitHubFalso({ arvore: ['outra-9z9z/index.html'] });
  assert.deepEqual(await removerPasta('sumiu', { token: 'T', repo: 'isaque/previas', fetch: f, mensagem: 'x' }), { commit: null, removidos: 0 });
});
test('urlDaPrevia', () => assert.equal(urlDaPrevia('https://isaque.github.io/previas', 'abc-1234'), 'https://isaque.github.io/previas/abc-1234/'));
```

`fetchGitHubFalso` e `escreverPrevia` ficam em `test/falsos.js`.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/github.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/github.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): publicação das prévias no GitHub Pages"`

---

### Task 11: Mensagens, objeções e preço

**Files:**
- Create: `jarvis/src/vendas/mensagens.js`, `jarvis/src/vendas/precos.js`, `jarvis/src/ia/abordagem.js`
- Test: `jarvis/test/vendas.test.js`

**Interfaces:**
- Consumes: `linkWhatsApp` (plano 1), `gerarJson` (Tarefa 6), `limparTracos` (plano 1).
- Produces:
  - `ROTEIRO_OBJECOES: Record<'caro'|'tenho_instagram'|'vou_pensar'|'sem_tempo'|'sobrinho_faz'|'ja_tenho_site'|'ja_tenho_clientes', string>`: uma resposta base curta e respeitosa para cada objeção da spec.
  - `mensagensPadrao(registro, diagnostico, {url, nomeUsuario, estudio}) -> Abordagem` (sem IA): a primeira mensagem segue a estrutura "Oi, tudo bem? Sou {nomeUsuario}, do {estudio}. {achadoPrincipal} Fiz uma amostra de como poderia ficar o site de vocês: {url} Se quiser, te explico como funciona. {nomeUsuario}"; os acompanhamentos são curtos e lembram a amostra; as objeções são o roteiro base.
  - `escreverAbordagem(registro, diagnostico, {url, nomeUsuario, estudio, gemini}) -> Promise<Abordagem & {porIA: boolean, aviso?: string}>`: pede à IA as 3 mensagens e as 7 respostas adaptadas ao nicho. Cai em `mensagensPadrao` quando não há IA, há erro, a primeira passa de 400 caracteres, falta o `url` ou o `nomeUsuario`, ou aparece `!!` ou palavras de pressão (`urgente`, `última chance`, `só hoje`). Tudo passa por `limparTracos`.
  - `linkAbordagem(registro, texto) -> string|null` (usa `telefoneInternacional` ou `telefone`; `null` sem WhatsApp provável).
  - `TABELA_PRECOS = {basico: [900, 1800], profissional: [1800, 4000], premium: [5000, 10000], manutencao: [60, 200]}` e `MULTIPLICADOR_NICHO = {clinica: 1.3, odontologia: 1.3, estetica: 1.2, imobiliaria: 1.3}` (os outros nichos 1.0); `sugerirPreco(nicho, sobrescrever = {}) -> {basico: [min, max], profissional, premium, manutencao}` (valores multiplicados e arredondados para dezenas; `sobrescrever` vem de `config.precos` e substitui faixas inteiras).

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('mensagem padrão cabe em 400 caracteres e tem tudo que precisa', () => {
  const a = mensagensPadrao(registro, diagnostico, { url: 'https://isaque.github.io/previas/x-1a2b/', nomeUsuario: 'Isaque', estudio: 'Estúdio Dez' });
  assert.ok(a.primeira.length <= 400); assert.match(a.primeira, /previas\/x-1a2b/); assert.match(a.primeira, /Isaque/); assert.match(a.primeira, /Estúdio Dez/);
  assert.ok(a.primeira.includes(diagnostico.achadoPrincipal)); assert.ok(!/[—–]/.test(JSON.stringify(a)));
  assert.deepEqual(Object.keys(a.objecoes).sort(), Object.keys(ROTEIRO_OBJECOES).sort());
});
test('mensagem da IA com pressão ou longa demais cai na padrão', async () => {
  for (const primeira of ['x'.repeat(401), 'Última chance!! Responda hoje https://isaque.github.io/previas/x-1a2b/ Isaque']) {
    const r = await escreverAbordagem(registro, diagnostico, { url: 'https://isaque.github.io/previas/x-1a2b/', nomeUsuario: 'Isaque', estudio: 'Estúdio Dez', gemini: geminiQueDevolve({ ...abordagemIA, primeira }) });
    assert.equal(r.porIA, false);
  }
});
test('mensagem da IA boa é usada', async () => {
  const r = await escreverAbordagem(registro, diagnostico, { url: 'https://isaque.github.io/previas/x-1a2b/', nomeUsuario: 'Isaque', estudio: 'Estúdio Dez', gemini: geminiQueDevolve(abordagemIA) });
  assert.equal(r.porIA, true); assert.equal(r.primeira, abordagemIA.primeira);
});
test('linkAbordagem só com WhatsApp provável', () => {
  assert.match(linkAbordagem({ telefone: '(19) 99876-5432', whatsappProvavel: true }, 'Oi'), /^https:\/\/wa\.me\/5519998765432\?text=Oi$/);
  assert.equal(linkAbordagem({ telefone: '(19) 3232-1010', whatsappProvavel: false }, 'Oi'), null);
});
test('preço por nicho com multiplicador e sobrescrita', () => {
  assert.deepEqual(sugerirPreco('barbearia').basico, [900, 1800]);
  assert.deepEqual(sugerirPreco('clinica').profissional, [2340, 5200]);
  assert.deepEqual(sugerirPreco('barbearia', { basico: [700, 1200] }).basico, [700, 1200]);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/vendas.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/vendas.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): mensagens, objeções e preço"`

---

### Task 12: Funil, acompanhamento e manutenção

**Files:**
- Create: `jarvis/src/funil/funil.js`, `jarvis/src/prospeccao/manutencao.js`
- Test: `jarvis/test/funil.test.js`

**Interfaces:**
- Consumes: loja (Tarefa 1), `removerPasta` (Tarefa 10).
- Produces:
  - `ETAPAS = ['encontrado','preparado','abordado','respondeu','reuniao','proposta','fechou','perdido','descartado']`.
  - `mudarEtapa(registro, etapa, agora = new Date(), detalhe?) -> Registro` (novo objeto): grava `datas[etapa]` e uma `Interacao` `{tipo: 'etapa', data, detalhe: etapa}`. Lança `Error` "Este negócio pediu para não ser contatado." se `naoContatar` e a etapa é de contato (`abordado`, `respondeu`, `reuniao`, `proposta`); lança "Negócio já fechado." ao sair de `fechou`; etapa fora de `ETAPAS` lança.
  - `registrarAcompanhamento(registro, agora) -> Registro` (soma 1, grava `ultimoAcompanhamento`, interação `acompanhamento`; lança quando já há 2).
  - `marcarNaoContatar(registro, agora) -> Registro` (`naoContatar: true`, etapa `descartado`).
  - `cobrarHoje(registros, agora = new Date(), dias = [3, 7]) -> {cobrar: {registro, qual: 1|2}[], sugerirPerdido: Registro[]}`: só `etapa === 'abordado'` e sem `naoContatar`; `acompanhamentos === 0` e `>= dias[0]` dias desde `datas.abordado` → `qual: 1`; `=== 1` e `>= dias[1]` desde `ultimoAcompanhamento` → `qual: 2`; `=== 2` e `>= dias[1]` desde o último → `sugerirPerdido`. Dias contados por data no fuso `America/Sao_Paulo`.
  - `previasParaRemover(registros, agora = new Date()) -> Registro[]`: tem `previa.url` e (`naoContatar`, `etapa` em `perdido` ou `descartado`, ou `etapa` em `preparado`/`abordado` com `publicadaEm` há 45 dias ou mais).
  - `limparPreviasVencidas({loja, servicos, agora}) -> Promise<{removidas: string[], avisos: string[]}>`: remove cada uma no GitHub (sem `servicos.github`, avisa e não mexe), apaga `previa.url` e `publicadaEm` do registro e grava uma interação `previa_removida`.
  - `exportarDados({loja, destino}) -> Promise<string>` (um JSON com `negocios`, `buscas` e a data) e `copiaSemanal({loja, pasta, agora}) -> Promise<string|null>` (grava `copias/AAAA-SS.json` quando ainda não existe a cópia daquela semana; guarda as 8 mais recentes).

- [ ] **Step 1: Escrever os testes que falham:**

```js
const dia = (s) => new Date(`2026-11-${s}T12:00:00-03:00`);
test('cobrar no dia 3 e no dia 7, depois sugerir perdido', () => {
  let r = mudarEtapa(base, 'abordado', dia('10'));
  assert.equal(cobrarHoje([r], dia('12')).cobrar.length, 0);
  assert.deepEqual(cobrarHoje([r], dia('13')).cobrar.map((c) => c.qual), [1]);
  r = registrarAcompanhamento(r, dia('13'));
  assert.equal(cobrarHoje([r], dia('19')).cobrar.length, 0);
  assert.deepEqual(cobrarHoje([r], dia('20')).cobrar.map((c) => c.qual), [2]);
  r = registrarAcompanhamento(r, dia('20'));
  assert.equal(cobrarHoje([r], dia('27')).sugerirPerdido.length, 1);
  assert.throws(() => registrarAcompanhamento(r, dia('27')));
});
test('não contatar bloqueia contato e some da cobrança', () => {
  const r = marcarNaoContatar(mudarEtapa(base, 'abordado', dia('10')), dia('11'));
  assert.equal(r.etapa, 'descartado'); assert.throws(() => mudarEtapa(r, 'abordado', dia('12')), /não ser contatado/);
  assert.equal(cobrarHoje([r], dia('20')).cobrar.length, 0);
});
test('fechou é final', () => {
  assert.throws(() => mudarEtapa(mudarEtapa(base, 'fechou', dia('10')), 'perdido', dia('11')), /já fechado/);
});
test('prévias para remover', () => {
  const pub = (etapa, publicadaEm, extra = {}) => ({ ...base, etapa, ...extra, previa: { url: 'u', publicadaEm, slug: 's', versao: 1 } });
  const lista = [pub('abordado', '2026-10-01T12:00:00-03:00'), pub('abordado', '2026-11-01T12:00:00-03:00'), pub('perdido', '2026-11-20T12:00:00-03:00'), pub('respondeu', '2026-09-01T12:00:00-03:00'), pub('preparado', '2026-11-20T12:00:00-03:00', { naoContatar: true })];
  assert.equal(previasParaRemover(lista, dia('21')).length, 3);
});
test('limparPreviasVencidas chama o GitHub e limpa o registro', async () => {
  const { loja, servicos, f } = await ambienteFunil([{ ...base, etapa: 'perdido', previa: { url: 'u', slug: 'x-1a2b', publicadaEm: '2026-11-01T00:00:00Z', versao: 1 } }]);
  const r = await limparPreviasVencidas({ loja, servicos, agora: dia('21') });
  assert.deepEqual(r.removidas, ['x-1a2b']); assert.equal((await loja.ler('negocios'))[0].previa.url, undefined);
});
test('cópia semanal não repete na mesma semana e guarda 8', async () => {
  const { loja } = await ambienteFunil([base]);
  assert.ok(await copiaSemanal({ loja, pasta: tmp, agora: dia('21') }));
  assert.equal(await copiaSemanal({ loja, pasta: tmp, agora: dia('22') }), null);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/funil.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/funil.test.js`. Expected: PASS.
- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): funil, acompanhamento e manutenção"`

---

### Task 13: Preparar um negócio, de ponta a ponta

**Files:**
- Create: `jarvis/src/prospeccao/preparar.js`
- Test: `jarvis/test/preparar.test.js`

**Interfaces:**
- Consumes: tudo das Tarefas 1 a 12 e `gerarPrevia` do plano 1.
- Produces:
  - `sugerirInstagram(id, {loja, servicos}) -> Promise<{usuario, confianca}[]>` (sem `servicos.instagram`, devolve `[]`).
  - `registroParaNegocio(registro, midias: Midia[], clima: string[]) -> Negocio` (formato do plano 1: copia nome, nicho, bairro, cidade, endereco, telefone, mapsUrl, horarios, nota, totalAvaliacoes, avaliacoes, instagram sem `confirmado`, e usa `id` do registro).
  - `confirmarInstagram(id, usuario|null, {loja}) -> Promise<Registro>` (`null` grava `instagram: {usuario: '', confirmado: true}`, que significa "não tem").
  - `prepararNegocio(id, {loja, servicos, config, agora?, navegador?, bloquearRede?, aoProgredir?: (passo: string) => void}) -> Promise<{registro: Registro, url?: string, avisos: string[]}>`, na ordem da spec 5.3:
    1. Detalhes do Google (`garantirCota('places_detalhes')`), horários, avaliações, e download de até 10 fotos para `dados/midias/{id}/google/` (`garantirCota('places_foto', n)`); grava no registro.
    2. Instagram: só com `instagram.confirmado` e `usuario` preenchido; perfil e mídias em `dados/midias/{id}/instagram/`; perfil pessoal vira aviso "O Instagram deles é pessoal, vou usar as fotos do Google.".
    3. `escolherMaterial`, depois `completarComPexels` (sem chave do Pexels, segue sem completar e avisa).
    4. `diagnosticar`, `extrairClima`, `escreverTextosPrevia`.
    5. `sugerirAssinatura` com `usadas` montadas da loja (`previa.assinatura`, `nicho`, `cidade` de cada registro).
    6. `gerarPrevia` do plano 1 em `dados/previas/` com `textos`, `assinatura`, `estudio` da config; se havia prévia publicada antes, remove a pasta antiga no GitHub e a local, e soma 1 na `versao`.
    7. Conferência reprovada: não publica, grava `previa.problemas` e devolve sem `url`.
    8. Publica (`servicos.github` ausente: avisa "Configure o GitHub para publicar as prévias." e segue sem `url`; publicação que falha depois das tentativas do `requisitarJson`: avisa "Não consegui publicar a prévia agora. Ela ficou salva no computador." e segue sem `url`), grava `previa.url`, `publicadaEm`, `podeMostrar: false`.
    9. `escreverAbordagem`, `sugerirPreco`, `mudarEtapa(..., 'preparado')` (só se estava em `encontrado`), grava. Cada passo chama `aoProgredir` com uma frase curta.
  - Cada passo grava o registro ao terminar, para uma falha no meio não perder o que já foi feito.

- [ ] **Step 1: Escrever os testes que falham** (fetch falso com todas as fixtures, `gerarPrevia` real com `bloquearRede: true`):

```js
test('preparo completo publica a prévia e deixa a mensagem pronta', async () => {
  const amb = await ambientePreparo(); // loja com 1 registro sem site, fixtures de todos os serviços, Instagram confirmado
  const r = await prepararNegocio('sem-site-1', amb);
  assert.match(r.url, /^https:\/\/isaque\.github\.io\/previas\/[a-z0-9-]+\/$/);
  assert.equal(r.registro.etapa, 'preparado'); assert.equal(r.registro.previa.versao, 1); assert.equal(r.registro.previa.podeMostrar, false);
  assert.ok(r.registro.abordagem.primeira.includes(r.url)); assert.ok(r.registro.preco.basico);
  assert.ok(amb.f.chamadas.some((c) => c.metodo === 'PATCH' && c.url.includes('/git/refs/heads/main')));
});
test('sem Gemini, Pexels e GitHub, prepara com alternativas e avisa', async () => {
  const amb = await ambientePreparo({ sem: ['gemini', 'pexels', 'github'] });
  const r = await prepararNegocio('sem-site-1', amb);
  assert.equal(r.url, undefined); assert.ok(r.registro.previa.slug);
  assert.ok(r.avisos.some((a) => /GitHub/.test(a)));
  assert.ok(r.registro.abordagem.primeira.length > 0);
});
test('limite da IA no meio não perde o que já foi feito', async () => {
  const amb = await ambientePreparo({ geminiStatus: 429 });
  const r = await prepararNegocio('sem-site-1', amb);
  const salvo = (await amb.loja.ler('negocios'))[0];
  assert.ok(salvo.horarios.length > 0 && salvo.diagnostico && salvo.previa.slug);
  assert.ok(r.avisos.some((a) => /limite/i.test(a)));
});
test('preparar de novo remove a prévia antiga e sobe a versão', async () => {
  const amb = await ambientePreparo();
  const r1 = await prepararNegocio('sem-site-1', amb);
  const r2 = await prepararNegocio('sem-site-1', amb);
  assert.equal(r2.registro.previa.versao, 2); assert.notEqual(r1.registro.previa.slug, r2.registro.previa.slug);
  assert.equal((await amb.loja.ler('negocios')).length, 1);
  const tree = amb.f.chamadas.filter((c) => c.url.endsWith('/git/trees') && c.metodo === 'POST').map((c) => JSON.parse(c.corpo));
  assert.ok(tree.some((t) => t.tree.every((e) => e.sha === null) && t.tree[0].path.startsWith(r1.registro.previa.slug)));
});
test('publicação que falha deixa a prévia local e avisa', async () => {
  const amb = await ambientePreparo({ githubStatus: 500 });
  const r = await prepararNegocio('sem-site-1', amb);
  assert.equal(r.url, undefined); assert.ok(r.avisos.some((a) => a.includes('ficou salva no computador')));
  assert.ok(r.registro.previa.slug);
});
test('Instagram pessoal vira aviso e usa o Google', async () => {
  const amb = await ambientePreparo({ instagram: 'pessoal' });
  const r = await prepararNegocio('sem-site-1', amb);
  assert.ok(r.avisos.some((a) => a.includes('Instagram deles é pessoal')));
});
test('sugerirInstagram usa o site do Google e confirmarInstagram grava', async () => {
  const amb = await ambientePreparo({ registro: { site: 'https://instagram.com/semsite.oficial' } });
  const s = await sugerirInstagram('sem-site-1', amb);
  assert.equal(s[0].usuario, 'semsite.oficial');
  const reg = await confirmarInstagram('sem-site-1', 'semsite.oficial', amb);
  assert.deepEqual(reg.instagram, { usuario: 'semsite.oficial', confirmado: true });
});
```

`ambientePreparo(opcoes)` fica em `test/falsos.js` e monta loja, config (`nomeUsuario: 'Isaque'`, `githubRepo: 'isaque/previas'`), serviços com fetch falso (todas as fixtures e `fetchGitHubFalso`), navegador aberto uma vez e `bloquearRede: true`.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/preparar.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/preparar.test.js`. Expected: PASS.
- [ ] **Step 5: Rodar a suíte inteira.** Run: `npm test`. Expected: todos passam (os 170 do plano 1 e os novos).
- [ ] **Step 6: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): preparo de ponta a ponta"`

---

### Task 14: Linha de comando

**Files:**
- Create: `jarvis/src/cli.js`
- Modify: `jarvis/package.json` (script `"jarvis": "node src/cli.js"`)
- Test: `jarvis/test/cli.test.js`

**Interfaces:**
- Consumes: tudo acima.
- Produces: `executar(argv: string[], {config, loja, servicos, saida = console.log}) -> Promise<number>` (código de saída) e o arquivo executável `src/cli.js` que monta o ambiente real com `carregarConfig()`. Comandos (texto de saída em português simples):
  - `buscar <nicho> [cidade]` (sem cidade usa `cidadePadrao`; sem nenhuma, erro "Diga a cidade ou configure a cidade padrão.") → imprime o `resumo` e a lista numerada (nome, presença, nota, id).
  - `instagram <id>` → candidatos com a confiança em porcentagem; `instagram <id> <@usuario|nenhum>` → confirma.
  - `preparar <id>` → progresso passo a passo, depois o link da prévia, a primeira mensagem e o link do WhatsApp (ou "Sem WhatsApp provável. Ligue para {telefone}.").
  - `enviei <id>` → `abordado`; `cobrei <id>` → `registrarAcompanhamento`; `etapa <id> <etapa>`; `nao-contatar <id>`.
  - `hoje` → resumo do dia: quem cobrar (com a mensagem de acompanhamento pronta), quem sugerir como perdido, progresso da meta semanal (contagem de `abordado` nos últimos 7 dias contra `metaSemanal`).
  - `limpar` → `limparPreviasVencidas`; `exportar <arquivo>`.
  - Sem comando ou comando desconhecido → ajuda curta e código 1. Qualquer `ErroExterno`, `ErroCota` ou `Error` vira uma linha "Não deu certo: {mensagem}" e código 1, nunca um stack trace.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('buscar imprime o resumo e a lista', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['buscar', 'barbearias', 'Campinas'], amb), 0);
  assert.match(linhas[0], /^Encontrei 5 barbearias\./); assert.ok(linhas.some((l) => /^1\. /.test(l)));
});
test('sem cidade nem cidade padrão explica o que falta', async () => {
  const { amb, linhas } = await ambienteCli({ cidadePadrao: '' });
  assert.equal(await executar(['buscar', 'barbearias'], amb), 1); assert.match(linhas.join('\n'), /Diga a cidade/);
});
test('hoje lista quem cobrar com a mensagem pronta', async () => {
  const { amb, linhas } = await ambienteCli({ registros: [registroAbordadoHa(3)] });
  assert.equal(await executar(['hoje'], amb), 0); assert.match(linhas.join('\n'), /Cobrar hoje/);
});
test('erro vira uma linha em português, sem stack', async () => {
  const { amb, linhas } = await ambienteCli({ cotaEsgotada: true });
  assert.equal(await executar(['buscar', 'barbearias', 'Campinas'], amb), 1);
  assert.match(linhas.at(-1), /^Não deu certo: Limite mensal/); assert.ok(!linhas.join('\n').includes('    at '));
});
test('comando desconhecido mostra ajuda', async () => {
  const { amb, linhas } = await ambienteCli();
  assert.equal(await executar(['voar'], amb), 1); assert.match(linhas.join('\n'), /buscar <nicho>/);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/cli.test.js`. Expected: FAIL.
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/cli.test.js`. Expected: PASS.
- [ ] **Step 5: Rodar a suíte inteira.** Run: `npm test`. Expected: todos passam.
- [ ] **Step 6: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): linha de comando do motor"`

---

## Entrega deste plano

Ao final: `npm test` passa, e com o `.env` preenchido o usuário consegue, no PC dele, rodar `npm run jarvis -- buscar barbearias Campinas`, `npm run jarvis -- preparar <id>` e `npm run jarvis -- hoje`. Neste ambiente de construção as APIs reais não são chamadas (rede bloqueada e sem chaves); a primeira chamada real acontece na configuração do plano 3, guiada passo a passo.

## Referências da pesquisa

- Preços: faixas gerais de R$ 400 a R$ 10.000 para sites no Brasil e manutenção de R$ 50 a R$ 500 por mês (InfinitePay, Nuvemshop, Hostinger, Wix, 2026). A tabela inicial é editável nas configurações.
- Gemini: busca no Google pelo Gemini fora do plano grátis (página de preços, out/2026); nomes dos modelos grátis mudam com frequência, por isso o modelo é configurável e usa os apelidos `-latest`.
- Places API (New): a cobrança segue o campo mais caro da máscara; site, telefone e nota ficam no nível Enterprise, e avaliações no Enterprise + Atmosphere (1.000 grátis por mês cada).
