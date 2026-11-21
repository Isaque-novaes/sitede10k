# Jarvis, plano 1 de 3: kit de prévias únicas

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar, a partir dos dados e do material de um negócio, uma prévia de site única, profissional, animada e conferida no celular e no PC, pronta para ser publicada.

**Architecture:** Um módulo Node.js (`jarvis/src/previa/`) trata as mídias (sharp e ffmpeg), extrai e deriva a paleta, escolhe uma assinatura de design única a partir de um catálogo do kit (`jarvis/kit/`), monta um HTML estático com CSS e JS embutidos, e confere o resultado num navegador invisível (playwright-core). Este plano entrega a escolha de assinatura **por regras** e os **textos base por nicho**. A direção de arte e os textos com IA (Gemini) entram no plano 2, usando as mesmas interfaces.

**Tech Stack:** Node.js 22 (ESM), `node:test`, `sharp` 0.35.x, `playwright-core` 1.63.0, ffmpeg (externo), HTML/CSS/JS puros nas prévias.

**Spec:** `docs/superpowers/specs/2026-11-21-jarvis-prospeccao-design.md` (seções 2, 5.2 "Prévia", 5.3 "Preparar um negócio" passos 5 a 10, "Regra de exclusividade", "O kit de design", 5.5 "Qualidade das prévias" e "Prévias discretas").

**Planos seguintes:** plano 2 (motor de prospecção: Google, Gemini, Instagram, Pexels, GitHub, funil, mensagens) e plano 3 (interface do Jarvis, voz, vitrine, configuração, atalho do Windows). Eles consomem `gerarPrevia` e os tipos deste plano.

## Global Constraints

- Tudo dentro de `jarvis/`. Node `>=22`, `"type": "module"`, sem etapa de build. Comandos rodam a partir de `jarvis/`.
- Dependências de execução permitidas neste plano: `sharp@^0.35.5` e `playwright-core@1.63.0`, nada mais. Testes com `node --test`, sem biblioteca de teste.
- Caminhos sempre com `node:path` (o app roda no Windows e os testes rodam no Linux).
- Todo texto visível na prévia em português do Brasil, **sem travessão (—) nem meia-risca (–)**.
- Toda prévia tem `<meta name="robots" content="noindex, nofollow">`, a faixa visível "Demonstração criada pelo Estúdio Dez. Este não é o site oficial de {nome}." (o nome do estúdio vem de `opcoes.estudio`, padrão `"Estúdio Dez"`) e os créditos de origem das mídias no rodapé.
- Nunca Inter nem Roboto como fonte de título.
- Animações respeitam `prefers-reduced-motion: reduce` (conteúdo visível na hora, sem transformações).
- Tamanhos de conferência: celular 390 x 844 e PC 1440 x 900.
- Kit mínimo: 8 topos, 8 tipos de seção com 3 variantes cada (`a`, `b`, `c`), 6 estilos de movimento, 10 pares de fontes.
- Exclusividade: nenhuma assinatura repete as 5 partes de outra. No mesmo nicho e na mesma cidade, a nova difere em pelo menos 3 das 5 partes de cada anterior. Paletas são "iguais" quando `fundo`, `texto` e `destaque` estão, cada um, a uma distância RGB euclidiana de no máximo 40.
- Vídeo de topo: até 720 px de altura, sem áudio, H.264 `+faststart`, taxa máxima de 1.500 kbit/s, no máximo 12 segundos, com imagem de capa JPG.
- Fotos: versões WebP com 800 px (celular) e 1600 px (PC) de largura, nunca ampliadas além da original.
- Slug: `{nome-normalizado}-{4 caracteres [a-z0-9]}`, com no máximo 40 caracteres na parte do nome.
- Nenhum teste chama a internet. Fixtures de imagem e vídeo são geradas nos próprios testes (sharp e ffmpeg `lavfi`).

## Review Focus

- **Nomes com acento, apóstrofo, "&" e emoji** (por exemplo "D'Ávila Barber & Co 💈"): o slug sai limpo e o HTML sai escapado, sem quebrar a página. Testes nas Tarefas 1 e 5.
- **Textos longos** (nome com 60 caracteres, avaliação com 1.000 caracteres): nada vaza para os lados em 390 px. Teste na Tarefa 10.
- **Pouca mídia** (1 foto, ou nenhuma): topos e seções que pedem mais fotos não são escolhidos, e a prévia ainda sai e passa na conferência. Testes nas Tarefas 4 e 10.
- **Fotos estranhas** (vertical 9:16 do Instagram, minúscula de 320 px, quase toda preta): não são ampliadas, e foto pequena não vira topo de tela cheia. A paleta de foto escura ainda tem contraste. Testes nas Tarefas 2, 3 e 4.
- **Dados opcionais ausentes** (sem horário, sem avaliações, sem WhatsApp, sem telefone): seções que dependem deles somem, e a chamada cai para telefone e depois para o link do Maps. Testes nas Tarefas 4 e 5.

---

## Estrutura de arquivos

```
jarvis/
  package.json
  .gitignore                      (node_modules, saida/, fixtures/midias/, .env, dados/)
  src/
    previa/
      tipos.js                    typedefs JSDoc compartilhados (sem código)
      cores.js                    contraste, distância, extração e derivação de paleta
      midia.js                    tratamento de fotos e vídeo
      assinatura.js               partes, comparação, exclusividade, escolha por regras
      textos-base.js              textos de prévia por nicho, sem IA
      montar.js                   monta o HTML e a lista de arquivos, grava a pasta
      conferir.js                 conferência no navegador invisível
      gerar.js                    pipeline completo de uma prévia
    util/
      slug.js                     criarSlug, normalizar
      html.js                     esc (escape de HTML)
      whatsapp.js                 normalizarTelefoneBR, provavelCelular, linkWhatsApp
      navegador.js                abrirNavegador (Edge, Chrome ou Chromium)
      aleatorio.js                criarAleatorio(semente)
  kit/
    catalogo.js                   ids, requisitos e etiquetas de topos, seções, movimentos e fontes
    base.css                      reset, variáveis, tipografia fluida, faixa de demonstração, rodapé
    movimento.css                 estilos dos 6 movimentos
    movimento.js                  runtime de animação (embutido na prévia)
    topos/<id>.js                 8 arquivos
    secoes/<tipo>-<variante>.js   24 arquivos
  scripts/
    baixar-midias-demo.mjs
    demo-previas.mjs
  fixtures/
    negocios-demo.json
  test/
    *.test.js
```

## Tipos compartilhados (`src/previa/tipos.js`)

Criados na Tarefa 1. Todas as tarefas usam estes nomes exatos.

```js
/** @typedef {{arquivo:string, tipo:'foto'|'video', origem:'instagram'|'google'|'pexels', credito:string}} Midia */
/** @typedef {{autor:string, nota:number, texto:string}} Avaliacao */
/** @typedef {{id:string, nome:string, nicho:string, bairro?:string, cidade:string, endereco?:string,
 *   telefone?:string, whatsapp?:string, mapsUrl?:string, horarios?:string[], nota?:number,
 *   totalAvaliacoes?:number, avaliacoes:Avaliacao[], instagram?:{usuario:string, bio?:string, seguidores?:number},
 *   midias:Midia[], clima:string[]}} Negocio */
/** @typedef {{titulo:string, subtitulo:string, servicos:{nome:string, descricao:string}[], sobre:string,
 *   perguntas:{pergunta:string, resposta:string}[], chamada:string}} TextosPrevia */
/** @typedef {{fundo:string, superficie:string, texto:string, textoSuave:string, destaque:string, destaque2:string}} Paleta */
/** @typedef {{tipo:string, variante:'a'|'b'|'c'}} SecaoEscolhida */
/** @typedef {{topo:string, fontes:string, movimento:string, secoes:SecaoEscolhida[], paleta:Paleta}} Assinatura */
/** @typedef {{original:Midia, tipo:'foto', celular:string, pc:string, largura:number, altura:number, cores:string[]}} FotoTratada */
/** @typedef {{original:Midia, tipo:'video', video:string, capa:string, largura:number, altura:number, duracao:number}} VideoTratado */
/** @typedef {{assinatura:Assinatura, nicho:string, cidade:string}} AssinaturaUsada */
/** @typedef {{ok:boolean, problemas:string[], capturas:{celular:string, pc:string}}} ResultadoConferencia */
/** @typedef {{slug:string, pasta:string, assinatura:Assinatura, conferencia:ResultadoConferencia}} PreviaGerada */
export {};
```

Todos os caminhos em `FotoTratada` e `VideoTratado` são absolutos no disco. Dentro da prévia, as mídias ficam em `midias/` relativo ao `index.html`.

---

### Task 1: Projeto, tipos e utilidades

**Files:**
- Create: `jarvis/package.json`, `jarvis/.gitignore`, `jarvis/src/previa/tipos.js`, `jarvis/src/util/slug.js`, `jarvis/src/util/html.js`, `jarvis/src/util/whatsapp.js`, `jarvis/src/util/aleatorio.js`
- Test: `jarvis/test/util.test.js`

**Interfaces:**
- Produces:
  - `normalizar(texto: string) -> string` (minúsculas, sem acento, só `[a-z0-9]` e hífens, sem hífens repetidos ou nas pontas)
  - `criarSlug(nome: string, aleatorio?: () => number) -> string`
  - `esc(texto: unknown) -> string` (escapa `& < > " '`, e `null`/`undefined` viram `""`)
  - `normalizarTelefoneBR(telefone: string) -> string | null` (só dígitos, com 55 na frente, `null` se não tiver 12 ou 13 dígitos depois de normalizar)
  - `provavelCelular(telefone: string) -> boolean` (13 dígitos com o 9 logo depois do DDD)
  - `linkWhatsApp(telefone: string, texto: string) -> string | null`
  - `criarAleatorio(semente: number) -> () => number` (gerador determinístico em [0,1), mulberry32)

- [ ] **Step 1: Criar `package.json`** com `"name": "jarvis"`, `"private": true`, `"type": "module"`, `"engines": {"node": ">=22"}`, scripts `"test": "node --test"`, `"demo": "node scripts/demo-previas.mjs"`, `"demo:midias": "node scripts/baixar-midias-demo.mjs"`, dependências `sharp@^0.35.5` e `playwright-core@1.63.0`. Rodar `npm install` em `jarvis/`. Criar o `.gitignore` e o `tipos.js` exatamente como na seção acima.

- [ ] **Step 2: Escrever os testes que falham** em `test/util.test.js`:

```js
test('criarSlug limpa acentos, apóstrofo, & e emoji', () => {
  const s = criarSlug("D'Ávila Barber & Co 💈", criarAleatorio(1));
  assert.match(s, /^davila-barber-co-[a-z0-9]{4}$/);
});
test('criarSlug corta o nome em 40 caracteres', () => {
  const s = criarSlug('a'.repeat(80), criarAleatorio(2));
  assert.equal(s.split('-')[0].length, 40);
});
test('criarSlug muda o sufixo entre chamadas sem semente', () => {
  assert.notEqual(criarSlug('Barbearia X'), criarSlug('Barbearia X'));
});
test('esc escapa HTML', () => {
  assert.equal(esc(`<a href="x">'&'</a>`), '&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;');
  assert.equal(esc(undefined), '');
});
test('telefone brasileiro', () => {
  assert.equal(normalizarTelefoneBR('(19) 99876-5432'), '5519998765432');
  assert.equal(normalizarTelefoneBR('+55 19 3234-5678'), '551932345678');
  assert.equal(normalizarTelefoneBR('123'), null);
  assert.equal(provavelCelular('(19) 99876-5432'), true);
  assert.equal(provavelCelular('(19) 3234-5678'), false);
});
test('linkWhatsApp codifica o texto', () => {
  assert.equal(linkWhatsApp('(19) 99876-5432', 'Olá, tudo bem?'),
    'https://wa.me/5519998765432?text=Ol%C3%A1%2C%20tudo%20bem%3F');
  assert.equal(linkWhatsApp('', 'x'), null);
});
test('criarAleatorio é determinístico', () => {
  const a = criarAleatorio(42), b = criarAleatorio(42);
  assert.deepEqual([a(), a(), a()], [b(), b(), b()]);
});
```

- [ ] **Step 3: Rodar e ver falhar.** Run: `node --test test/util.test.js`. Expected: FAIL (módulos não existem).

- [ ] **Step 4: Implementar** as funções da lista de Interfaces nos arquivos de `src/util/`. O sufixo do slug usa `aleatorio` (padrão `Math.random`) para sortear 4 caracteres de `abcdefghijklmnopqrstuvwxyz0123456789`.

- [ ] **Step 5: Rodar e ver passar.** Run: `node --test test/util.test.js`. Expected: PASS, 7 testes.

- [ ] **Step 6: Commit.** `git add jarvis && git commit -m "feat(jarvis): projeto, tipos e utilidades"` (sem `node_modules`).

---

### Task 2: Cores e paleta

**Files:**
- Create: `jarvis/src/previa/cores.js`
- Test: `jarvis/test/cores.test.js`

**Interfaces:**
- Produces:
  - `hexParaRgb(hex: string) -> [number, number, number]` e `rgbParaHex([r,g,b]) -> string` (minúsculas, `#rrggbb`)
  - `distanciaRgb(a: string, b: string) -> number` (euclidiana)
  - `contraste(a: string, b: string) -> number` (razão de contraste WCAG 2, de 1 a 21)
  - `extrairCores(imagem: Buffer | string, quantidade = 5) -> Promise<string[]>` (hex, da cor mais presente para a menos)
  - `derivarPaleta(cores: string[], clima: string[]) -> Paleta`

**Regras de `derivarPaleta`** (o teste fixa o resultado, a implementação escolhe o caminho):
- `destaque` é a cor mais saturada da lista (saturação HSL), ajustada para ter contraste de pelo menos 3 com `fundo`.
- `fundo` é escuro (luminância relativa até 0,05) quando o clima tem alguma de `["noturno","moderno","sofisticado","forte","urbano"]` ou quando a cor mais presente é escura. Senão é claro (luminância de pelo menos 0,85). O fundo herda o tom da cor mais presente, com saturação baixa (nunca preto ou branco puro).
- `texto` tem contraste de pelo menos 7 com `fundo`. `textoSuave` tem pelo menos 4,5. `superficie` fica a uma distância de 8 a 40 de `fundo`. `destaque2` é a segunda cor mais saturada, ajustada como o `destaque`.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('contraste WCAG conhecido', () => {
  assert.equal(Math.round(contraste('#000000', '#ffffff')), 21);
  assert.equal(contraste('#777777', '#777777'), 1);
});
test('extrairCores acha a cor dominante', async () => {
  const img = await sharp({ create: { width: 100, height: 100, channels: 3, background: '#c0392b' } }).png().toBuffer();
  const [principal] = await extrairCores(img, 3);
  assert.ok(distanciaRgb(principal, '#c0392b') < 20);
});
for (const caso of [
  { nome: 'foto quase preta', cores: ['#050505', '#0a0a0a', '#111111'], clima: [] },
  { nome: 'foto quase branca', cores: ['#fafafa', '#f0f0f0', '#e8e8e8'], clima: [] },
  { nome: 'foto colorida', cores: ['#2e4057', '#d1495b', '#edae49', '#00798c', '#66a182'], clima: ['moderno'] },
]) {
  test(`derivarPaleta tem contraste: ${caso.nome}`, () => {
    const p = derivarPaleta(caso.cores, caso.clima);
    assert.ok(contraste(p.texto, p.fundo) >= 7);
    assert.ok(contraste(p.textoSuave, p.fundo) >= 4.5);
    assert.ok(contraste(p.destaque, p.fundo) >= 3);
    assert.ok(!['#000000', '#ffffff'].includes(p.fundo));
    const d = distanciaRgb(p.superficie, p.fundo); assert.ok(d >= 8 && d <= 40);
  });
}
test('clima moderno gera fundo escuro', () => {
  const p = derivarPaleta(['#f5e6c8', '#c97b2a'], ['moderno']);
  assert.ok(contraste(p.fundo, '#000000') < 2);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/cores.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `cores.js`.** `extrairCores` reduz a imagem com sharp para 64 x 64, lê os pixels brutos e roda k-means (k = `quantidade`, 10 iterações, centros iniciais escolhidos de forma determinística), ordenando pelos tamanhos dos grupos. Ajustes de contraste mexem só na luminosidade HSL, em passos de 2%, até atingir o mínimo.

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/cores.test.js`. Expected: PASS.

- [ ] **Step 5: Commit.** `git commit -am "feat(jarvis): cores e paleta das prévias"` (adicionar os arquivos novos antes).

---

### Task 3: Tratamento de mídia

**Files:**
- Create: `jarvis/src/previa/midia.js`
- Test: `jarvis/test/midia.test.js`

**Interfaces:**
- Consumes: `extrairCores` (Tarefa 2), tipos `Midia`, `FotoTratada`, `VideoTratado`.
- Produces:
  - `temFfmpeg() -> Promise<boolean>`
  - `tratarFoto(midia: Midia, pastaDestino: string, nomeBase: string) -> Promise<FotoTratada>` (grava `{nomeBase}-800.webp` e `{nomeBase}-1600.webp`, qualidade 78. A versão grande nunca passa da largura original, e a pequena também não. `cores` tem 5 cores. `largura` e `altura` são as da original, já com a rotação EXIF aplicada)
  - `tratarVideo(midia: Midia, pastaDestino: string, nomeBase: string) -> Promise<VideoTratado>` (grava `{nomeBase}.mp4` e `{nomeBase}-capa.jpg` com os parâmetros das Global Constraints. A capa é o quadro de 1 s, ou o primeiro se o vídeo for mais curto)
  - `tratarMidias(midias: Midia[], pastaDestino: string) -> Promise<{fotos: FotoTratada[], video: VideoTratado | null, avisos: string[]}>` (no máximo 4 em paralelo. Fotos com erro viram um aviso e são puladas. Usa só o primeiro vídeo. Sem ffmpeg, ignora vídeos e avisa "ffmpeg não encontrado, vídeo ignorado")

- [ ] **Step 1: Escrever os testes que falham** (fixtures geradas numa pasta temporária com `fs.mkdtemp`):

```js
test('tratarFoto gera duas larguras sem ampliar', async () => {
  const orig = join(tmp, 'grande.jpg'); await sharp({ create: { width: 2400, height: 1600, channels: 3, background: '#336699' } }).jpeg().toFile(orig);
  const f = await tratarFoto({ arquivo: orig, tipo: 'foto', origem: 'google', credito: 'Google Maps' }, tmp, 'f1');
  assert.equal((await sharp(f.celular).metadata()).width, 800);
  assert.equal((await sharp(f.pc).metadata()).width, 1600);
  assert.equal(f.cores.length, 5);
});
test('tratarFoto não amplia foto pequena', async () => {
  const orig = join(tmp, 'pequena.jpg'); await sharp({ create: { width: 320, height: 568, channels: 3, background: '#aa3300' } }).jpeg().toFile(orig);
  const f = await tratarFoto({ arquivo: orig, tipo: 'foto', origem: 'instagram', credito: '@x' }, tmp, 'f2');
  assert.equal((await sharp(f.pc).metadata()).width, 320);
  assert.equal(f.largura, 320); assert.equal(f.altura, 568);
});
test('tratarVideo comprime para 720p sem áudio e gera capa', { skip: !(await temFfmpeg()) }, async () => {
  const orig = join(tmp, 'v.mp4');
  execFileSync('ffmpeg', ['-y', '-f', 'lavfi', '-i', 'testsrc=size=1080x1920:rate=30:duration=15', '-f', 'lavfi', '-i', 'sine=duration=15', '-shortest', orig]);
  const v = await tratarVideo({ arquivo: orig, tipo: 'video', origem: 'instagram', credito: '@x' }, tmp, 'v1');
  const info = JSON.parse(execFileSync('ffprobe', ['-v', 'error', '-show_streams', '-show_format', '-of', 'json', v.video]));
  assert.equal(info.streams.filter(s => s.codec_type === 'audio').length, 0);
  assert.ok(info.streams[0].height <= 720);
  assert.ok(Number(info.format.duration) <= 12.1);
  assert.ok(existsSync(v.capa));
});
test('tratarMidias pula arquivo corrompido com aviso', async () => {
  const ruim = join(tmp, 'ruim.jpg'); await writeFile(ruim, 'não é imagem');
  const r = await tratarMidias([{ arquivo: ruim, tipo: 'foto', origem: 'google', credito: 'x' }], join(tmp, 'saida'));
  assert.equal(r.fotos.length, 0); assert.equal(r.avisos.length, 1);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/midia.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `midia.js`.** O vídeo usa `ffmpeg -y -i in -t 12 -an -vf "scale=-2:'min(720,ih)'" -c:v libx264 -preset veryfast -crf 26 -maxrate 1500k -bufsize 3000k -pix_fmt yuv420p -movflags +faststart out.mp4`, e a duração e o tamanho vêm do `ffprobe`. `temFfmpeg` roda `ffmpeg -version` e devolve `false` se der erro.

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/midia.test.js`. Expected: PASS (o teste de vídeo roda, porque o ffmpeg existe neste ambiente).

- [ ] **Step 5: Commit.** `git add -A jarvis/src jarvis/test && git commit -m "feat(jarvis): tratamento de fotos e vídeo"`

---

### Task 4: Catálogo do kit e assinatura única

**Files:**
- Create: `jarvis/kit/catalogo.js`, `jarvis/src/previa/assinatura.js`
- Test: `jarvis/test/assinatura.test.js`

**Interfaces:**
- Consumes: `distanciaRgb` (Tarefa 2), `criarAleatorio` (Tarefa 1).
- Produces:
  - `TOPOS: {id:string, requisitos:{fotos:number, video:boolean, larguraMin:number}, etiquetas:string[]}[]`
  - `SECOES: {tipo:string, requisitos:(ctx) => boolean, fixa?:'inicio'|'fim'}[]` e `VARIANTES = ['a','b','c']`
  - `MOVIMENTOS: {id:string, etiquetas:string[]}[]`
  - `FONTES: {id:string, titulo:string, texto:string, pesosTitulo:string, pesosTexto:string, etiquetas:string[]}[]`
  - `partesAssinatura(a: Assinatura) -> {topo, fontes, movimento, secoes: string, paleta: Paleta}` (`secoes` vira `"servicos:a|sobre:c|..."`)
  - `paletasIguais(p1: Paleta, p2: Paleta) -> boolean`
  - `contarDiferencas(a: Assinatura, b: Assinatura) -> number` (0 a 5)
  - `ehUnica(candidata: Assinatura, usadas: AssinaturaUsada[], alvo: {nicho:string, cidade:string}) -> boolean`
  - `opcoesPossiveis(contexto: {fotos: FotoTratada[], video: VideoTratado|null, negocio: Negocio, textos: TextosPrevia}) -> {topos:string[], secoes:string[]}`
  - `escolherAssinaturaPorRegras(contexto, paletaBase: Paleta, coresExtras: string[], usadas: AssinaturaUsada[], aleatorio: () => number) -> Assinatura` (lança `Error` com `code = 'SEM_COMBINACAO_UNICA'` depois de 300 tentativas)

**Conteúdo fixo do catálogo:**

| Topos (`id`: fotos, vídeo, larguraMin) |
|---|
| `foto-cheia`: 1, não, 1200 · `video-fundo`: 0, sim, 0 · `colagem`: 3, não, 600 · `tela-dividida`: 1, não, 800 · `titulo-gigante`: 0, não, 0 (usa uma foto recortada quando houver, e só tipografia sobre a paleta quando não houver) · `carrossel`: 3, não, 1000 · `moldura`: 1, não, 700 · `mosaico-movel`: 5, não, 500 |

| Seções (`tipo`: requisito) |
|---|
| `servicos`: `textos.servicos.length >= 3` · `sobre`: `textos.sobre` não vazio · `galeria`: pelo menos 4 fotos · `avaliacoes`: pelo menos 2 avaliações com texto · `numeros`: `nota` ou `totalAvaliacoes` presentes · `localizacao`: `endereco` ou `horarios` presentes · `perguntas`: pelo menos 2 perguntas · `chamada-final`: sempre (fixa `fim`) |

Movimentos: `suave` (acolhedor, familiar), `elegante` (sofisticado, premium), `energico` (jovem, esportivo, urbano), `paralaxe` (moderno, natureza), `cinema` (premium, gastronomia, noturno), `minimo` (clínico, profissional, discreto).

Fontes (Google Fonts):

| id | título | texto | etiquetas |
|---|---|---|---|
| `playfair-dmsans` | Playfair Display | DM Sans | elegante, classico |
| `bebas-manrope` | Bebas Neue | Manrope | forte, urbano |
| `fraunces-worksans` | Fraunces | Work Sans | acolhedor, artesanal |
| `syne-karla` | Syne | Karla | moderno, criativo |
| `cormorant-montserrat` | Cormorant Garamond | Montserrat | sofisticado, premium |
| `archivoblack-archivo` | Archivo Black | Archivo | forte, esportivo |
| `dmserif-outfit` | DM Serif Display | Outfit | classico, acolhedor |
| `anton-nunitosans` | Anton | Nunito Sans | energico, jovem |
| `spacegrotesk-ibmplexsans` | Space Grotesk | IBM Plex Sans | profissional, clinico |
| `abrilfatface-lato` | Abril Fatface | Lato | divertido, gastronomia |

**Regras da escolha:** filtra os topos e as seções pelos requisitos. A ordem das seções começa com `servicos` ou `sobre` (se nenhuma das duas for possível, pela primeira possível), termina com `chamada-final` e inclui todas as seções possíveis, numa ordem sorteada entre elas. Variantes sorteadas. Movimento e fontes sorteados com peso 3 para quem tem etiqueta em comum com `negocio.clima` e peso 1 para os outros. A paleta começa em `paletaBase`. Quando a candidata só falha por paleta igual, a tentativa seguinte troca `destaque` por uma das `coresExtras` (reajustando o contraste com as regras da Tarefa 2), e depois alterna fundo claro e escuro.

- [ ] **Step 1: Escrever os testes que falham:**

```js
const P = { fundo: '#101418', superficie: '#1c232a', texto: '#f2f4f5', textoSuave: '#b8c0c7', destaque: '#e0a030', destaque2: '#3fa7a0' };
const A = { topo: 'foto-cheia', fontes: 'playfair-dmsans', movimento: 'suave', secoes: [{ tipo: 'servicos', variante: 'a' }, { tipo: 'chamada-final', variante: 'a' }], paleta: P };
test('catálogo tem o tamanho mínimo', () => {
  assert.equal(TOPOS.length, 8); assert.equal(SECOES.length, 8); assert.equal(MOVIMENTOS.length, 6); assert.equal(FONTES.length, 10);
  assert.ok(FONTES.every(f => !/^(Inter|Roboto)$/.test(f.titulo)));
});
test('paletas próximas contam como iguais', () => {
  assert.equal(paletasIguais(P, { ...P, fundo: '#141a1e' }), true);
  assert.equal(paletasIguais(P, { ...P, destaque: '#2060e0' }), false);
});
test('assinatura idêntica nunca é única', () => {
  assert.equal(ehUnica(A, [{ assinatura: A, nicho: 'pizzaria', cidade: 'Recife' }], { nicho: 'barbearia', cidade: 'Campinas' }), false);
});
test('mesmo nicho e cidade exige 3 diferenças', () => {
  const duas = { ...A, topo: 'colagem', fontes: 'syne-karla' };
  const tres = { ...duas, movimento: 'elegante' };
  const usadas = [{ assinatura: A, nicho: 'barbearia', cidade: 'Campinas' }];
  assert.equal(contarDiferencas(A, duas), 2);
  assert.equal(ehUnica(duas, usadas, { nicho: 'barbearia', cidade: 'Campinas' }), false);
  assert.equal(ehUnica(tres, usadas, { nicho: 'barbearia', cidade: 'Campinas' }), true);
  assert.equal(ehUnica(duas, usadas, { nicho: 'barbearia', cidade: 'Sorocaba' }), true);
});
test('uma foto pequena só libera topos possíveis', () => {
  const fotos = [{ largura: 640, altura: 1136 }];
  const { topos, secoes } = opcoesPossiveis({ fotos, video: null, negocio: negocioMinimo, textos: textosMinimos });
  assert.ok(!topos.includes('foto-cheia') && !topos.includes('colagem') && !topos.includes('video-fundo'));
  assert.ok(topos.includes('titulo-gigante'));
  assert.ok(!secoes.includes('galeria') && !secoes.includes('avaliacoes') && !secoes.includes('localizacao'));
});
test('dez assinaturas seguidas no mesmo nicho e cidade são todas únicas', () => {
  const usadas = []; const rnd = criarAleatorio(7);
  for (let i = 0; i < 10; i++) {
    const a = escolherAssinaturaPorRegras(contextoCompleto, P, ['#c0392b', '#2e86de', '#27ae60'], usadas, rnd);
    assert.ok(ehUnica(a, usadas, { nicho: 'barbearia', cidade: 'Campinas' }));
    assert.equal(a.secoes.at(-1).tipo, 'chamada-final');
    assert.ok(['servicos', 'sobre'].includes(a.secoes[0].tipo));
    usadas.push({ assinatura: a, nicho: 'barbearia', cidade: 'Campinas' });
  }
});
```

`negocioMinimo` não tem avaliações, endereço, horários, nota nem telefone. `textosMinimos` tem 3 serviços, `sobre` e nenhuma pergunta. `contextoCompleto` tem 8 fotos de 2000 x 1333, um vídeo, 5 avaliações, endereço, horários, nota e 4 perguntas. Os três ficam definidos no topo do arquivo de teste.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/assinatura.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `catalogo.js` e `assinatura.js`** com o conteúdo e as regras acima. Uma foto atende `larguraMin` pela largura original.

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/assinatura.test.js`. Expected: PASS.

- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): catálogo do kit e regra de exclusividade"`

---

### Task 5: Montador, base, movimentos, fontes e as primeiras peças

**Files:**
- Create: `jarvis/src/previa/montar.js`, `jarvis/kit/base.css`, `jarvis/kit/movimento.css`, `jarvis/kit/movimento.js`, `jarvis/kit/topos/foto-cheia.js`, e a variante `a` das 8 seções: `jarvis/kit/secoes/{servicos,sobre,galeria,avaliacoes,numeros,localizacao,perguntas,chamada-final}-a.js`
- Test: `jarvis/test/montar.test.js`

**Interfaces:**
- Consumes: `esc`, `linkWhatsApp` (Tarefa 1), catálogo (Tarefa 4), tipos.
- Produces:
  - **Contrato de peça do kit** (todo arquivo em `kit/topos/` e `kit/secoes/`): `export function render(ctx) -> {html: string, css: string}`, com `ctx = {negocio, textos, fotos: FotoTratada[], video: VideoTratado|null, paleta, fontes, movimento, util}`. Em `util`: `esc`, `img(foto: FotoTratada, {classe?: string, prioridade?: boolean, alt: string}) -> string` (um `<img>` com `srcset` 800w/1600w, `sizes`, `width`, `height`, `loading="lazy"`, ou `fetchpriority="high"` sem lazy quando `prioridade`), `linkContato() -> {href: string, rotulo: string}` (WhatsApp do negócio, senão `tel:` do telefone, senão `mapsUrl`, senão `null`). O CSS de cada peça usa só classes com o prefixo da própria peça (por exemplo `.t-foto-cheia__titulo`) e as variáveis `--cor-fundo`, `--cor-superficie`, `--cor-texto`, `--cor-texto-suave`, `--cor-destaque`, `--cor-destaque2`, `--fonte-titulo`, `--fonte-texto`.
  - **Contrato de animação:** elementos marcados com `data-anim` em `revelar | subir | zoom-lento | texto-partes | contador | faixa | paralaxe`. O `<body>` recebe `data-movimento="{id}"`. `movimento.js` (sem dependências, até 6 KB) usa `IntersectionObserver` e `requestAnimationFrame`. Com `prefers-reduced-motion: reduce`, mostra tudo de uma vez e não aplica transformações. Cada um dos 6 movimentos muda duração, curva e quais efeitos ficam ativos, em `movimento.css`.
  - O título principal do topo leva `data-titulo-principal` (a conferência procura esse atributo).
  - `montarPrevia({negocio, textos, assinatura, fotos, video, opcoes: {estudio?: string}}) -> {html: string, arquivos: {destino: string, origem: string}[]}`. Os `destino` ficam em `midias/...`, e os `src` do HTML apontam para eles.
  - `gravarPrevia(pasta: string, montagem) -> Promise<void>` (escreve `index.html` e copia os arquivos).
  - `criarContextoPeca({negocio, textos, fotos, video, assinatura, opcoes}) -> ctx` (o mesmo `ctx` que o montador passa para as peças. As Tarefas 6 e 7 usam para testar peças sozinhas).

**Conteúdo fixo da página:** `<html lang="pt-BR">`, `<meta name="viewport" content="width=device-width, initial-scale=1">`, a meta de robots das Global Constraints, `<title>{nome} | Prévia</title>`, `preconnect` para `fonts.googleapis.com` e `fonts.gstatic.com` e o link do Google Fonts do par escolhido com `display=swap`, CSS embutido (base, movimento, peças usadas), a faixa de demonstração fixa no rodapé da tela, com texto exato "Demonstração criada pelo {estudio}. Este não é o site oficial de {nome}.", e o rodapé com "Fotos: " seguido dos créditos únicos das mídias usadas, separados por vírgula. Uma seção sem requisito atendido nunca é renderizada, mesmo se estiver na assinatura.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('página tem noindex, faixa, créditos e título principal', async () => {
  const { html } = montarPrevia(montagemExemplo);
  assert.match(html, /<meta name="robots" content="noindex, nofollow">/);
  assert.match(html, /Demonstração criada pelo Estúdio Dez\. Este não é o site oficial de Barbearia do Zé\./);
  assert.match(html, /Fotos: .*@barbeariadoze/);
  assert.match(html, /data-titulo-principal/);
  assert.match(html, /data-movimento="suave"/);
});
test('nome perigoso sai escapado', () => {
  const { html } = montarPrevia({ ...montagemExemplo, negocio: { ...montagemExemplo.negocio, nome: `<script>alert(1)</script> D'Ávila & Co` } });
  assert.ok(!html.includes('<script>alert(1)</script>'));
  assert.ok(html.includes('&lt;script&gt;'));
});
test('sem travessão nem meia-risca no texto', () => {
  assert.ok(!/[—–]/.test(montarPrevia(montagemExemplo).html));
});
test('chamada cai para telefone e depois para o Maps', () => {
  const semZap = { ...montagemExemplo.negocio, whatsapp: undefined };
  assert.match(montarPrevia({ ...montagemExemplo, negocio: semZap }).html, /href="tel:\+?\d+"/);
  const soMaps = { ...semZap, telefone: undefined };
  assert.match(montarPrevia({ ...montagemExemplo, negocio: soMaps }).html, /href="https:\/\/maps\.google\.com/);
});
test('seção sem dados some', () => {
  const semAval = { ...montagemExemplo.negocio, avaliacoes: [] };
  assert.ok(!montarPrevia({ ...montagemExemplo, negocio: semAval }).html.includes('s-avaliacoes'));
});
test('gravarPrevia copia as mídias', async () => {
  const m = montarPrevia(montagemExemplo); await gravarPrevia(pastaTmp, m);
  for (const a of m.arquivos) assert.ok(existsSync(join(pastaTmp, a.destino)));
});
test('fonte de título nunca é Inter ou Roboto', () => {
  assert.ok(!/family=(Inter|Roboto)[:&]/.test(montarPrevia(montagemExemplo).html));
});
test('respeita reduzir movimento', () => {
  assert.match(montarPrevia(montagemExemplo).html, /prefers-reduced-motion:\s*reduce/);
});
```

`montagemExemplo` (no topo do arquivo) é a Barbearia do Zé em Campinas, com WhatsApp, telefone, `mapsUrl: 'https://maps.google.com/?cid=1'`, 3 avaliações, Instagram `@barbeariadoze`, textos completos, 6 fotos tratadas geradas na hora com `tratarFoto`, e uma assinatura que usa `foto-cheia`, `playfair-dmsans`, `suave` e a variante `a` de todas as seções.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/montar.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar o montador, `base.css`, `movimento.css`, `movimento.js`, o topo `foto-cheia` e as 8 seções `-a`.** As peças seguem a barra de design da spec: celular primeiro, tipografia fluida com `clamp()`, alvo de toque de pelo menos 44 px, texto sobre foto sempre com véu escuro ou claro para manter o contraste, nada de fundo preto ou branco puro (as cores vêm da paleta), e um elemento assinatura por peça (por exemplo, número grande do serviço, aspas grandes nas avaliações).

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/montar.test.js`. Expected: PASS.

- [ ] **Step 5: Gerar uma página de exemplo e olhar.** Escrever um teste temporário, ou usar o REPL, que grava `montagemExemplo` em `saida/exemplo/` e abre com o Playwright em 390 e 1440 px, salvando capturas. Ler as capturas e corrigir o que estiver feio ou quebrado antes do commit.

- [ ] **Step 6: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): montador de prévias, animações e primeiras peças do kit"`

---

### Task 6: Os outros 7 topos

**Files:**
- Create: `jarvis/kit/topos/{video-fundo,colagem,tela-dividida,titulo-gigante,carrossel,moldura,mosaico-movel}.js`
- Test: `jarvis/test/kit-topos.test.js`

**Interfaces:**
- Consumes: contrato de peça e `util` (Tarefa 5), `TOPOS` (Tarefa 4).

**Comportamentos fixos:** `video-fundo` usa `<video autoplay muted loop playsinline preload="metadata" poster="{capa}">` e, com `prefers-reduced-motion: reduce`, mostra só a capa (sem `autoplay`, via `movimento.js`). `carrossel` troca a foto sozinho a cada 5 s, pausa quando sai da tela e tem botões com `aria-label` em português. `mosaico-movel` usa `data-anim="paralaxe"`. Todo topo tem exatamente um elemento com `data-titulo-principal` e usa `prioridade: true` só na primeira foto.

- [ ] **Step 1: Escrever os testes que falham:**

```js
for (const { id } of TOPOS) {
  test(`topo ${id} existe e segue o contrato`, async () => {
    const { render } = await import(`../kit/topos/${id}.js`);
    const { html, css } = render(ctxCompleto);
    assert.equal((html.match(/data-titulo-principal/g) || []).length, 1);
    assert.ok(css.includes(`.t-${id}`));
    assert.ok(!/[—–]/.test(html));
  });
}
test('video-fundo tem os atributos de vídeo leve', async () => {
  const { html } = (await import('../kit/topos/video-fundo.js')).render(ctxCompleto);
  for (const attr of ['autoplay', 'muted', 'loop', 'playsinline', 'poster=']) assert.ok(html.includes(attr));
});
```

`ctxCompleto` vem de `criarContextoPeca` (Tarefa 5) com o mesmo conjunto de dados de `contextoCompleto` (Tarefa 4), com fotos e vídeo tratados de verdade (gerados no `before`). A Tarefa 7 usa o mesmo `ctxCompleto`.

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/kit-topos.test.js`. Expected: FAIL nos 7 topos novos.

- [ ] **Step 3: Implementar os 7 topos.**

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/kit-topos.test.js`. Expected: PASS.

- [ ] **Step 5: Olhar.** Gravar uma prévia por topo em `saida/topos/` e tirar capturas em 390 e 1440 px. Ler cada captura e corrigir o que estiver quebrado ou com cara de modelo pronto.

- [ ] **Step 6: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): oito topos do kit"`

---

### Task 7: Variantes b e c das 8 seções

**Files:**
- Create: `jarvis/kit/secoes/{servicos,sobre,galeria,avaliacoes,numeros,localizacao,perguntas,chamada-final}-{b,c}.js` (16 arquivos)
- Test: `jarvis/test/kit-secoes.test.js`

**Interfaces:**
- Consumes: contrato de peça (Tarefa 5), `SECOES`, `VARIANTES` (Tarefa 4).

**Comportamentos fixos:** `avaliacoes` mostra o autor e as estrelas, com textos maiores que 280 caracteres cortados numa palavra inteira e reticências. Uma das três variantes de `avaliacoes` usa `data-anim="faixa"`. Uma das três de `numeros` usa `data-anim="contador"`. `perguntas` usa `<details>`/`<summary>` (acessível sem JS). `localizacao` tem o link "Ver no mapa" (`mapsUrl`) e lista os horários, sem iframe de mapa (peso e privacidade). `chamada-final` usa `util.linkContato()` e não renderiza o botão se ele for `null`.

- [ ] **Step 1: Escrever os testes que falham:**

```js
for (const { tipo } of SECOES) for (const v of VARIANTES) {
  test(`seção ${tipo}-${v} existe e segue o contrato`, async () => {
    const { html, css } = (await import(`../kit/secoes/${tipo}-${v}.js`)).render(ctxCompleto);
    assert.ok(html.includes(`s-${tipo}`)); assert.ok(css.length > 0); assert.ok(!/[—–]/.test(html));
  });
}
test('avaliação longa é cortada em 280 caracteres', async () => {
  const longa = { autor: 'Ana', nota: 5, texto: 'ótimo '.repeat(200) };
  const ctx = { ...ctxCompleto, negocio: { ...ctxCompleto.negocio, avaliacoes: [longa, longa] } };
  for (const v of VARIANTES) {
    const { html } = (await import(`../kit/secoes/avaliacoes-${v}.js`)).render(ctx);
    assert.ok(!html.includes('ótimo '.repeat(60)));
  }
});
test('variantes de avaliações e números usam faixa e contador', async () => {
  const htmls = async t => Promise.all(VARIANTES.map(async v => (await import(`../kit/secoes/${t}-${v}.js`)).render(ctxCompleto).html));
  assert.ok((await htmls('avaliacoes')).some(h => h.includes('data-anim="faixa"')));
  assert.ok((await htmls('numeros')).some(h => h.includes('data-anim="contador"')));
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/kit-secoes.test.js`. Expected: FAIL nas 16 variantes novas.

- [ ] **Step 3: Implementar as 16 variantes.** Cada variante de um tipo precisa ser visualmente distinta das outras duas (layout diferente, não só cor).

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/kit-secoes.test.js`. Expected: PASS.

- [ ] **Step 5: Olhar.** Gravar uma página com as 3 variantes de cada tipo em `saida/secoes/`, tirar capturas em 390 e 1440 px, ler e corrigir.

- [ ] **Step 6: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): variantes b e c das seções do kit"`

---

### Task 8: Textos base por nicho

**Files:**
- Create: `jarvis/src/previa/textos-base.js`
- Test: `jarvis/test/textos-base.test.js`

**Interfaces:**
- Consumes: `normalizar` (Tarefa 1), tipos.
- Produces:
  - `NICHOS: string[]` = `['barbearia','salao','estetica','restaurante','pizzaria','hamburgueria','cafeteria','padaria','clinica','odontologia','academia','petshop','oficina','imobiliaria','generico']`
  - `identificarNicho(texto: string) -> string` (reconhece variações como "Barbearia", "barber shop", "salão de beleza", "clínica odontológica", "pet shop". Sem reconhecimento, devolve `generico`)
  - `textosBase(negocio: Negocio, aleatorio?: () => number) -> TextosPrevia`

**Regras:** cada nicho tem pelo menos 3 títulos, 3 subtítulos, 5 serviços, 2 textos "sobre", 5 perguntas com resposta e 3 chamadas, sorteados com `aleatorio`. Os textos usam `{nome}`, `{bairro}` (ou `{cidade}` se não houver bairro) e, quando houver avaliação com nota 5, um trecho de até 120 caracteres dela entre aspas no subtítulo ou no "sobre". Escrita simples, voz confiante do negócio, sem travessão.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('identificarNicho reconhece variações', () => {
  assert.equal(identificarNicho('Barber Shop'), 'barbearia');
  assert.equal(identificarNicho('Clínica Odontológica Sorriso'), 'odontologia');
  assert.equal(identificarNicho('Pet Shop'), 'petshop');
  assert.equal(identificarNicho('Loja de parafusos'), 'generico');
});
for (const nicho of NICHOS) {
  test(`textos base completos: ${nicho}`, () => {
    const t = textosBase({ ...negocioBase, nicho }, criarAleatorio(3));
    assert.ok(t.titulo && t.subtitulo && t.sobre && t.chamada);
    assert.ok(t.servicos.length >= 3 && t.perguntas.length >= 2);
    const tudo = JSON.stringify(t);
    assert.ok(!/[—–]/.test(tudo)); assert.ok(!tudo.includes('{'));
    assert.ok(tudo.includes(negocioBase.nome));
  });
}
test('usa trecho de avaliação 5 estrelas', () => {
  const t = textosBase({ ...negocioBase, avaliacoes: [{ autor: 'Ana', nota: 5, texto: 'Melhor corte da cidade, atendimento impecável.' }] }, criarAleatorio(1));
  assert.ok(JSON.stringify(t).includes('Melhor corte da cidade'));
});
test('sem bairro usa a cidade', () => {
  const t = textosBase({ ...negocioBase, bairro: undefined }, criarAleatorio(1));
  assert.ok(JSON.stringify(t).includes(negocioBase.cidade));
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/textos-base.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `textos-base.js`.**

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/textos-base.test.js`. Expected: PASS.

- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): textos base por nicho"`

---

### Task 9: Conferência automática

**Files:**
- Create: `jarvis/src/util/navegador.js`, `jarvis/src/previa/conferir.js`
- Test: `jarvis/test/conferir.test.js`

**Interfaces:**
- Produces:
  - `abrirNavegador() -> Promise<import('playwright-core').Browser>` (ordem: `process.env.JARVIS_NAVEGADOR` como `executablePath`, depois `channel: 'msedge'`, depois `channel: 'chrome'`, depois o Chromium do Playwright quando `PLAYWRIGHT_BROWSERS_PATH` existe. Sempre headless. Se nada abrir, lança `Error` com a mensagem "Não achei o Edge nem o Chrome neste computador.")
  - `conferirPrevia(pasta: string, opcoes?: {navegador?: Browser}) -> Promise<ResultadoConferencia>` (abre `file://{pasta}/index.html` em 390 x 844 e 1440 x 900, rola até o fim devagar para disparar o carregamento preguiçoso e as animações, espera a rede ficar parada, confere e salva `conferencia/celular.png` e `conferencia/pc.png` na pasta, com a primeira tela)

**Problemas detectados** (cada um vira uma frase em `problemas`, com o tamanho de tela no começo, por exemplo `"celular: conteúdo vaza para os lados (scrollWidth 412 > 390)"`):
- `document.documentElement.scrollWidth > innerWidth + 1`
- `img` com `complete && naturalWidth === 0`
- erro no console (`console` do tipo `error` ou `pageerror`), ignorando falhas de rede para `fonts.googleapis.com` e `fonts.gstatic.com`
- `[data-titulo-principal]` ausente, com altura zero ou fora da primeira tela

`ok` é `problemas.length === 0`.

- [ ] **Step 1: Escrever os testes que falham:**

```js
test('prévia boa passa', async () => {
  await gravarPrevia(boa, montarPrevia(montagemExemplo));
  const r = await conferirPrevia(boa);
  assert.deepEqual(r.problemas, []); assert.ok(r.ok);
  assert.ok(existsSync(r.capturas.celular) && existsSync(r.capturas.pc));
});
test('página quebrada é reprovada com os motivos', async () => {
  await writeFile(join(ruim, 'index.html'), `<!doctype html><meta name=viewport content="width=device-width"><body>
    <div style="width:2000px">largo</div><img src="nao-existe.jpg"><script>throw new Error('x')</script>`);
  const r = await conferirPrevia(ruim);
  assert.equal(r.ok, false);
  for (const trecho of ['vaza para os lados', 'imagem quebrada', 'erro', 'título principal']) assert.ok(r.problemas.some(p => p.includes(trecho)), trecho);
});
```

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/conferir.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `navegador.js` e `conferir.js`.** Abrir um navegador por chamada quando `opcoes.navegador` não vier, e fechar no final, mesmo com erro.

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/conferir.test.js`. Expected: PASS.

- [ ] **Step 5: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): conferência automática das prévias"`

---

### Task 10: Pipeline completo e demonstração

**Files:**
- Create: `jarvis/src/previa/gerar.js`, `jarvis/fixtures/negocios-demo.json`, `jarvis/scripts/baixar-midias-demo.mjs`, `jarvis/scripts/demo-previas.mjs`
- Test: `jarvis/test/gerar.test.js`

**Interfaces:**
- Consumes: tudo das Tarefas 1 a 9.
- Produces (usado pelo plano 2):
  - `gerarPrevia(negocio: Negocio, opcoes: {pastaSaida: string, usadas: AssinaturaUsada[], textos?: TextosPrevia, assinatura?: Assinatura, estudio?: string, aleatorio?: () => number, conferir?: boolean, navegador?: Browser}) -> Promise<PreviaGerada & {avisos: string[]}>`

**Fluxo de `gerarPrevia`:** cria o slug, trata as mídias em `{pastaSaida}/{slug}/midias/`, junta as cores das fotos (até 3 por foto, as mais presentes primeiro), deriva a paleta base, usa `opcoes.textos` ou `textosBase`, usa `opcoes.assinatura` se vier e for única, senão `escolherAssinaturaPorRegras`, monta, grava e confere (quando `conferir !== false`, que é o padrão). Se a conferência reprovar, tenta até mais 2 vezes com outra assinatura por regras (a reprovada entra nas `usadas` só desta chamada). Devolve o último resultado, com `conferencia.ok` falso se as 3 falharam. A pasta de uma tentativa reprovada é apagada antes da próxima. O plano 2 recebe a decisão de não publicar.

**Demonstração:** `fixtures/negocios-demo.json` tem 5 negócios fictícios com dados realistas: "Barbearia Navalha de Ouro" e "Studio Corte Fino" (as duas barbearias em Campinas, Cambuí e Taquaral), "Forno da Nonna" (pizzaria, Campinas), "Essenza Estética" (clínica de estética, Jundiaí) e "Patas & Cia" (pet shop, Valinhos). Cada um tem de 4 a 8 fotos do Pexels (URLs `https://images.pexels.com/photos/{id}/pexels-photo-{id}.jpeg?auto=compress&w=2000` escolhidas no pexels.com combinando com o nicho, com o crédito "Foto: {autor} (Pexels)"), avaliações e horários inventados, e o "Forno da Nonna" tem também um vídeo. A "Patas & Cia" tem só 1 foto, para exercitar o caso de pouca mídia. `baixar-midias-demo.mjs` baixa as mídias para `fixtures/midias/`. Se o vídeo não puder ser baixado, a demonstração segue sem ele. `demo-previas.mjs` gera as 5 prévias em `saida/demo/`, encadeando as `usadas`, e escreve `saida/demo/index.html`: uma galeria com a miniatura de celular e de PC de cada uma, a assinatura em texto e o resultado da conferência.

- [ ] **Step 1: Escrever os testes que falham** (mídias geradas no `before` com sharp e ffmpeg):

```js
test('duas barbearias na mesma cidade saem únicas e aprovadas', async () => {
  const usadas = [];
  const a = await gerarPrevia(barbeariaA, { pastaSaida: tmp, usadas, aleatorio: criarAleatorio(1) });
  usadas.push({ assinatura: a.assinatura, nicho: 'barbearia', cidade: 'Campinas' });
  const b = await gerarPrevia(barbeariaB, { pastaSaida: tmp, usadas, aleatorio: criarAleatorio(1) });
  assert.ok(a.conferencia.ok, a.conferencia.problemas.join('; '));
  assert.ok(b.conferencia.ok, b.conferencia.problemas.join('; '));
  assert.ok(contarDiferencas(a.assinatura, b.assinatura) >= 3);
  assert.notEqual(a.slug, b.slug);
});
test('negócio com nome longo, avaliação enorme e uma foto só passa no celular', async () => {
  const r = await gerarPrevia(negocioDificil, { pastaSaida: tmp, usadas: [] });
  assert.ok(r.conferencia.ok, r.conferencia.problemas.join('; '));
});
test('negócio sem nenhuma mídia ainda gera prévia', async () => {
  const r = await gerarPrevia({ ...barbeariaA, id: 'sem-midia', midias: [] }, { pastaSaida: tmp, usadas: [] });
  assert.ok(r.conferencia.ok, r.conferencia.problemas.join('; '));
  assert.equal(r.assinatura.topo, 'titulo-gigante');
});
test('vídeo do negócio vira topo possível', async () => {
  const r = await gerarPrevia(pizzariaComVideo, { pastaSaida: tmp, usadas: [], assinatura: assinaturaComVideo });
  assert.equal(r.assinatura.topo, 'video-fundo');
  assert.ok(existsSync(join(r.pasta, 'midias')));
});
```

`negocioDificil`: nome com 60 caracteres, acentos e "&", uma avaliação de 1.000 caracteres, uma única foto vertical de 640 x 1136, sem WhatsApp. Sem nenhuma foto, a paleta base vem de `derivarPaleta([], negocio.clima)`, que precisa devolver uma paleta válida (acrescentar esse caso ao teste da Tarefa 2 ao implementar esta tarefa).

- [ ] **Step 2: Rodar e ver falhar.** Run: `node --test test/gerar.test.js`. Expected: FAIL.

- [ ] **Step 3: Implementar `gerar.js`.**

- [ ] **Step 4: Rodar e ver passar.** Run: `node --test test/gerar.test.js`. Expected: PASS.

- [ ] **Step 5: Rodar a suíte inteira.** Run: `npm test`. Expected: todos os testes passam.

- [ ] **Step 6: Criar a fixture e os scripts da demonstração, baixar as mídias e gerar.** Run: `npm run demo:midias && npm run demo`. Expected: `saida/demo/index.html` com 5 prévias, todas com conferência aprovada, e as duas barbearias com pelo menos 3 diferenças de assinatura.

- [ ] **Step 7: Olhar como cliente.** Ler as capturas de celular e PC das 5 prévias. Cada uma precisa parecer um site profissional e diferente das outras. Corrigir as peças do kit que não passarem e gerar de novo.

- [ ] **Step 8: Commit.** `git add -A jarvis && git commit -m "feat(jarvis): pipeline de prévias e demonstração"` (sem `saida/` e sem `fixtures/midias/`, que estão no `.gitignore`).

---

## Entrega deste plano

Ao final: `npm test` passa e `npm run demo` gera 5 prévias únicas e conferidas. As prévias de demonstração são mostradas ao usuário num link que abre no celular e no PC, para ele aprovar o visual do kit antes do plano 2.

---

## Registro da execução (2026-11-21)

Plano executado por inteiro, com revisão final de um revisor separado ("pronto com correções": 0 crítico, 8 importantes, 11 menores). As 8 importantes e mais uma que subi de menor foram corrigidas com teste. Suíte final: 170 de 170.

### Decisões tomadas durante a construção (com o custo se estiverem erradas)

1. T2: sem cor nas fotos (cinza, preto, branco), o destaque cai para dourado #c8962e. Custo: negócio monocromático ganha dourado.
2. T2: `extrairCores` repete cores para sempre devolver 5. Custo: cores duplicadas na lista.
3. T2: fundo escuro com luminância até 0,035 (o design dizia 0,05), senão o teste do plano era impossível. Custo: nenhum.
4. T4: `derivarPaleta` aceita forçar fundo claro ou escuro, para alternar paletas. Custo: um parâmetro a mais.
5. T4: paleta ausente nunca conta como igual (usado para saber se a falha foi só de paleta). Custo: nenhum.
6. T4: depois de uma falha que não é de paleta, a nova tentativa volta às cores do negócio. Custo: algumas tentativas a mais.
7. T5: peças registradas em `kit/pecas.js` porque o montador é síncrono. Custo: um registro a manter (coberto por teste).
8. T5: cada peça gera o próprio elemento raiz. Custo: nenhum.
9. T5: `util` ganhou numero, cortar, estrelas, caminho e ancora, e `ctx.secoes`. Custo: nenhum.
10. T5: celular do Google vira o WhatsApp quando não há WhatsApp. Custo: link de WhatsApp para um celular que não usa WhatsApp.
11. T5: títulos de seção são frases curtas fixas. Custo: títulos genéricos.
12. T6: partes repetidas dos topos em `_comum.js`; reel vertical no PC fica numa moldura alta. Custo: reel menor no PC.
13. T6: testes dos topos usam vídeo de verdade (precisam de ffmpeg). Custo: testes exigem ffmpeg.
14. T7: testes além do plano para as variantes. Custo: nenhum.
15. T7: grades de uma coluna usam `minmax(0,1fr)`. Custo: nenhum.
16. T8: o teste do plano `!includes('{')` nunca passaria (JSON começa com `{`); virou "nenhum {nome} ou {lugar} sobrando". Custo: nenhum.
17. T8: respostas das perguntas não inventam fatos; no máximo 5 perguntas. Custo: textos menos específicos.
18. T8: trecho de avaliação entre aspas retas. Custo: nenhum.
19. T9: opção `bloquearRede` para os testes não usarem internet. Custo: nenhum.
20. T9: falhas de fonte filtradas pela URL do erro. Custo: nenhum.
21. T10: nova tentativa apaga só a página e as capturas, não as mídias. Custo: nenhum.
22. T10: opção `ficticio` para a demonstração avisar que nome, avaliações e números são inventados. Custo: nenhum.
23. T10: demonstração sem telefone nem Instagram, para não apontar para pessoas reais. Custo: a demo não mostra o botão de WhatsApp.
24. T10: o vídeo da pizzaria da demo é montado com fotos (vídeos do Pexels bloqueados neste ambiente). Custo: é uma montagem, não filmagem.
25. T10: pesos da direção por regras 8:1 para o clima e 30 para o reel no topo, mais etiquetas nas fontes. Custo: menos variedade dentro de um clima.
26. T10: nome de 60 caracteres do teste ajustado (tinha 59). Custo: nenhum.
27. Revisão: "nicho por pedaço de palavra" subiu de menor para importante e foi corrigido.
28. Revisão: visual profissional conferido por capturas de todos os topos, variantes e da demo. Custo: o usuário pode não gostar de alguma peça.
29. Revisão: corte com fontes reais resolvido no CSS e medido na conferência. Custo: nenhum.
30. Revisão: nota de velocidade 80+ medida no plano 2, depois de publicar. Custo: prévia lenta até lá.
31. Revisão: créditos do Google, publicação, remoção em 45 dias e "não contatar" ficam nos planos 2 e 3.
32. Revisão: travessão em fala de cliente também é limpo. Custo: vírgula no lugar do travessão.
33. Revisão: texto do botão pode ter contraste de 3,35:1 no pior caso; mantido. Custo: botão pouco legível em caso raro.
34. Revisão: risco de esgotar combinações únicas mantido. Custo: erro depois de muitos meses no mesmo nicho e cidade.
35. Revisão: comportamento real no Windows conferido na instalação do plano 3. Custo: o problema aparece lá primeiro.
36. Revisão: pesos 8:1 mantidos.

### Pontos menores deixados para depois

- `mapsUrl` não é restrito a https (vem do Google hoje).
- Faixa de avaliações deixa espaço vazio no PC com 2 ou 3 avaliações.
- ffmpeg falha com vídeo de altura ímpar menor que 720 (o vídeo é descartado com aviso).
- Avisos trazem texto técnico cru; traduzir antes do plano 3 mostrar ao usuário.
- Cores quase brancas passam como coloridas no limite de saturação.
- Telefones estrangeiros aceitos como brasileiros.
- Testes que usam ffmpeg falham, em vez de pular, num PC sem ffmpeg.
- `gerarPrevia` com erro deixa a pasta de mídias para trás.
- "0 avaliações" aparece com contagem zero; nota ausente mostra 5 estrelas; "Fotos:" também lista o crédito do vídeo.
- Detalhes de código (duplicação no foto-cheia, `aria-hidden="false"`, prefixos de classe).
