#!/usr/bin/env python3
"""Gera assets/tema.svg do boaz (estilo + catálogo visual dos diagramas).

Uso: python3 scripts/gerar-tema.py [saida.svg]   (padrão: assets/tema.svg)

O tema.svg é gerado: para mudar o visual, edite este script e rode de novo.
Os ícones de provedor da seção 5 são lidos de assets/icones/ e embutidos.
"""
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1] if len(sys.argv) > 1 else f"{ROOT}/assets/tema.svg"
ICONS = f"{ROOT}/assets/icones"
W, H = 1280, 3296

# ───────────────────────────── estilo ─────────────────────────────
STYLE = """
    /* ── base ─────────────────────────────────────────── */
    .bg            { fill: #0d1117; }
    text           { font-family: Inter, "Segoe UI", Roboto, "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 13px; fill: #e6edf3; }
    .title         { font-size: 22px; font-weight: 700; fill: #f0f6fc; }
    .subtitle      { font-size: 13px; fill: #8b949e; }
    .section       { font-size: 12px; font-weight: 700; letter-spacing: 0.12em; fill: #58a6ff; }
    .label         { font-size: 13px; fill: #e6edf3; }
    .label-strong  { font-size: 14px; font-weight: 600; fill: #f0f6fc; }
    .label-underline { text-decoration: underline; }
    .muted         { font-size: 12px; fill: #8b949e; }
    .mono          { font-family: "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace; font-size: 12px; fill: #8b949e; }
    .divider       { stroke: #21262d; stroke-width: 1; }
    .panel         { fill: #10151c; stroke: #21262d; stroke-width: 1; }

    /* ── nós: uma cor por papel, no máximo 4 por diagrama ── */
    .node          { fill: #161b22; stroke: #30363d; stroke-width: 1.5; }
    .node-face     { fill: #21262d; stroke: #30363d; stroke-width: 1.5; stroke-linejoin: round; }
    .node-blue     { fill: #0c2d4a; stroke: #58a6ff; stroke-width: 1.5; }
    .node-green    { fill: #0f2e1b; stroke: #3fb950; stroke-width: 1.5; }
    .node-purple   { fill: #271a45; stroke: #bc8cff; stroke-width: 1.5; }
    .node-orange   { fill: #3a2410; stroke: #f0883e; stroke-width: 1.5; }
    .node-red      { fill: #3b1219; stroke: #f85149; stroke-width: 1.5; }
    .node-external { fill: #1c2128; stroke: #6e7681; stroke-width: 1.5; }

    /* ── fronteiras (conta, região, rede, módulo) ─────── */
    .boundary       { fill: #161b22; fill-opacity: 0.35; stroke: #484f58; stroke-width: 1.2; stroke-dasharray: 6 4; }
    .boundary-label { font-size: 11px; font-weight: 600; letter-spacing: 0.08em; fill: #8b949e; }

    /* ── arestas e comunicação ─────────────────────────── */
    .edge          { fill: none; stroke: #8b949e; stroke-width: 1.5; }
    .edge-accent   { fill: none; stroke: #58a6ff; stroke-width: 1.8; }
    .edge-async    { stroke-dasharray: 6 4; }
    .edge-data     { stroke-dasharray: 1 5; stroke-linecap: round; stroke-width: 2.2; }
    .edge-label-bg { fill: #0d1117; }
    .arrow-head    { fill: #8b949e; }
    .arrow-accent  { fill: #58a6ff; }
    .lifeline      { stroke: #30363d; stroke-width: 1.2; stroke-dasharray: 4 4; }
    .chip          { fill: #21262d; stroke: #30363d; stroke-width: 1; }
    .chip-text     { font-family: "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace; font-size: 11px; fill: #c9d1d9; }

    /* ── ícones neutros (#ic-*, #uml-*) ───────────────── */
    .ico           { fill: none; stroke: #c9d1d9; stroke-width: 1.5; stroke-linecap: round; stroke-linejoin: round; }
    .ico-fill      { fill: #c9d1d9; }
    .ico-solid     { fill: #161b22; stroke: #c9d1d9; stroke-width: 1.5; stroke-linejoin: round; }

    /* ── notação UML ───────────────────────────────────── */
    .ink           { fill: #e6edf3; }
    .ink-ring      { fill: none; stroke: #e6edf3; stroke-width: 1.5; }
    .node-note     { fill: #2b2311; stroke: #d29922; stroke-width: 1.2; }
    .uml-keyword   { font-size: 11px; font-style: italic; fill: #8b949e; }
    .activation    { fill: #21262d; stroke: #8b949e; stroke-width: 1.2; }
    .frame-tag     { fill: #21262d; stroke: #484f58; stroke-width: 1.2; }
    .frame-op      { font-size: 11px; font-weight: 700; fill: #c9d1d9; }
    .arrow-open    { fill: none; stroke: #8b949e; stroke-width: 1.4; stroke-linejoin: round; }
    .arrow-hollow  { fill: #0d1117; stroke: #8b949e; stroke-width: 1.2; stroke-linejoin: round; }

    /* ── legenda e rodapé ─────────────────────────────── */
    .legend-box    { fill: #161b22; stroke: #30363d; stroke-width: 1; }
    .footer        { font-size: 12px; fill: #6e7681; }
"""

MARKERS = """
    <!-- ── markers e filtro: copie sempre ─────────────── -->
    <marker id="seta" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" class="arrow-head"/>
    </marker>
    <marker id="seta-destaque" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" class="arrow-accent"/>
    </marker>
    <marker id="seta-aberta" viewBox="-1 -1 12 12" refX="10" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10" class="arrow-open"/>
    </marker>
    <marker id="heranca" viewBox="-1 -1 14 14" refX="12" refY="6" markerWidth="10" markerHeight="10" orient="auto-start-reverse">
      <path d="M0,0 L12,6 L0,12 z" class="arrow-hollow"/>
    </marker>
    <marker id="extensao" viewBox="-1 -1 14 14" refX="12" refY="6" markerWidth="10" markerHeight="10" orient="auto-start-reverse">
      <path d="M0,0 L12,6 L0,12 z" class="arrow-head"/>
    </marker>
    <marker id="composicao" viewBox="-1 -1 16 10" refX="14" refY="4" markerWidth="16" markerHeight="11" orient="auto-start-reverse">
      <path d="M0,4 L7,0 L14,4 L7,8 z" class="arrow-head"/>
    </marker>
    <marker id="agregacao" viewBox="-1 -1 16 10" refX="14" refY="4" markerWidth="16" markerHeight="11" orient="auto-start-reverse">
      <path d="M0,4 L7,0 L14,4 L7,8 z" class="arrow-hollow"/>
    </marker>
    <marker id="er-um" viewBox="0 0 16 12" refX="16" refY="6" markerWidth="16" markerHeight="12" markerUnits="userSpaceOnUse" orient="auto-start-reverse">
      <path d="M6,0 V12 M10,0 V12" class="arrow-open"/>
    </marker>
    <marker id="er-muitos" viewBox="0 0 16 12" refX="16" refY="6" markerWidth="16" markerHeight="12" markerUnits="userSpaceOnUse" orient="auto-start-reverse">
      <path d="M4,0 V12 M6,6 L16,0 M6,6 L16,12" class="arrow-open"/>
    </marker>
    <filter id="sombra" x="-10%" y="-10%" width="120%" height="140%">
      <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="#000000" flood-opacity="0.45"/>
    </filter>
"""


def heptagon():
    pts, spokes = [], []
    for i in range(7):
        a = -math.pi / 2 + i * 2 * math.pi / 7
        pts.append(f"{12 + 10 * math.cos(a):.2f},{12 + 10 * math.sin(a):.2f}")
        spokes.append(f"M{12 + 3 * math.cos(a):.2f},{12 + 3 * math.sin(a):.2f} L{12 + 7 * math.cos(a):.2f},{12 + 7 * math.sin(a):.2f}")
    return f'<polygon class="ico" points="{" ".join(pts)}"/><circle class="ico" cx="12" cy="12" r="3"/><path class="ico" d="{" ".join(spokes)}"/>'


# (id, nome, conteúdo 24×24)
NEUTRAL = [
    ("ic-ator", "Ator / usuário",
     '<circle class="ico" cx="12" cy="8" r="4"/><path class="ico" d="M4,21 C4,16.5 7.6,14 12,14 C16.4,14 20,16.5 20,21"/>'),
    ("ic-web", "Navegador / web",
     '<rect class="ico" x="2" y="4" width="20" height="16" rx="2"/><path class="ico" d="M2,9 H22"/>'
     '<circle class="ico-fill" cx="5" cy="6.5" r="0.9"/><circle class="ico-fill" cx="7.8" cy="6.5" r="0.9"/>'),
    ("ic-mobile", "App mobile",
     '<rect class="ico" x="6" y="2" width="12" height="20" rx="2"/><path class="ico" d="M10.5,18.5 H13.5"/>'),
    ("ic-servico", "Serviço / API",
     '<rect class="ico" x="3" y="4" width="18" height="7" rx="1.5"/><rect class="ico" x="3" y="13" width="18" height="7" rx="1.5"/>'
     '<circle class="ico-fill" cx="6.5" cy="7.5" r="0.9"/><circle class="ico-fill" cx="6.5" cy="16.5" r="0.9"/>'
     '<path class="ico" d="M10,7.5 H17 M10,16.5 H17"/>'),
    ("ic-conteiner", "Contêiner",
     '<path class="ico" d="M12,2.5 L20.5,7 V17 L12,21.5 L3.5,17 V7 Z M3.5,7 L12,11.5 L20.5,7 M12,11.5 V21.5"/>'),
    ("ic-funcao", "Função serverless",
     '<path class="ico" d="M6,3 C4.3,3 4,4.3 4,6 V10 C4,11 3.2,12 2,12 C3.2,12 4,13 4,14 V18 C4,19.7 4.3,21 6,21'
     ' M18,3 C19.7,3 20,4.3 20,6 V10 C20,11 20.8,12 22,12 C20.8,12 20,13 20,14 V18 C20,19.7 19.7,21 18,21'
     ' M15,6.5 C13.4,6.3 12.6,7 12.3,8.6 L11,16 C10.7,17.6 9.9,18 8.8,17.8 M9.5,10.5 H14.5"/>'),
    ("ic-kubernetes", "Cluster Kubernetes", heptagon()),
    ("ic-vm", "Máquina virtual",
     '<rect class="ico" x="2" y="3" width="20" height="13" rx="1.5"/><rect class="ico" x="6" y="6.5" width="12" height="6" rx="1" stroke-dasharray="2 2"/>'
     '<path class="ico" d="M8,21 H16 M12,16 V21"/>'),
    ("ic-gateway", "API gateway",
     '<rect class="ico" x="8" y="3" width="8" height="18" rx="1.5"/>'
     '<path class="ico" d="M2,9 H6 M18,9 H22 M20.5,7.5 L22,9 L20.5,10.5 M2,15 H6 M18,15 H22 M20.5,13.5 L22,15 L20.5,16.5"/>'),
    ("ic-balanceador", "Balanceador",
     '<circle class="ico" cx="5" cy="12" r="2.5"/><circle class="ico" cx="19" cy="5" r="2.5"/><circle class="ico" cx="19" cy="12" r="2.5"/>'
     '<circle class="ico" cx="19" cy="19" r="2.5"/><path class="ico" d="M7.5,12 H16.5 M7.2,10.8 L16.6,6 M7.2,13.2 L16.6,18"/>'),
    ("ic-cdn", "CDN",
     '<circle class="ico" cx="12" cy="12" r="9"/><ellipse class="ico" cx="12" cy="12" rx="4" ry="9"/>'
     '<path class="ico" d="M3,12 H21 M4.5,7.5 H19.5 M4.5,16.5 H19.5"/>'),
    ("ic-dns", "DNS",
     '<rect class="ico" x="9" y="2.5" width="6" height="5" rx="1"/><rect class="ico" x="2" y="16.5" width="6" height="5" rx="1"/>'
     '<rect class="ico" x="9" y="16.5" width="6" height="5" rx="1"/><rect class="ico" x="16" y="16.5" width="6" height="5" rx="1"/>'
     '<path class="ico" d="M12,7.5 V16.5 M5,16.5 V12 H19 V16.5"/>'),
    ("ic-banco-sql", "Banco relacional",
     '<ellipse class="ico" cx="12" cy="5.5" rx="8" ry="3"/>'
     '<path class="ico" d="M4,5.5 V18.5 C4,20.2 7.6,21.5 12,21.5 C16.4,21.5 20,20.2 20,18.5 V5.5 M4,12 C4,13.7 7.6,15 12,15 C16.4,15 20,13.7 20,12"/>'),
    ("ic-banco-nosql", "Banco NoSQL",
     '<rect class="ico" x="7" y="2" width="14" height="16" rx="1.5"/><path class="ico" d="M4,6 V20.5 C4,21.3 4.7,22 5.5,22 H16 M10,7 H18 M10,10.5 H18 M10,14 H15"/>'),
    ("ic-cache", "Cache",
     '<rect class="ico" x="5" y="5" width="14" height="14" rx="2"/>'
     '<path class="ico" d="M9,2 V5 M15,2 V5 M9,19 V22 M15,19 V22 M2,9 H5 M2,15 H5 M19,9 H22 M19,15 H22"/>'
     '<path class="ico-fill" d="M13,7.5 L9.5,12.6 H12 L11,16.5 L14.5,11.4 H12 Z"/>'),
    ("ic-objetos", "Objetos (bucket)",
     '<ellipse class="ico" cx="12" cy="6" rx="8.5" ry="2.8"/><path class="ico" d="M3.5,6 L6,20 C6.3,21.2 8.8,22 12,22 C15.2,22 17.7,21.2 18,20 L20.5,6"/>'),
    ("ic-fila", "Fila de mensagens",
     '<rect class="ico" x="2" y="7" width="20" height="10" rx="1.5"/><path class="ico" d="M7.5,7 V17 M12,7 V17 M16.5,7 V17"/>'),
    ("ic-eventos", "Eventos / tópico",
     '<circle class="ico-fill" cx="12" cy="12" r="2.5"/>'
     '<path class="ico" d="M7.5,7.5 A6.4,6.4 0 0 0 7.5,16.5 M16.5,7.5 A6.4,6.4 0 0 1 16.5,16.5 M4.5,4.5 A10.6,10.6 0 0 0 4.5,19.5 M19.5,4.5 A10.6,10.6 0 0 1 19.5,19.5"/>'),
    ("ic-identidade", "Identidade",
     '<rect class="ico" x="3" y="4" width="18" height="16" rx="2"/><circle class="ico" cx="9" cy="10.5" r="2.5"/>'
     '<path class="ico" d="M5.5,17 C6,15.2 7.3,14.5 9,14.5 C10.7,14.5 12,15.2 12.5,17 M15,10 H18.5 M15,13.5 H18.5"/>'),
    ("ic-segredos", "Cofre de segredos",
     '<rect class="ico" x="5" y="10.5" width="14" height="11" rx="2"/>'
     '<path class="ico" d="M8,10.5 V7.5 C8,5 9.8,3 12,3 C14.2,3 16,5 16,7.5 V10.5 M12,16.6 V18.5"/><circle class="ico" cx="12" cy="15.2" r="1.4"/>'),
    ("ic-observabilidade", "Observabilidade",
     '<rect class="ico" x="2.5" y="3.5" width="19" height="17" rx="2"/><polyline class="ico" points="5,14 8.5,14 10.5,8.5 13.5,17 15.5,11.5 19,11.5"/>'),
    ("ic-dw", "Data warehouse",
     '<path class="ico" d="M3,21 V9 L12,3.5 L21,9 V21 Z M7,21 V13 H17 V21 M7,17 H17 M12,13 V21"/>'),
    ("ic-registro", "Registro de imagens",
     '<path class="ico" d="M12,3 L21,7.5 L12,12 L3,7.5 Z M3,12 L12,16.5 L21,12 M3,16.5 L12,21 L21,16.5"/>'),
    ("ic-externo", "Sistema externo",
     '<path class="ico" d="M14,4 H20 V10 M20,4 L11,13 M18,14 V19 C18,19.6 17.6,20 17,20 H5 C4.4,20 4,19.6 4,19 V7 C4,6.4 4.4,6 5,6 H10"/>'),
]

UML_SYMBOLS = [
    ("uml-ator", "0 0 24 40",
     '<circle class="ink-ring" cx="12" cy="6" r="5"/><path class="ico" d="M12,11 V26 M3,16 H21 M12,26 L4,37 M12,26 L20,37"/>'),
    ("uml-componente", "0 0 24 24",
     '<rect class="ico" x="6" y="3" width="15" height="18" rx="1"/><rect class="ico-solid" x="3" y="6.5" width="6" height="4"/>'
     '<rect class="ico-solid" x="3" y="13.5" width="6" height="4"/>'),
    ("uml-artefato", "0 0 24 24",
     '<path class="ico" d="M5,2.5 H14 L19,7.5 V21.5 H5 Z M14,2.5 V7.5 H19"/>'),
]

# (termo neutro, ícone neutro, [(provedor, arquivo, nome do produto)])
PROVIDERS = [
    ("Função serverless", "ic-funcao", [
        ("aws/servicos/compute/aws-lambda.svg", "Lambda"),
        ("azure/compute/function-apps.svg", "Functions"),
        ("gcp/legado/cloud-functions.svg", "Cloud Functions")]),
    ("Kubernetes gerenciado", "ic-kubernetes", [
        ("aws/servicos/containers/amazon-elastic-kubernetes-service.svg", "EKS"),
        ("azure/containers/kubernetes-services.svg", "AKS"),
        ("gcp/produtos/gke.svg", "GKE")]),
    ("Banco relacional", "ic-banco-sql", [
        ("aws/servicos/database/amazon-rds.svg", "RDS"),
        ("azure/databases/sql-database.svg", "SQL Database"),
        ("gcp/produtos/cloud-sql.svg", "Cloud SQL")]),
    ("Armaz. de objetos", "ic-objetos", [
        ("aws/servicos/storage/amazon-simple-storage-service.svg", "S3"),
        ("azure/storage/storage-accounts.svg", "Blob Storage"),
        ("gcp/produtos/cloud-storage.svg", "Cloud Storage")]),
    ("Fila / pub-sub", "ic-fila", [
        ("aws/servicos/app-integration/amazon-simple-queue-service.svg", "SQS"),
        ("azure/integration/azure-service-bus.svg", "Service Bus"),
        ("gcp/legado/pubsub.svg", "Pub/Sub")]),
    ("Rede privada", "ic-dns", [
        ("aws/servicos/networking-content-delivery/amazon-virtual-private-cloud.svg", "VPC"),
        ("azure/networking/virtual-networks.svg", "VNet"),
        ("gcp/legado/virtual-private-cloud.svg", "VPC")]),
]
# rede privada não tem ícone próprio: usa a fronteira tracejada
PROVIDERS[5] = ("Rede privada", None, PROVIDERS[5][2])


# ─────────────────────── embutir ícone oficial ───────────────────────
def local(tag):
    return tag.split("}", 1)[-1]


def embed_icon(path, sym_id):
    tree = ET.parse(f"{ICONS}/{path}")
    root = tree.getroot()
    vb = root.get("viewBox") or f"0 0 {root.get('width').rstrip('px')} {root.get('height').rstrip('px')}"
    css = {}
    for st in root.iter():
        if local(st.tag) == "style" and st.text:
            for sel, body in re.findall(r"\.([\w-]+)\s*\{([^}]*)\}", st.text):
                decl = {}
                for d in body.split(";"):
                    if ":" in d:
                        k, v = d.split(":", 1)
                        decl[k.strip()] = v.strip()
                css.setdefault(sel, {}).update(decl)
    ids = {}
    for el in root.iter():
        if el.get("id") and el is not root:
            ids[el.get("id")] = f"{sym_id}-{len(ids) + 1}"

    def fix(v):
        v = re.sub(r"url\(#([^)]+)\)", lambda m: f"url(#{ids.get(m.group(1), m.group(1))})", v)
        if v.startswith("#") and v[1:] in ids:
            v = "#" + ids[v[1:]]
        return v

    def ser(el):
        tag = local(el.tag)
        if tag in ("title", "desc", "metadata", "style", "script", "foreignObject"):
            return ""
        attrs = {}
        for cls in (el.get("class") or "").split():
            attrs.update(css.get(cls, {}))
        for k, v in el.attrib.items():
            k = local(k)
            if k in ("class", "data-name") or k.startswith("on"):
                continue
            if k == "id":
                v = ids[v]
            attrs[k] = fix(v)
        a = "".join(f' {k}="{v}"' for k, v in attrs.items())
        kids = "".join(ser(c) for c in el)
        if tag == "defs" and not kids:
            return ""
        return f"<{tag}{a}>{kids}</{tag}>" if kids else f"<{tag}{a}/>"

    body = "".join(ser(c) for c in root)
    return f'    <symbol id="{sym_id}" viewBox="{vb}">{body}</symbol>\n'


# ─────────────────────────── helpers ───────────────────────────
out = []


def add(s):
    out.append(s)


def t(x, y, s, cls="label", anchor=None, extra=""):
    a = f' text-anchor="{anchor}"' if anchor else ""
    return f'<text class="{cls}" x="{x}" y="{y}"{a}{extra}>{s}</text>'


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def chip(x, y, s):
    w = round(len(s) * 6.7 + 16)
    return (f'<rect class="chip" x="{x}" y="{y}" width="{w}" height="20" rx="10"/>'
            + t(x + w / 2, y + 14, esc(s), "chip-text", "middle")), w


def section(y, label, sub=None):
    s = t(40, y, label, "section")
    if sub:
        s += t(40, y + 20, sub, "muted")
    return s


def node(x, y, w, h, cls, name, tech, icon=None, gid=None):
    g = f'<g id="{gid}" filter="url(#sombra)">' if gid else '<g filter="url(#sombra)">'
    g += f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="10"/>'
    if icon:
        g += f'<use href="#{icon}" x="{x + 16}" y="{y + (h - 24) / 2:g}" width="24" height="24"/>'
        tx = x + 52
        g += t(tx, y + h / 2 - 3, name, "label-strong") + t(tx, y + h / 2 + 15, esc(tech), "mono")
    else:
        g += t(x + w / 2, y + h / 2 - 3, name, "label-strong", "middle") + t(x + w / 2, y + h / 2 + 15, esc(tech), "mono", "middle")
    return g + "</g>"


# ─────────────────────────── documento ───────────────────────────
defs_symbols = ""
for sid, _, body in NEUTRAL:
    defs_symbols += f'    <symbol id="{sid}" viewBox="0 0 24 24">{body}</symbol>\n'
for sid, vb, body in UML_SYMBOLS:
    defs_symbols += f'    <symbol id="{sid}" viewBox="{vb}">{body}</symbol>\n'
prov_symbols = ""
for _, _, cells in PROVIDERS:
    for path, _ in cells:
        sid = "prov-" + path.split("/")[0] + "-" + path.rsplit("/", 1)[1][:-4]
        prov_symbols += embed_icon(path, sid)

add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
add('  <title>Tema dos diagramas</title>')
add('  <desc>Tema dark padrão do boaz e catálogo visual. As skills de diagrama copiam o bloco style e, de defs, os markers e o filtro '
    'sem alterações; dos symbol (#ic-* formas neutras, #uml-* notação, #prov-* ícones oficiais de exemplo) copiam só os que usarem. '
    'v01: criação. v02: comunicação, formas neutras de arquitetura, provedores e catálogo UML por tipo de diagrama.</desc>')
add(f"  <style>{STYLE}  </style>")
add("  <defs>" + MARKERS)
add("    <!-- ── formas neutras de arquitetura e notação UML: copie só as usadas ── -->")
add(defs_symbols.rstrip("\n"))
add("    <!-- ── ícones oficiais (exemplo de embutir de icones/): copie só os usados ── -->")
add(prov_symbols.rstrip("\n"))
add("  </defs>\n")
add(f'  <rect class="bg" x="0" y="0" width="{W}" height="{H}"/>\n')

# cabeçalho
add('  <g id="cabecalho">')
add("    " + t(40, 56, "Tema dos diagramas", "title"))
add("    " + t(40, 80, "Referência visual e catálogo do boaz — copie o style e os markers de defs para cada SVG; dos symbol, só os que usar", "subtitle"))
add(f'    <line class="divider" x1="40" y1="100" x2="{W - 40}" y2="100"/>')
add("  </g>\n")

# ── 1. base ──
y0 = 140
add('  <g id="base">')
add("    " + section(y0, "1 · CORES POR PAPEL E TIPOGRAFIA"))
roles = [("node", "Neutro"), ("node-blue", "Projeto"), ("node-green", "Dados"), ("node-purple", "Mensageria"),
         ("node-orange", "Atenção"), ("node-red", "Erro / risco"), ("node-external", "Externo"), ("node-note", "Nota")]
for i, (cls, role) in enumerate(roles):
    x = 40 + i * 152
    add(f'    <rect class="{cls}" x="{x}" y="{y0 + 16}" width="136" height="56" rx="10"/>')
    add("    " + t(x + 16, y0 + 40, role, "label-strong") + t(x + 16, y0 + 60, cls, "mono"))
typo = [("title", "Título"), ("label-strong", "Nome do nó"), ("label", "Texto"), ("muted", "rótulo · detalhe"),
        ("mono", "[tecnologia]"), ("uml-keyword", "«estereótipo»"), ("boundary-label", "FRONTEIRA"), ("section", "SEÇÃO")]
for i, (cls, s) in enumerate(typo):
    x = 40 + i * 152
    add("    " + t(x, y0 + 124, s, cls) + t(x, y0 + 148, "." + cls, "footer"))
add("  </g>\n")

# ── 2. comunicação ──
y0 = 340
add('  <g id="comunicacao">')
add("    " + section(y0, "2 · COMUNICAÇÃO", "Cada aresta diz o que trafega e o protocolo, acima da linha: pedidos · HTTPS/JSON"))
edges = [
    ("Síncrono principal", "HTTPS · gRPC", "edge-accent", "seta-destaque", None, ["edge-accent", "#seta-destaque"]),
    ("Síncrono", "REST · SQL · TCP", "edge", "seta", None, ["edge", "#seta"]),
    ("Resposta / retorno", "200 OK · callback", "edge edge-async", "seta-aberta", None, ["edge edge-async", "#seta-aberta"]),
    ("Assíncrono / evento", "AMQP · Kafka · MQTT", "edge edge-async", "seta", None, ["edge edge-async", "#seta"]),
    ("Bidirecional / stream", "WebSocket · gRPC stream", "edge", "seta", "seta", ["edge", "#seta nas 2 pontas"]),
    ("Dados / lote", "ETL · réplica · backup", "edge edge-data", "seta", None, ["edge edge-data", "#seta"]),
]
for i, (name, ex, cls, me, ms, mono) in enumerate(edges):
    x = 40 + i * 200
    ms_attr = f' marker-start="url(#{ms})"' if ms else ""
    add(f'    <line class="{cls}" x1="{x + 2}" y1="{y0 + 52}" x2="{x + 168}" y2="{y0 + 52}" marker-end="url(#{me})"{ms_attr}/>')
    add("    " + t(x, y0 + 80, name, "label-strong") + t(x, y0 + 98, ex, "muted"))
    add("    " + t(x, y0 + 118, mono[0], "mono") + t(x, y0 + 134, mono[1], "mono"))
add("    " + t(40, y0 + 172, "Protocolo como chip (chip + chip-text):", "muted"))
cx = 270
for p in ["HTTPS", "REST", "gRPC", "GraphQL", "WebSocket", "AMQP", "Kafka", "MQTT", "SQL", "Redis", "SMTP", "SFTP", "OIDC", "Webhook"]:
    s, w = chip(cx, y0 + 158, p)
    add("    " + s)
    cx += w + 8
add("  </g>\n")

# ── 3. formas neutras ──
y0 = 556
add('  <g id="formas-neutras">')
add("    " + section(y0, "3 · FORMAS NEUTRAS DE ARQUITETURA",
                    "symbol #ic-* (24×24, valem para AWS, Azure e GCP) — use com <use href=\"#ic-banco-sql\" width=\"24\" height=\"24\"/> à esquerda do nome".replace("<", "&lt;").replace(">", "&gt;")))
for i, (sid, name, _) in enumerate(NEUTRAL):
    r, c = divmod(i, 8)
    x, y = 40 + c * 152, y0 + 44 + r * 112
    add(f'    <rect class="node" x="{x}" y="{y}" width="48" height="48" rx="10"/>'
        f'<use href="#{sid}" x="{x + 10}" y="{y + 10}" width="28" height="28"/>')
    add("    " + t(x, y + 70, name, "label") + t(x, y + 88, "#" + sid, "mono"))
add("  </g>\n")

# ── 4. exemplo de arquitetura neutra ──
Y = 952
add('  <g id="exemplo-arquitetura">')
add("    " + section(Y, "4 · EXEMPLO — ARQUITETURA NEUTRA DE PROVEDOR",
                    "Fronteiras aninhadas (conta → rede → sub-rede), ícone à esquerda do nome, cor por papel, fluxo principal em destaque"))
Y += 32
# fronteiras
add(f'    <rect class="boundary" x="224" y="{Y + 40}" width="808" height="512" rx="14"/>' + t(242, Y + 64, "CONTA / PROJETO · REGIÃO", "boundary-label"))
add(f'    <rect class="boundary" x="456" y="{Y + 80}" width="560" height="304" rx="14"/>' + t(474, Y + 104, "REDE PRIVADA", "boundary-label"))
add(f'    <rect class="boundary" x="472" y="{Y + 120}" width="528" height="248" rx="14"/>' + t(490, Y + 144, "SUB-REDE PRIVADA", "boundary-label"))
add(f'    <rect class="boundary" x="240" y="{Y + 408}" width="776" height="128" rx="14"/>' + t(258, Y + 432, "SERVIÇOS GERENCIADOS", "boundary-label"))
r1, r2, r3 = Y + 168, Y + 280, Y + 448
add("    " + node(40, r1, 144, 64, "node-external", "Cliente", "[web · app]", "ic-ator", "cliente"))
add("    " + node(248, r1, 184, 64, "node", "API gateway", "[gerenciado]", "ic-gateway", "api-gateway"))
add("    " + node(248, r2, 184, 64, "node", "Identidade", "[OIDC]", "ic-identidade", "identidade"))
add("    " + node(496, r1, 200, 64, "node-blue", "Pedidos", "[contêiner]", "ic-conteiner", "pedidos"))
add("    " + node(496, r2, 200, 64, "node-green", "Banco relacional", "[PostgreSQL]", "ic-banco-sql", "banco"))
add("    " + node(776, r1, 200, 64, "node-purple", "Fila de mensagens", "[AMQP]", "ic-fila", "fila"))
add("    " + node(776, r2, 200, 64, "node-blue", "Notificações", "[serverless]", "ic-funcao", "notificacoes"))
add("    " + node(1072, r2, 168, 64, "node-external", "E-mail", "[SaaS]", "ic-externo", "email"))
add("    " + node(264, r3, 200, 64, "node", "Cofre de segredos", "[gerenciado]", "ic-segredos", "segredos"))
add("    " + node(496, r3, 200, 64, "node", "Observabilidade", "[logs · métricas]", "ic-observabilidade", "observabilidade"))
add("    " + node(776, r3, 200, 64, "node-green", "Objetos", "[armazenamento]", "ic-objetos", "objetos"))
# arestas
add(f'    <line class="edge-accent" x1="184" y1="{r1 + 32}" x2="246" y2="{r1 + 32}" marker-end="url(#seta-destaque)"/>' + t(216, r1 + 24, "HTTPS", "muted", "middle"))
add(f'    <line class="edge-accent" x1="432" y1="{r1 + 32}" x2="494" y2="{r1 + 32}" marker-end="url(#seta-destaque)"/>' + t(464, r1 + 24, "REST", "muted", "middle"))
add(f'    <line class="edge" x1="340" y1="{r1 + 64}" x2="340" y2="{r2 - 2}" marker-end="url(#seta)"/>' + t(348, r1 + 92, "valida token", "muted"))
add(f'    <line class="edge-accent" x1="596" y1="{r1 + 64}" x2="596" y2="{r2 - 2}" marker-end="url(#seta-destaque)"/>' + t(604, r1 + 92, "SQL", "muted"))
add(f'    <line class="edge edge-async" x1="696" y1="{r1 + 32}" x2="774" y2="{r1 + 32}" marker-end="url(#seta)"/>' + t(736, r1 + 24, "evento", "muted", "middle"))
add(f'    <line class="edge edge-async" x1="876" y1="{r1 + 64}" x2="876" y2="{r2 - 2}" marker-end="url(#seta)"/>' + t(884, r1 + 92, "consome", "muted"))
add(f'    <rect class="edge-label-bg" x="1018" y="{r2 + 12}" width="44" height="16"/>')
add(f'    <line class="edge" x1="976" y1="{r2 + 32}" x2="1070" y2="{r2 + 32}" marker-end="url(#seta)"/>' + t(1040, r2 + 24, "HTTPS", "muted", "middle"))
add(f'    <line class="edge edge-data" x1="876" y1="{r2 + 64}" x2="876" y2="{r3 - 2}" marker-end="url(#seta)"/>')
add(f'    <rect class="edge-label-bg" x="882" y="{r2 + 108}" width="52" height="16"/>' + t(886, r2 + 120, "anexos", "muted"))
# legenda
ly = Y + 384
add(f'    <rect class="legend-box" x="1072" y="{ly}" width="168" height="168" rx="10"/>' + t(1088, ly + 26, "Legenda", "label-strong"))
for i, (cls, s) in enumerate([("node-blue", "Projeto"), ("node-green", "Dados"), ("node-purple", "Mensageria"), ("node", "Gerenciado"), ("node-external", "Externo")]):
    add(f'    <rect class="{cls}" x="1088" y="{ly + 42 + i * 24}" width="14" height="14" rx="3"/>' + t(1112, ly + 54 + i * 24, s, "label"))
add("  </g>\n")

# ── 5. provedores ──
y0 = 1576
add('  <g id="provedores">')
add("    " + section(y0, "5 · COM PROVEDOR FIXADO",
                    "Só quando o pedido nomeia o provedor: troque a forma neutra pelo ícone oficial de icones/&lt;provedor&gt;/ (symbol #prov-*)"))
for col in range(2):
    x0 = 40 + col * 608
    hy = y0 + 56
    add("    " + t(x0, hy, "NEUTRO", "boundary-label") + t(x0 + 272, hy, "AWS", "boundary-label", "middle")
        + t(x0 + 400, hy, "AZURE", "boundary-label", "middle") + t(x0 + 528, hy, "GCP", "boundary-label", "middle"))
    for r in range(3):
        name, ic, cells = PROVIDERS[col * 3 + r]
        ry = hy + 12 + r * 88
        add(f'    <line class="divider" x1="{x0}" y1="{ry}" x2="{x0 + 592}" y2="{ry}"/>')
        if ic:
            add(f'    <rect class="node" x="{x0}" y="{ry + 20}" width="48" height="48" rx="10"/><use href="#{ic}" x="{x0 + 10}" y="{ry + 30}" width="28" height="28"/>')
        else:
            add(f'    <rect class="boundary" x="{x0}" y="{ry + 20}" width="48" height="48" rx="10"/>')
        add("    " + t(x0 + 64, ry + 49, name, "label-strong"))
        for k, (path, prod) in enumerate(cells):
            cxp = x0 + 272 + k * 128
            sid = "prov-" + path.split("/")[0] + "-" + path.rsplit("/", 1)[1][:-4]
            add(f'    <use href="#{sid}" x="{cxp - 18}" y="{ry + 14}" width="36" height="36"/>' + t(cxp, ry + 72, prod, "muted", "middle"))
    add(f'    <line class="divider" x1="{x0}" y1="{hy + 276}" x2="{x0 + 592}" y2="{hy + 276}"/>')
add("    " + t(40, y0 + 364, "Rede privada não tem forma: é a fronteira tracejada. Com provedor fixado, as fronteiras usam icones/aws/grupos/ (região, VPC, sub-redes).", "muted"))
add("  </g>\n")

# ── 6. UML ──
y0 = 1976
add('  <g id="catalogo-uml">')
add("    " + section(y0, "6 · CATÁLOGO UML 2.5 — ELEMENTOS POR TIPO DE DIAGRAMA",
                    "dev → 2_Diagramas (diagrama-dev) · arq → 3_Arquitetura (diagrama-arquitetura)"))

CW, CH = 288, 280


def card(i, gid, title, skill, lines, body):
    r, c = divmod(i, 4)
    x, y = 40 + c * (CW + 16), y0 + 40 + r * (CH + 16)
    s = f'  <g id="{gid}" transform="translate({x},{y})">\n'
    s += f'    <rect class="panel" x="0" y="0" width="{CW}" height="{CH}" rx="12"/>\n'
    s += "    " + t(16, 28, title, "label-strong") + "\n"
    ch, w = chip(0, 12, skill)
    s += f'    <g transform="translate({CW - 16 - w},0)">{ch}</g>\n'
    s += "    " + body.strip().replace("\n", "\n    ") + "\n"
    s += f'    <line class="divider" x1="16" y1="220" x2="{CW - 16}" y2="220"/>\n'
    for k, ln in enumerate(lines):
        s += "    " + t(16, 242 + k * 18, esc(ln), "muted") + "\n"
    return s + "  </g>"


K = "uml-keyword"
cards = []

cards.append(("uml-classes", "Classes", "dev", ["compartimentos · visibilidade + - # ~", "herança · composição · agregação · 1..*"], f"""
<rect class="node" x="16" y="56" width="120" height="112" rx="4"/>
{t(76, 76, "Pedido", "label-strong", "middle")}
<line class="divider" x1="16" y1="84" x2="136" y2="84"/>
{t(24, 104, "- id: UUID", "mono")}{t(24, 122, "- total: Money", "mono")}
<line class="divider" x1="16" y1="132" x2="136" y2="132"/>
{t(24, 154, "+ fechar()", "mono")}
<rect class="node" x="184" y="56" width="88" height="56" rx="4"/>
{t(228, 76, "Item", "label-strong", "middle")}
<line class="divider" x1="184" y1="84" x2="272" y2="84"/>
{t(192, 104, "qtd: int", "mono")}
<line class="edge" x1="136" y1="70" x2="184" y2="70" marker-start="url(#composicao)"/>
{t(154, 64, "1", "muted")}{t(178, 64, "*", "muted", "end")}
<rect class="node" x="184" y="136" width="88" height="32" rx="4"/>
{t(228, 157, "Assinatura", "label", "middle")}
<line class="edge" x1="184" y1="152" x2="138" y2="152" marker-end="url(#heranca)"/>
{t(16, 196, "«abstract» · «interface» acima do nome", K)}
"""))

cards.append(("uml-objetos", "Objetos", "dev", ["nome sublinhado (label-underline)", "valores em mono · vínculos sem multiplicidade"], f"""
<rect class="node" x="16" y="64" width="120" height="80" rx="4"/>
{t(76, 86, "p1 : Pedido", "label-strong label-underline", "middle")}
<line class="divider" x1="16" y1="96" x2="136" y2="96"/>
{t(26, 116, "id = 42", "mono")}{t(26, 134, "total = 99,90", "mono")}
<rect class="node" x="176" y="64" width="96" height="80" rx="4"/>
{t(224, 86, "i1 : Item", "label-strong label-underline", "middle")}
<line class="divider" x1="176" y1="96" x2="272" y2="96"/>
{t(186, 116, "qtd = 2", "mono")}{t(186, 134, "sku = A7", "mono")}
<line class="edge" x1="136" y1="104" x2="176" y2="104"/>
{t(16, 180, "um instante concreto do diagrama de classes", "muted")}
"""))

cards.append(("uml-pacotes", "Pacotes", "dev", ["pasta com aba · elementos dentro", "«import» / «access» com edge-async"], f"""
<rect class="node" x="16" y="72" width="48" height="14" rx="2"/>
<rect class="node" x="16" y="86" width="96" height="72" rx="2"/>
{t(64, 114, "pedidos", "label-strong", "middle")}{t(64, 136, "Pedido, Item", "mono", "middle")}
<rect class="node" x="176" y="72" width="48" height="14" rx="2"/>
<rect class="node" x="176" y="86" width="96" height="72" rx="2"/>
{t(224, 114, "pagamentos", "label-strong", "middle")}{t(224, 136, "Cobranca", "mono", "middle")}
<line class="edge edge-async" x1="112" y1="122" x2="174" y2="122" marker-end="url(#seta-aberta)"/>
{t(144, 112, "«import»", K, "middle")}
{t(16, 192, "ciclo de dependência → node-red", "muted")}
"""))

cards.append(("uml-componentes", "Componentes", "dev · arq", ["«component» + #uml-componente no canto", "pirulito fornece · soquete requer"], f"""
<g filter="url(#sombra)"><rect class="node-blue" x="16" y="72" width="104" height="72" rx="6"/></g>
<use href="#uml-componente" x="98" y="78" width="16" height="16"/>
{t(64, 104, "«component»", K, "middle")}{t(64, 126, "Pedidos", "label-strong", "middle")}
<g filter="url(#sombra)"><rect class="node-blue" x="184" y="72" width="88" height="72" rx="6"/></g>
<use href="#uml-componente" x="250" y="78" width="16" height="16"/>
{t(224, 104, "«component»", K, "middle")}{t(224, 126, "Checkout", "label-strong", "middle")}
<line class="edge" x1="120" y1="108" x2="140" y2="108"/><circle class="ink-ring" cx="146" cy="108" r="6"/>
<path class="edge" d="M150,98 A10,10 0 0 1 150,118 M160,108 H184"/>
{t(146, 88, "IPedido", "muted", "middle")}
<rect class="node-face" x="58" y="138" width="12" height="12"/>
{t(16, 180, "porta = quadrado na borda", "muted")}
"""))

cards.append(("uml-estrutura-composta", "Estrutura composta", "dev", ["partes nome : Tipo [mult] · portas na borda", "conectores entre partes"], f"""
<rect class="node" x="16" y="52" width="256" height="128" rx="4"/>
{t(144, 74, "Checkout", "label-strong", "middle")}
<rect class="node-blue" x="40" y="96" width="96" height="40" rx="4"/>{t(88, 121, "c : Carrinho", "label", "middle")}
<rect class="node-blue" x="168" y="96" width="88" height="40" rx="4"/>{t(212, 121, "p : Pagador", "label", "middle")}
<line class="edge" x1="136" y1="116" x2="168" y2="116"/>
<rect class="node-face" x="10" y="110" width="12" height="12"/>
<line class="edge" x1="22" y1="116" x2="40" y2="116"/>
{t(28, 164, "porta", "muted")}
<ellipse class="boundary" cx="200" cy="200" rx="56" ry="14"/>{t(200, 204, "colaboração", K, "middle")}
"""))

cards.append(("uml-perfil", "Perfil", "dev", ["«stereotype» estende «metaclass»", "marker #extensao · tagged values em mono"], f"""
<rect class="boundary" x="12" y="48" width="264" height="140" rx="6"/>{t(24, 66, "«profile» Persistencia", K)}
<rect class="node" x="24" y="88" width="88" height="56" rx="4"/>
{t(68, 110, "«metaclass»", K, "middle")}{t(68, 130, "Class", "label-strong", "middle")}
<rect class="node-purple" x="160" y="80" width="104" height="96" rx="4"/>
{t(212, 100, "«stereotype»", K, "middle")}{t(212, 120, "Entidade", "label-strong", "middle")}
<line class="divider" x1="160" y1="132" x2="264" y2="132"/>
{t(168, 152, "tabela: Str", "mono")}{t(168, 168, "schema: Str", "mono")}
<line class="edge" x1="160" y1="116" x2="114" y2="116" marker-end="url(#extensao)"/>
"""))

cards.append(("uml-casos-de-uso", "Casos de uso", "dev", ["boundary do sistema · #uml-ator", "elipses · «include» / «extend» · herança"], f"""
<use href="#uml-ator" x="16" y="74" width="24" height="40"/>{t(28, 132, "Cliente", "muted", "middle")}
<rect class="boundary" x="72" y="48" width="200" height="156" rx="14"/>{t(86, 66, "LOJA", "boundary-label")}
<ellipse class="node" cx="176" cy="96" rx="64" ry="18"/>{t(176, 101, "Comprar", "label", "middle")}
<ellipse class="node" cx="176" cy="170" rx="56" ry="18"/>{t(176, 175, "Pagar", "label", "middle")}
<line class="edge" x1="44" y1="96" x2="112" y2="96"/>
<line class="edge edge-async" x1="176" y1="114" x2="176" y2="150" marker-end="url(#seta-aberta)"/>
{t(184, 136, "«include»", K)}
"""))

cards.append(("uml-atividades", "Atividades", "dev", ["início ink · fim ink-ring + ink · ações", "decisão [guarda] · fork/join · raias"], f"""
<circle class="ink" cx="64" cy="56" r="7"/>
<line class="edge" x1="64" y1="63" x2="64" y2="78" marker-end="url(#seta)"/>
<rect class="node" x="24" y="80" width="80" height="28" rx="10"/>{t(64, 99, "Validar", "label", "middle")}
<line class="edge" x1="64" y1="108" x2="64" y2="122" marker-end="url(#seta)"/>
<path class="node" d="M64,124 L76,136 L64,148 L52,136 z"/>
<line class="edge" x1="76" y1="136" x2="126" y2="136" marker-end="url(#seta)"/>{t(101, 128, "[sim]", "muted", "middle")}
<rect class="node" x="128" y="122" width="80" height="28" rx="10"/>{t(168, 141, "Aprovar", "label", "middle")}
<line class="edge" x1="64" y1="148" x2="64" y2="174" marker-end="url(#seta)"/>{t(70, 166, "[não]", "muted")}
<rect class="node" x="24" y="176" width="80" height="28" rx="10"/>{t(64, 195, "Recusar", "label", "middle")}
<line class="edge" x1="208" y1="136" x2="236" y2="136" marker-end="url(#seta)"/>
<path class="edge" d="M104,190 H248 V148" marker-end="url(#seta)"/>
<circle class="ink-ring" cx="248" cy="136" r="10"/><circle class="ink" cx="248" cy="136" r="6"/>
<rect class="ink" x="176" y="64" width="80" height="6" rx="2"/>{t(216, 88, "fork / join", "muted", "middle")}
"""))

cards.append(("uml-sequencia", "Sequência", "dev", ["lifeline · activation · síncrona #seta", "retorno edge-async · alt/opt/loop em frame"], f"""
<rect class="node" x="16" y="48" width="72" height="28" rx="4"/>{t(52, 67, ":Cliente", "label", "middle")}
<rect class="node" x="108" y="48" width="72" height="28" rx="4"/>{t(144, 67, ":API", "label", "middle")}
<rect class="node" x="200" y="48" width="72" height="28" rx="4"/>{t(236, 67, ":Banco", "label", "middle")}
<line class="lifeline" x1="52" y1="76" x2="52" y2="208"/>
<line class="lifeline" x1="144" y1="76" x2="144" y2="208"/>
<line class="lifeline" x1="236" y1="76" x2="236" y2="208"/>
<rect class="activation" x="139" y="96" width="10" height="92"/>
<rect class="activation" x="231" y="120" width="10" height="36"/>
<line class="edge" x1="52" y1="100" x2="137" y2="100" marker-end="url(#seta)"/>{t(94, 94, "1: criar()", "muted", "middle")}
<line class="edge" x1="149" y1="124" x2="229" y2="124" marker-end="url(#seta)"/>{t(190, 118, "2: salvar()", "muted", "middle")}
<line class="edge edge-async" x1="231" y1="152" x2="151" y2="152" marker-end="url(#seta-aberta)"/>{t(190, 146, "ok", "muted", "middle")}
<line class="edge edge-async" x1="139" y1="184" x2="54" y2="184" marker-end="url(#seta-aberta)"/>{t(96, 178, "201", "muted", "middle")}
"""))

cards.append(("uml-comunicacao", "Comunicação", "dev", ["objetos ligados por vínculos simples", "mensagens numeradas 1:, 1.1: + seta curta"], f"""
<rect class="node" x="16" y="72" width="80" height="32" rx="4"/>{t(56, 93, ":Cliente", "label", "middle")}
<rect class="node" x="176" y="72" width="96" height="32" rx="4"/>{t(224, 93, ":Pedido", "label", "middle")}
<rect class="node" x="176" y="168" width="96" height="32" rx="4"/>{t(224, 189, ":Estoque", "label", "middle")}
<line class="edge" x1="96" y1="88" x2="176" y2="88"/>
<line class="edge" x1="224" y1="104" x2="224" y2="168"/>
{t(136, 66, "1: criar()", "muted", "middle")}
<line class="edge" x1="116" y1="114" x2="154" y2="114" marker-end="url(#seta)"/>
{t(212, 132, "1.1: reservar()", "muted", "end")}
<line class="edge" x1="240" y1="118" x2="240" y2="152" marker-end="url(#seta)"/>
"""))

cards.append(("uml-visao-geral-interacao", "Visão geral de interação", "dev", ["fluxo de atividades com quadros ref", "frame-tag + frame-op · [guardas]"], f"""
<circle class="ink" cx="64" cy="54" r="7"/>
<line class="edge" x1="64" y1="61" x2="64" y2="74" marker-end="url(#seta)"/>
<rect class="node" x="16" y="76" width="96" height="36" rx="2"/>
<path class="frame-tag" d="M16,76 H44 V84 L38,90 H16 Z"/>{t(20, 87, "ref", "frame-op")}{t(72, 104, "Login", "label", "middle")}
<line class="edge" x1="64" y1="112" x2="64" y2="122" marker-end="url(#seta)"/>
<path class="node" d="M64,124 L76,136 L64,148 L52,136 z"/>
<line class="edge" x1="76" y1="136" x2="142" y2="136" marker-end="url(#seta)"/>{t(108, 128, "[ok]", "muted", "middle")}
<rect class="node" x="144" y="118" width="120" height="36" rx="2"/>
<path class="frame-tag" d="M144,118 H172 V126 L166,132 H144 Z"/>{t(148, 129, "ref", "frame-op")}{t(212, 146, "Checkout", "label", "middle")}
<line class="edge" x1="204" y1="154" x2="204" y2="172" marker-end="url(#seta)"/>
<circle class="ink-ring" cx="204" cy="184" r="10"/><circle class="ink" cx="204" cy="184" r="6"/>
<path class="edge" d="M64,148 V184 H192" marker-end="url(#seta)"/>{t(72, 172, "[falha]", "muted")}
"""))

cards.append(("uml-estados", "Estados", "dev", ["estados rx 16 · evento [guarda] / ação", "inicial ink · final ink-ring + ink"], f"""
<circle class="ink" cx="28" cy="96" r="7"/>
<line class="edge" x1="35" y1="96" x2="46" y2="96" marker-end="url(#seta)"/>
<rect class="node" x="48" y="76" width="88" height="40" rx="16"/>{t(92, 101, "Pendente", "label", "middle")}
<line class="edge" x1="136" y1="96" x2="182" y2="96" marker-end="url(#seta)"/>{t(160, 88, "pagar", "muted", "middle")}
<rect class="node-blue" x="184" y="76" width="88" height="40" rx="16"/>{t(228, 101, "Pago", "label", "middle")}
<line class="edge" x1="92" y1="116" x2="92" y2="154" marker-end="url(#seta)"/>{t(100, 140, "cancelar", "muted")}
<rect class="node-red" x="48" y="156" width="88" height="40" rx="16"/>{t(92, 181, "Cancelado", "label", "middle")}
<line class="edge" x1="228" y1="116" x2="228" y2="164" marker-end="url(#seta)"/>{t(220, 144, "entregue", "muted", "end")}
<line class="edge" x1="136" y1="176" x2="216" y2="176" marker-end="url(#seta)"/>
<circle class="ink-ring" cx="228" cy="176" r="10"/><circle class="ink" cx="228" cy="176" r="6"/>
{t(48, 66, "entry/ · do/ · exit/ em mono", "muted")}
"""))

cards.append(("uml-tempo", "Tempo", "dev", ["uma faixa por participante · degraus", "edge-accent · {restrição} entre marcas"], f"""
{t(16, 62, "PEDIDO", "boundary-label")}
{t(92, 84, "pago", "muted", "end")}{t(92, 108, "novo", "muted", "end")}
<path class="edge-accent" d="M100,104 H152 V80 H272"/>
<line class="divider" x1="16" y1="122" x2="272" y2="122"/>
{t(16, 140, "PAGAMENTO", "boundary-label")}
{t(92, 156, "ok", "muted", "end")}{t(92, 180, "aguarda", "muted", "end")}
<path class="edge" d="M100,176 H232 V152 H272"/>
<line class="lifeline" x1="152" y1="80" x2="152" y2="204"/>
<line class="lifeline" x1="232" y1="152" x2="232" y2="204"/>
<line class="edge edge-async" x1="154" y1="196" x2="230" y2="196" marker-start="url(#seta-aberta)" marker-end="url(#seta-aberta)"/>
{t(192, 190, "{≤ 200 ms}", "muted", "middle")}
<line class="edge" x1="100" y1="208" x2="272" y2="208"/>
"""))

cards.append(("uml-implantacao", "Implantação", "arq", ["nó 3D: node + node-face · «device»", "«artifact» · caminho com protocolo"], f"""
<path class="node-face" d="M16,72 L28,60 H148 L136,72 Z"/><path class="node-face" d="M136,72 L148,60 V180 L136,192 Z"/>
<rect class="node" x="16" y="72" width="120" height="120"/>
{t(76, 92, "«device»", K, "middle")}{t(76, 112, "Servidor", "label-strong", "middle")}
<rect class="node-blue" x="28" y="128" width="96" height="48" rx="2"/>
<use href="#uml-artefato" x="104" y="132" width="16" height="16"/>
{t(68, 148, "«artifact»", K, "middle")}{t(68, 166, "api:1.4", "mono", "middle")}
<path class="node-face" d="M184,100 L196,88 H272 L260,100 Z"/><path class="node-face" d="M260,100 L272,88 V152 L260,164 Z"/>
<rect class="node-green" x="184" y="100" width="76" height="64"/>
{t(222, 124, "«device»", K, "middle")}{t(222, 146, "Banco", "label-strong", "middle")}
<line class="edge" x1="148" y1="132" x2="184" y2="132"/>{t(166, 124, "TCP", "muted", "middle")}
"""))

cards.append(("er", "Entidade-relacionamento", "dev", ["tabelas · PK / FK em mono", "#er-um · #er-muitos nas pontas"], f"""
<rect class="node-green" x="16" y="64" width="96" height="88" rx="4"/>
{t(64, 84, "cliente", "label-strong", "middle")}
<line class="divider" x1="16" y1="92" x2="112" y2="92"/>
{t(24, 112, "PK id", "mono")}{t(24, 136, "   nome", "mono")}
<rect class="node-green" x="160" y="64" width="112" height="112" rx="4"/>
{t(216, 84, "pedido", "label-strong", "middle")}
<line class="divider" x1="160" y1="92" x2="272" y2="92"/>
{t(168, 112, "PK id", "mono")}{t(168, 136, "FK cliente_id", "mono")}{t(168, 160, "   total", "mono")}
<path class="edge" d="M112,108 H136 V132 H160" marker-start="url(#er-um)" marker-end="url(#er-muitos)"/>
{t(16, 196, "1 cliente : N pedidos", "muted")}
"""))

cards.append(("c4", "C4 contexto / contêiner", "arq", ["pessoa · sistema node-blue", "externo node-external · arestas rotuladas"], f"""
<g filter="url(#sombra)"><circle class="node-blue" cx="52" cy="64" r="12"/><rect class="node-blue" x="16" y="80" width="72" height="44" rx="16"/></g>
{t(52, 107, "Cliente", "label", "middle")}
<g filter="url(#sombra)"><rect class="node-blue" x="128" y="64" width="144" height="56" rx="10"/></g>
{t(200, 88, "Loja online", "label-strong", "middle")}{t(200, 106, "[sistema]", "mono", "middle")}
<line class="edge-accent" x1="88" y1="100" x2="126" y2="100" marker-end="url(#seta-destaque)"/>{t(107, 92, "usa", "muted", "middle")}
<g filter="url(#sombra)"><rect class="node-external" x="128" y="152" width="144" height="52" rx="10"/></g>
{t(200, 174, "Pagamentos", "label-strong", "middle")}{t(200, 192, "[externo]", "mono", "middle")}
<line class="edge" x1="200" y1="120" x2="200" y2="150" marker-end="url(#seta)"/>{t(192, 140, "HTTPS", "muted", "end")}
"""))

for i, (gid, title, skill, lines, body) in enumerate(cards):
    add(card(i, gid, title, skill, lines, body))
add("  </g>\n")

fy = H - 72
add('  <g id="rodape">')
add(f'    <line class="divider" x1="40" y1="{fy}" x2="{W - 40}" y2="{fy}"/>')
add("    " + t(40, fy + 28, "tema · v02 · referência de estilo e catálogo", "footer"))
add("    " + t(40, fy + 48, "Fundo #0d1117 · fonte sans do sistema · cantos 10px · grade de 8px · no máximo 4 cores de papel por diagrama · ícones 24–32px à esquerda do nome", "footer"))
add("  </g>")
add("</svg>")

open(OUT, "w").write("\n".join(out) + "\n")
print(OUT, sum(len(s) for s in out), "bytes")
