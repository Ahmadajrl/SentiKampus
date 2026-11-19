"""SentiKampus — Web Frontend (Streamlit).

Aplikasi web untuk analisis sentimen masukan mahasiswa.
Semua prediksi dikirim ke FastAPI; model tidak berjalan di sini.

Jalankan:
    set API_BASE_URL=http://127.0.0.1:8000
    streamlit run app.py

Env variable:
    API_BASE_URL — base URL FastAPI (default: http://127.0.0.1:8000)
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

import streamlit as st

# ===========================================================================
# KONFIGURASI
# ===========================================================================
API_BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


# ===========================================================================
# FUNGSI HTTP (tanpa library eksternal, hanya stdlib)
# ===========================================================================
def _post_json(path: str, payload: dict) -> dict:
    """Kirim POST JSON ke API; kembalikan dict response."""
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url=f"{API_BASE_URL}{path}",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=8) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _get_json(path: str) -> dict:
    """Kirim GET ke API; kembalikan dict response."""
    req = urllib.request.Request(url=f"{API_BASE_URL}{path}", method="GET")
    with urllib.request.urlopen(req, timeout=8) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _check_api_health() -> dict | None:
    """Periksa status API; kembalikan dict health atau None jika tidak terhubung."""
    try:
        return _get_json("/health")
    except Exception:
        return None


# ===========================================================================
# KONFIGURASI HALAMAN
# ===========================================================================
st.set_page_config(
    page_title="SentiKampus",
    page_icon="🎓",
    layout="centered",
    initial_sidebar_state="collapsed",
)

# ===========================================================================
# HEADER & STATUS API
# ===========================================================================
st.title("🎓 SentiKampus")
st.caption("Analisis sentimen masukan mahasiswa — Universitas Bina Sarana Informatika")

health = _check_api_health()
if health and health.get("model_loaded"):
    st.success(f"API terhubung · Model: `{health.get('model_version', '?')}`", icon="✅")
else:
    st.warning(
        f"API tidak dapat dihubungi di `{API_BASE_URL}`. "
        "Pastikan server FastAPI sudah berjalan.",
        icon="⚠️",
    )

st.divider()

# ===========================================================================
# INPUT PENGGUNA
# ===========================================================================
col_text, col_opts = st.columns([3, 1])

with col_text:
    text = st.text_area(
        "Masukan mahasiswa",
        value="Pelayanan akademik sangat membantu",
        height=100,
        max_chars=500,
        help="Masukkan satu kalimat masukan mahasiswa (maks. 500 karakter). "
             "Jangan gunakan nama, NIM, atau data pribadi.",
        placeholder="Contoh: Dosen menjelaskan materi dengan sangat jelas",
    )

with col_opts:
    week = st.selectbox(
        "Pertemuan",
        options=list(range(1, 17)),
        index=3,
        help="Nomor pertemuan menentukan fitur yang aktif (mis. XAI mulai P7).",
    )
    include_xai = st.checkbox(
        "Tampilkan XAI",
        value=week >= 7,
        help="Tampilkan kontribusi kata terhadap prediksi. Aktif otomatis mulai P7.",
    )

# Contoh cepat untuk demonstrasi
st.caption("Contoh cepat:")
example_cols = st.columns(3)
examples = [
    ("Positif", "Pelayanan akademik sangat membantu"),
    ("Negatif", "Internet kampus sering terputus"),
    ("Netral", "Kuliah dimulai pukul delapan"),
]
for col, (label, ex) in zip(example_cols, examples):
    if col.button(label, key=f"ex_{label}", use_container_width=True):
        st.session_state["_example_text"] = ex

# Terapkan contoh jika dipilih
if "_example_text" in st.session_state:
    text = st.session_state.pop("_example_text")

st.divider()

# ===========================================================================
# TOMBOL ANALISIS
# ===========================================================================
analyze_btn = st.button(
    "Analisis Sentimen",
    type="primary",
    use_container_width=True,
    disabled=not (health and health.get("model_loaded")),
)

if analyze_btn:
    cleaned = text.strip()
    if len(cleaned) < 3:
        st.warning("Teks minimal tiga karakter bermakna.", icon="⚠️")
    else:
        with st.spinner("Model sedang membaca pola kata …"):
            try:
                result = _post_json(
                    "/api/v1/predict",
                    {
                        "text": cleaned,
                        "week": int(week),
                        "include_explanation": bool(include_xai or week >= 7),
                    },
                )
            except urllib.error.HTTPError as exc:
                st.error(f"API mengembalikan HTTP {exc.code}. Detail: {exc.read().decode()}", icon="🚨")
                result = None
            except urllib.error.URLError:
                st.error(
                    f"Tidak dapat terhubung ke `{API_BASE_URL}`. Pastikan server API sudah berjalan.",
                    icon="🔌",
                )
                result = None
            except (KeyError, TypeError, ValueError) as exc:
                st.error(f"Format respons API tidak sesuai: {exc}", icon="⚠️")
                result = None
            except Exception as exc:
                st.error(f"Prediksi gagal: {exc}", icon="❌")
                result = None

        if result:
            # -----------------------------------------------------------
            # HASIL PREDIKSI
            # -----------------------------------------------------------
            label = result.get("label", "?")
            score = result.get("score", 0.0)
            probs = result.get("probabilities", {})
            explanation = result.get("explanation", [])
            latency = result.get("latency_ms", 0.0)
            capabilities = result.get("capabilities", [])
            trace_id = result.get("trace_id", "-")
            model_ver = result.get("model_version", "?")

            # Warna label
            label_color = {
                "positif": "green",
                "negatif": "red",
                "netral": "orange",
            }.get(label, "gray")

            # Header hasil
            st.markdown(
                f"### Hasil: :{label_color}[**{label.upper()}**]"
            )
            st.progress(score, text=f"Tingkat keyakinan model: **{score * 100:.1f}%**")

            # -----------------------------------------------------------
            # DISTRIBUSI PROBABILITAS
            # -----------------------------------------------------------
            if probs:
                st.subheader("Distribusi Probabilitas")
                for cls_name in sorted(probs.keys()):
                    cls_prob = probs[cls_name]
                    cls_color = {"positif": "green", "negatif": "red", "netral": "orange"}.get(
                        cls_name, "gray"
                    )
                    bar_col, val_col = st.columns([4, 1])
                    bar_col.progress(cls_prob, text=f":{cls_color}[{cls_name}]")
                    val_col.metric(label="", value=f"{cls_prob * 100:.1f}%")

            # -----------------------------------------------------------
            # PENJELASAN XAI (mulai P7)
            # -----------------------------------------------------------
            if explanation and "xai" in capabilities:
                st.subheader("Mengapa hasil ini muncul? (XAI)")
                st.caption(
                    "Batang berikut menunjukkan kata atau frasa yang paling memengaruhi "
                    "kelas terpilih. Ini penjelasan model linear, bukan makna psikologis."
                )
                max_contrib = max(abs(item["contribution"]) for item in explanation) or 0.01
                for item in explanation:
                    term = item["term"]
                    contrib = item["contribution"]
                    norm = abs(contrib) / max_contrib
                    sign = "+" if contrib >= 0 else "-"
                    st.progress(norm, text=f"`{term}` → {sign}{abs(contrib):.4f}")

            # -----------------------------------------------------------
            # METADATA
            # -----------------------------------------------------------
            with st.expander("Detail teknis"):
                meta_col1, meta_col2 = st.columns(2)
                meta_col1.metric("Latensi", f"{latency:.1f} ms")
                meta_col1.metric("Model", model_ver)
                meta_col2.metric("Pertemuan", f"P{week}")
                meta_col2.metric("Trace ID", trace_id[:8] + "…" if len(trace_id) > 8 else trace_id)

                st.caption("Kapabilitas aktif: " + ", ".join(capabilities))
                st.json(result)

# ===========================================================================
# TAB MONITORING & ARSITEKTUR
# ===========================================================================
st.divider()
tab_monitor, tab_arch = st.tabs(["Monitoring API", "Arsitektur"])

with tab_monitor:
    st.subheader("Monitoring API")
    if week < 7:
        # -------------------------------------------------------------------
        # ALUR PREDIKSI — ditampilkan sebelum monitoring dibuka (P1–P6)
        # -------------------------------------------------------------------
        st.info("Monitoring dibuka mulai Pertemuan 7. Bangun alur prediksi terlebih dahulu.", icon="🔒")
        st.markdown(
            """
**Alur prediksi yang harus berjalan sebelum monitoring bermakna:**

```
1. Pengguna mengetik teks masukan mahasiswa
        ↓
2. Streamlit mengirim POST /api/v1/predict  (HTTP JSON)
        ↓
3. FastAPI menerima request → validasi Pydantic
        ↓
4. ModelService.predict()
     ├── TF-IDF vectorizer  (teks → vektor fitur)
     └── Logistic Regression (vektor → probabilitas 3 kelas)
        ↓
5. Response: label, score, probabilities, latency_ms, trace_id
        ↓
6. MetricsStore.record()   ← dicatat tiap request
        ↓
7. GET /api/v1/metrics     ← monitoring membaca ringkasan
```

> **Latihan P7:** Lakukan minimal 5 prediksi berbeda, lalu buka tab ini dengan
> Pertemuan ≥ 7 dan amati angka p50, p95, dan distribusi label.
"""
        )
    else:
        # -------------------------------------------------------------------
        # MONITORING AKTIF — P7 ke atas
        # -------------------------------------------------------------------
        st.caption(
            "Metrik diambil dari `GET /api/v1/metrics`. "
            "Data hanya tersimpan selama proses API berjalan (in-memory)."
        )

        col_load, col_reset = st.columns([3, 1])
        load_clicked = col_load.button("🔄 Muat Metrik", key="load_metrics", use_container_width=True)
        reset_clicked = col_reset.button("🗑 Reset", key="reset_metrics", use_container_width=True)

        if reset_clicked:
            try:
                _post_json("/api/v1/metrics/reset", {})
                st.success("Metrik berhasil direset.", icon="✅")
            except Exception as exc:
                st.error(f"Gagal mereset metrik: {exc}", icon="⚠️")

        if load_clicked:
            try:
                metrics_data = _get_json("/api/v1/metrics")

                # -----------------------------------------------------------
                # KARTU METRIK UTAMA
                # -----------------------------------------------------------
                total = metrics_data.get("total_requests", 0)
                success = metrics_data.get("successful_requests", 0)
                failed = metrics_data.get("failed_requests", 0)
                error_rate = metrics_data.get("error_rate", 0.0)
                lat = metrics_data.get("latency_ms", {})

                col_a, col_b, col_c, col_d = st.columns(4)
                col_a.metric("Total Request", total)
                col_b.metric(
                    "Berhasil / Gagal",
                    f"{success} / {failed}",
                    delta=f"error {error_rate * 100:.1f}%",
                    delta_color="inverse",
                )
                col_c.metric("P50 Latency", f"{lat.get('p50', 0):.1f} ms")
                col_d.metric("P95 Latency", f"{lat.get('p95', 0):.1f} ms")

                col_e, col_f = st.columns(2)
                col_e.metric("Avg Latency", f"{lat.get('average', 0):.1f} ms")
                col_f.metric("Max Latency", f"{lat.get('maximum', 0):.1f} ms")

                # -----------------------------------------------------------
                # DISTRIBUSI LABEL
                # -----------------------------------------------------------
                dist = metrics_data.get("label_distribution", {})
                if dist:
                    st.subheader("Distribusi Label")
                    st.caption(
                        "Proporsi prediksi berhasil per kelas sentimen. "
                        "Distribusi yang sangat tidak seimbang bisa mencerminkan bias teks uji."
                    )
                    total_preds = sum(dist.values())
                    label_colors = {"positif": "green", "negatif": "red", "netral": "orange"}
                    for lbl, count in sorted(dist.items()):
                        ratio = count / total_preds if total_preds else 0
                        color = label_colors.get(lbl, "gray")
                        bar_col, pct_col = st.columns([4, 1])
                        bar_col.progress(ratio, text=f":{color}[{lbl}] — {count} prediksi")
                        pct_col.metric(label="", value=f"{ratio * 100:.1f}%")
                elif total > 0:
                    st.info("Belum ada prediksi berhasil yang dicatat.", icon="ℹ️")
                else:
                    st.warning(
                        "Belum ada request yang tercatat. "
                        "Lakukan beberapa prediksi terlebih dahulu, lalu muat ulang metrik.",
                        icon="⚠️",
                    )

                # -----------------------------------------------------------
                # RIWAYAT REQUEST TERBARU
                # -----------------------------------------------------------
                recent = metrics_data.get("recent", [])
                if recent:
                    st.subheader("10 Request Terakhir")
                    st.caption("Urutan terbaru di atas. Gunakan untuk verifikasi trace_id dari prediksi yang baru dilakukan.")
                    for req in recent:
                        status_icon = "✅" if req.get("success") else "❌"
                        lbl = req.get("label", "?")
                        lat_ms = req.get("latency_ms", 0)
                        ts = req.get("timestamp", "")[:19].replace("T", " ")
                        tid = req.get("trace_id", "-")[:8]
                        st.markdown(
                            f"{status_icon} `{ts}` — **{lbl}** · {lat_ms:.1f} ms · trace `{tid}…`"
                        )

                # -----------------------------------------------------------
                # JSON LENGKAP (untuk inspeksi mendalam)
                # -----------------------------------------------------------
                with st.expander("JSON lengkap `/api/v1/metrics`"):
                    st.caption("Ini adalah respons mentah dari endpoint monitoring. Gunakan untuk debugging.")
                    st.json(metrics_data)

                # -----------------------------------------------------------
                # CATATAN PEDAGOGI P7
                # -----------------------------------------------------------
                st.info(
                    "**Latihan P7:** Bandingkan p50 vs p95. "
                    "Jika p95 jauh lebih tinggi dari p50, ada request yang lambat secara outlier. "
                    "Lihat kolom 'Max Latency' dan riwayat terbaru untuk mencari penyebabnya.",
                    icon="💡",
                )

            except Exception as exc:
                st.error(f"Gagal memuat metrik: {exc}", icon="⚠️")

with tab_arch:
    st.subheader("Arsitektur SentiKampus")
    st.markdown(
        """
```
User
  |
  +--> Streamlit Web      (starter/web/app.py)
  |
  +--> Flutter Android    (starter/mobile/lib/)
           |
           v
       HTTP / JSON
           |
           v
       FastAPI REST API    (starter/backend/app/main.py)
           |
           +--> ModelService      (app/model_service.py)
           |       |
           |       +--> TfidfVectorizer    (sklearn)
           |       +--> LogisticRegression (sklearn)
           |       +--> Prediction + Probability
           |       +--> Feature Contribution / XAI
           |
           +--> MetricsStore      (app/monitoring.py)
                   |
                   +--> Request Count
                   +--> Error Count + Rate
                   +--> Latency (p50, p95, avg, max)
                   +--> Label Distribution
```

**Prinsip:**
- Frontend **tidak** menjalankan model secara langsung.
- Semua prediksi melalui FastAPI.
- Web dan Android memakai **API contract yang sama**.
- Training dan inference dipisahkan (`training.py` vs `model_service.py`).
        """
    )

    with st.expander("Peta file"):
        st.code(
            """
starter/backend/
  app/
    main.py          ← FastAPI factory + endpoints
    config.py        ← Settings dari env variable
    schemas.py       ← Pydantic request/response
    training.py      ← TF-IDF + Logistic Regression
    model_service.py ← Inference + XAI
    monitoring.py    ← MetricsStore thread-safe
    course_weeks.py  ← Metadata 16 pertemuan
    evaluation.py    ← Cross-validation
  scripts/
    train_model.py   ← CLI training
    evaluate_model.py← CLI evaluasi
  tests/
    test_api.py      ← Integration tests
  data/
    training_samples.csv
  models/
    sentiment.pkl    ← Artifact model
    metadata.json    ← Info model
            """
        )

# ===========================================================================
# FOOTER
# ===========================================================================
st.divider()
st.caption(
    "SentiKampus v2 — Modul Praktik Kecerdasan Buatan (788) · "
    "Universitas Bina Sarana Informatika 2026. "
    "Dataset bersifat demonstrasi. Gunakan input anonim."
)
