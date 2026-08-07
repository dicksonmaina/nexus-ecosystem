import json
from datetime import datetime
from pathlib import Path
import subprocess, sys, hashlib, concurrent.futures

# ── Paths ────────────────────────────────────────────────────────────────
DRIVE_PATH = "/mnt/bootcamp"
DOCS_DIR   = f"{DRIVE_PATH}/documents"
DB_DIR     = f"{DRIVE_PATH}/database"
MANIFEST   = f"{DRIVE_PATH}/nexus_manifest.json"

OLLAMA_URL   = "http://localhost:11434/api/embeddings"
OLLAMA_MODEL = "nomic-embed-text"
CHROMA_DB    = "/home/riziki/bootcamp-db/chroma"  # heavy DB on internal SSD


# ── Embedder ─────────────────────────────────────────────────────────────
class OllamaEmbed:
    def _one(self, text: str) -> list[float]:
        import urllib.request, json
        req = urllib.request.Request(
            OLLAMA_URL,
            data=json.dumps({"model": OLLAMA_MODEL, "prompt": text[:6000]}).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = json.loads(resp.read())
        if "error" in body:
            raise RuntimeError(body["error"])
        return body["embedding"]

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            return list(pool.map(self._one, texts))

    def embed_query(self, text: str) -> list[float]:
        return self._one(text)


# ── Main ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import os
    from langchain_community.document_loaders import DirectoryLoader, TextLoader
    from langchain_text_splitters                import RecursiveCharacterTextSplitter
    from langchain_community.vectorstores         import Chroma

    os.makedirs(DB_DIR, exist_ok=True)

    print("═" * 50)
    print("🚀  NEXUS  –  BOOTCAMP Ingestor")
    print(f"   Documents → {DOCS_DIR}")
    print(f"   Database  → {CHROMA_DB}")
    print("═" * 50)

    # Read state
    docs = DirectoryLoader(DOCS_DIR, glob="**/*", loader_cls=TextLoader).load()
    print(f"📄  Loaded  {len(docs)} file(s)")

    chunks = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50) \
                 .split_documents(docs)
    print(f"✂️   {len(chunks)} chunks")

    # Embed + index
    emb = OllamaEmbed()
    db  = Chroma.from_documents(chunks, emb, persist_directory=CHROMA_DB)

    manifest = {
        "drive":      DRIVE_PATH,
        "docs_dir":   DOCS_DIR,
        "db_path":    CHROMA_DB,
        "embed_model":OLLAMA_MODEL,
        "embed_dim":  768,
        "num_docs":   len(docs),
        "num_chunks": len(chunks),
        "updated":    datetime.now().isoformat(),
    }
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"✅  Indexed {len(chunks)} chunks  →  {CHROMA_DB}")
    print(f"📋  Manifest  →  {MANIFEST}")

    # ── Query test ──────────────────────────────────────────────────────
    print("\n🔍  — Query Tests —")
    for query in [
        "nexus project status",
        "poultry chicken farm",
        "jarvis telegram ai assistant",
        "career ops pipeline",
        "what is the RICHIE system",
    ]:
        results = db.similarity_search(query, k=1)
        snippet = results[0].page_content[:130].replace("\n", " ") if results else "—"
        print(f"   {query!r:<35} → {snippet}")

    print("\n🧠 NEXUS is ready on the BOOTCAMP drive.\n")
