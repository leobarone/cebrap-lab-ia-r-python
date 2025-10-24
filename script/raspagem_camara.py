
import time
from pathlib import Path
from typing import Optional, Dict, Any, List

import requests
import pandas as pd
from unidecode import unidecode
import nltk
from nltk.corpus import stopwords

# ---------- Sessão HTTP com retry + cabeçalhos ----------
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter

def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update({
        "Accept": "application/json",
        "User-Agent": "cebrap-lab-ia/1.0 (+https://github.com/cebrap-lab)"
    })
    retries = Retry(
        total=5, backoff_factor=0.5,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"]
    )
    s.mount("https://", HTTPAdapter(max_retries=retries))
    s.mount("http://", HTTPAdapter(max_retries=retries))
    return s

SESSION = make_session()

BASE = "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

# ---------- 1) Listagem ----------
def listar_proposicoes(sigla_tipo: str = "PL", ano: int = 2025, itens: int = 100) -> pd.DataFrame:
    params = {
        "siglaTipo": sigla_tipo, "ano": ano,
        "ordem": "ASC", "ordenarPor": "id", "itens": itens
    }
    r = SESSION.get(BASE, params=params, timeout=60)
    r.raise_for_status()
    return pd.DataFrame(r.json().get("dados", []))

# ---------- 2) Detalhe ----------
def obter_proposicao_detalhe(pid: int) -> Optional[Dict[str, Any]]:
    url = f"{BASE}/{pid}"
    r = SESSION.get(url, timeout=60)
    if not r.ok:
        return None
    d = r.json().get("dados", {}) or {}
    st = d.get("statusProposicao") or {}
    return {
        "id": d.get("id"),
        "siglaTipo": d.get("siglaTipo"),
        "numero": d.get("numero"),
        "ano": d.get("ano"),
        "ementa": d.get("ementa"),
        "dataApresentacao": d.get("dataApresentacao"),
        "urlInteiroTeor": d.get("urlInteiroTeor"),
        "status_apreciacao": st.get("apreciacao"),
    }

# ---------- 2b) Arquivos da proposição (fallback p/ PDF) ----------
def listar_arquivos(pid: int) -> List[Dict[str, Any]]:
    url = f"{BASE}/{pid}/arquivos"
    r = SESSION.get(url, timeout=60)
    if not r.ok:
        return []
    return r.json().get("dados", []) or []

def escolher_url_pdf(detalhe: Dict[str, Any]) -> Optional[str]:
    # 1) tenta o campo direto do detalhe
    url = detalhe.get("urlInteiroTeor")
    if url and isinstance(url, str) and url.strip():
        return url

    # 2) cai para /arquivos e procura PDF
    arquivos = listar_arquivos(int(detalhe["id"]))
    # candidatos por campo
    campos = ("urlDownload", "urlInteiroTeor", "url")
    for arq in arquivos:
        # heurística de PDF
        eh_pdf = (
            (arq.get("formato") or "").lower() == "pdf" or
            str(arq.get("nome") or "").lower().endswith(".pdf") or
            "pdf" in str(arq.get("titulo") or "").lower()
        )
        if not eh_pdf:
            continue
        for c in campos:
            link = arq.get(c)
            if link and isinstance(link, str) and link.strip():
                return link
    # se nada der certo, tenta a 1ª URL que exista
    for arq in arquivos:
        for c in campos:
            link = arq.get(c)
            if link and isinstance(link, str) and link.strip():
                return link
    return None

# ---------- 3) Download robusto ----------
def baixar_pdf(pid: int, url: str, outdir: str = "inteiro_teor") -> bool:
    Path(outdir).mkdir(parents=True, exist_ok=True)
    destino = Path(outdir) / f"{pid}.pdf"
    try:
        with SESSION.get(url, stream=True, timeout=120, headers={"Accept": "*/*"}) as r:
            r.raise_for_status()
            # checa Content-Type quando possível
            ctype = (r.headers.get("Content-Type") or "").lower()
            if "pdf" not in ctype and not str(url).lower().endswith(".pdf"):
                # alguns endpoints servem PDF com content-type genérico; ainda assim,
                # se não for óbvio PDF, salvamos assim mesmo mas com .pdf (a maioria é PDF de fato).
                pass
            with open(destino, "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        # tamanho mínimo pra considerar válido
        if destino.exists() and destino.stat().st_size > 1024:
            return True
    except Exception:
        return False
    return False

# ---------- 4) Leitura de PDF (opcional; igual ao seu) ----------
# (deixei igual; se precisar eu troco por pdfminer.six/PyPDF2 como antes)

# ---------- 5) Main ----------
def main():
    print(">> Listando proposições (PL, 2025)...")
    df_simples = listar_proposicoes("PL", 2025, itens=100)
    print(df_simples.head())
    print(f"Total retornado: {len(df_simples)}")

    print(">> Buscando detalhes...")
    detalhes = []
    for pid in df_simples["id"].tolist():
        time.sleep(0.1)
        d = obter_proposicao_detalhe(int(pid))
        if d:
            detalhes.append(d)
    df = pd.DataFrame(detalhes)
    print(df.head())
    print(f"Detalhes coletados: {len(df)}")

    print(">> Resolvendo URLs de inteiro teor (com fallback /arquivos)...")
    df["url_pdf"] = df.apply(escolher_url_pdf, axis=1)
    tem_url = df["url_pdf"].notna().sum()
    print(f"Proposições com URL para download: {tem_url}/{len(df)}")

    print(">> Baixando PDFs...")
    ok = 0
    for _, row in df.iterrows():
        if not row["url_pdf"]:
            continue
        time.sleep(0.15)  # cortesia com a API/servidor
        if baixar_pdf(int(row["id"]), row["url_pdf"], outdir="inteiro_teor"):
            ok += 1
    print(f"Arquivos PDF baixados: {ok}")

if __name__ == "__main__":
    # NLTK stopwords só se você for usar a parte de NLP depois
    try:
        _ = stopwords.words("portuguese")
    except LookupError:
        nltk.download("stopwords")
    main()
