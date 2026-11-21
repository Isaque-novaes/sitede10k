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
