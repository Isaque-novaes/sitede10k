(function () {
  var reduzir = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var corpo = document.body;
  var movimento = corpo.getAttribute('data-movimento') || 'suave';
  var itens = Array.prototype.slice.call(document.querySelectorAll('[data-anim]'));

  function formatar(v, casas) {
    return v.toLocaleString('pt-BR', { minimumFractionDigits: casas, maximumFractionDigits: casas });
  }

  if (!reduzir) {
    document.querySelectorAll('[data-anim="texto-partes"]').forEach(function (el) {
      var texto = el.textContent.trim();
      el.setAttribute('aria-label', texto);
      el.textContent = '';
      texto.split(/\s+/).forEach(function (p, i) {
        var mascara = document.createElement('span');
        mascara.className = 'palavra-mascara';
        mascara.setAttribute('aria-hidden', 'true');
        var palavra = document.createElement('span');
        palavra.className = 'palavra';
        palavra.style.setProperty('--i', i);
        palavra.textContent = p;
        mascara.appendChild(palavra);
        el.appendChild(mascara);
        el.appendChild(document.createTextNode(' '));
      });
    });
    document.querySelectorAll('[data-anim="contador"]').forEach(function (el) {
      el.textContent = formatar(0, parseInt(el.getAttribute('data-casas') || '0', 10));
    });
  } else {
    document.querySelectorAll('video[autoplay]').forEach(function (v) {
      v.removeAttribute('autoplay');
      try { v.pause(); } catch (e) { /* sem vídeo */ }
    });
  }

  function contar(el) {
    var alvo = parseFloat(el.getAttribute('data-valor'));
    var casas = parseInt(el.getAttribute('data-casas') || '0', 10);
    if (isNaN(alvo)) return;
    if (reduzir) { el.textContent = formatar(alvo, casas); return; }
    var duracao = movimento === 'energico' ? 900 : 1600;
    var inicio = performance.now();
    function passo(t) {
      var p = Math.min(1, (t - inicio) / duracao);
      var e = 1 - Math.pow(1 - p, 3);
      el.textContent = formatar(alvo * e, casas);
      if (p < 1) requestAnimationFrame(passo);
    }
    requestAnimationFrame(passo);
  }

  if (reduzir || !('IntersectionObserver' in window)) {
    itens.forEach(function (el) {
      el.classList.add('visivel');
      if (el.getAttribute('data-anim') === 'contador') contar(el);
    });
  } else {
    var observador = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (e) {
        var el = e.target;
        var tipo = el.getAttribute('data-anim');
        if (e.isIntersecting) {
          el.classList.add('visivel');
          if (tipo === 'contador' && !el.hasAttribute('data-contado')) { el.setAttribute('data-contado', ''); contar(el); }
          if (tipo !== 'faixa') observador.unobserve(el);
        } else if (tipo === 'faixa') {
          el.classList.remove('visivel');
        }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0 });
    itens.forEach(function (el) { observador.observe(el); });
  }

  var paralaxe = Array.prototype.slice.call(document.querySelectorAll('[data-anim="paralaxe"]'));
  var fatorMovimento = parseFloat(getComputedStyle(corpo).getPropertyValue('--fator-paralaxe')) || 0;
  if (!reduzir && paralaxe.length && fatorMovimento > 0) {
    var pendente = false;
    var atualizar = function () {
      pendente = false;
      var vh = window.innerHeight;
      paralaxe.forEach(function (el) {
        var r = el.getBoundingClientRect();
        if (r.bottom < -200 || r.top > vh + 200) return;
        var fator = parseFloat(el.getAttribute('data-fator') || '0.12') * fatorMovimento;
        var desloc = ((r.top + r.height / 2) - vh / 2) * -fator;
        el.style.transform = 'translate3d(0,' + desloc.toFixed(1) + 'px,0)';
      });
    };
    window.addEventListener('scroll', function () {
      if (!pendente) { pendente = true; requestAnimationFrame(atualizar); }
    }, { passive: true });
    atualizar();
  }

  document.querySelectorAll('[data-carrossel]').forEach(function (c) {
    var slides = c.querySelectorAll('[data-slide]');
    if (slides.length < 2) return;
    var atual = 0;
    var timer = null;
    var visivel = true;
    function mostrar(i) {
      slides[atual].classList.remove('ativo');
      atual = (i + slides.length) % slides.length;
      slides[atual].classList.add('ativo');
    }
    function tocar() {
      parar();
      if (!reduzir && visivel) timer = setInterval(function () { mostrar(atual + 1); }, 5000);
    }
    function parar() { if (timer) { clearInterval(timer); timer = null; } }
    var ant = c.querySelector('[data-anterior]');
    var prox = c.querySelector('[data-proximo]');
    if (ant) ant.addEventListener('click', function () { mostrar(atual - 1); tocar(); });
    if (prox) prox.addEventListener('click', function () { mostrar(atual + 1); tocar(); });
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (es) {
        visivel = es[0].isIntersecting;
        if (visivel) tocar(); else parar();
      }).observe(c);
    }
    tocar();
  });
})();
