import { requisitarJson } from './http.js';

const SERVICO = 'Google Maps';
const URL_BUSCA = 'https://places.googleapis.com/v1/places:searchText';
const MASCARA_BUSCA = [
  'places.id', 'places.displayName', 'places.formattedAddress', 'places.addressComponents', 'places.location',
  'places.types', 'places.primaryTypeDisplayName', 'places.businessStatus', 'places.googleMapsUri',
  'places.websiteUri', 'places.nationalPhoneNumber', 'places.internationalPhoneNumber', 'places.rating', 'places.userRatingCount',
].join(',');

const componente = (componentes, ...tipos) => (componentes ?? []).find((c) => tipos.some((t) => c.types?.includes(t)))?.longText;

/** @returns {import('../prospeccao/tipos.js').Lugar} */
function paraLugar(p) {
  return {
    id: p.id,
    nome: p.displayName?.text ?? '',
    endereco: p.formattedAddress,
    bairro: componente(p.addressComponents, 'sublocality_level_1', 'sublocality'),
    cidade: componente(p.addressComponents, 'administrative_area_level_2', 'locality'),
    local: p.location ? { lat: p.location.latitude, lng: p.location.longitude } : undefined,
    tipos: p.types ?? [],
    tipoPrincipal: p.primaryTypeDisplayName?.text,
    situacao: p.businessStatus ?? 'OPERATIONAL',
    mapsUrl: p.googleMapsUri,
    site: p.websiteUri,
    telefone: p.nationalPhoneNumber,
    telefoneInternacional: p.internationalPhoneNumber,
    nota: p.rating,
    totalAvaliacoes: p.userRatingCount,
  };
}

/**
 * Busca lugares por texto no Google Maps (Places API New, Text Search).
 * @param {string} texto
 * @param {{chave:string, fetch?:typeof fetch, registrar?:Function, local?:{lat:number,lng:number}, raioM?:number, quantidade?:number}} opcoes
 */
export async function buscarLugares(texto, { chave, fetch, registrar, local, raioM = 2000, quantidade = 20 }) {
  const corpo = { textQuery: texto, languageCode: 'pt-BR', regionCode: 'BR', pageSize: quantidade };
  if (local) corpo.locationBias = { circle: { center: { latitude: local.lat, longitude: local.lng }, radius: raioM } };
  const resposta = await requisitarJson(URL_BUSCA, {
    servico: SERVICO, metodo: 'POST', corpo, fetch, registrar,
    cabecalhos: { 'X-Goog-Api-Key': chave, 'X-Goog-FieldMask': MASCARA_BUSCA },
  });
  return (resposta?.places ?? []).map(paraLugar);
}

/**
 * Detalhes de um lugar: horários, até 5 avaliações com texto e até 10 fotos.
 * @param {string} id
 */
export async function detalharLugar(id, { chave, fetch, registrar }) {
  const r = await requisitarJson(`https://places.googleapis.com/v1/places/${encodeURIComponent(id)}?languageCode=pt-BR`, {
    servico: SERVICO, fetch, registrar,
    cabecalhos: { 'X-Goog-Api-Key': chave, 'X-Goog-FieldMask': 'id,regularOpeningHours,reviews,photos' },
  });
  return {
    horarios: r?.regularOpeningHours?.weekdayDescriptions ?? [],
    avaliacoes: (r?.reviews ?? [])
      .filter((a) => a.text?.text?.trim())
      .slice(0, 5)
      .map((a) => ({ autor: a.authorAttribution?.displayName ?? 'Cliente', nota: a.rating, texto: a.text.text.trim() })),
    fotos: (r?.photos ?? []).slice(0, 10).map((f) => {
      const autor = f.authorAttributions?.[0]?.displayName;
      return { nome: f.name, largura: f.widthPx, altura: f.heightPx, credito: autor ? `Foto: ${autor} (Google Maps)` : 'Foto: Google Maps' };
    }),
  };
}

/** Baixa uma foto do Google Maps pelo nome do recurso. */
export async function baixarFotoLugar(nome, destino, { chave, fetch, registrar, larguraMax = 1600 }) {
  const { baixarArquivo } = await import('./baixar.js');
  const url = `https://places.googleapis.com/v1/${nome}/media?maxWidthPx=${larguraMax}&key=${encodeURIComponent(chave)}`;
  return baixarArquivo(url, destino, { servico: SERVICO, fetch, registrar });
}
