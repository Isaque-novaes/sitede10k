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
