import { existsSync } from 'node:fs';
import { chromium } from 'playwright-core';

/**
 * Abre um navegador invisível usando o que já existe no computador:
 * JARVIS_NAVEGADOR, depois Edge, depois Chrome, depois o Chromium do Playwright (testes).
 * @returns {Promise<import('playwright-core').Browser>}
 */
export async function abrirNavegador() {
  const tentativas = [];
  if (process.env.JARVIS_NAVEGADOR) tentativas.push({ headless: true, executablePath: process.env.JARVIS_NAVEGADOR });
  tentativas.push({ headless: true, channel: 'msedge' });
  tentativas.push({ headless: true, channel: 'chrome' });
  if (process.env.PLAYWRIGHT_BROWSERS_PATH && existsSync(process.env.PLAYWRIGHT_BROWSERS_PATH)) tentativas.push({ headless: true });
  for (const opcoes of tentativas) {
    try {
      return await chromium.launch(opcoes);
    } catch {
      // tenta o próximo
    }
  }
  throw new Error('Não achei o Edge nem o Chrome neste computador.');
}
