import { useState, useEffect } from "react";
import { translateAPI, folderAPI, vocabAPI } from "../services/api";
import { useAuth } from "../context/AuthContext";

const DICT_API = "https://api.dictionaryapi.dev/api/v2/entries/en";

export default function DictionaryPage() {
  const { user } = useAuth();
  const [word, setWord] = useState("");
  const [results, setResults] = useState(null);
  const [translation, setTranslation] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Save vocab state
  const [folders, setFolders] = useState([]);
  const [saveData, setSaveData] = useState(null);
  const [editSavePhonetic, setEditSavePhonetic] = useState("");
  const [editSaveMeaning, setEditSaveMeaning] = useState("");
  const [targetFolderId, setTargetFolderId] = useState("");
  const [saveLoading, setSaveLoading] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState("");

  useEffect(() => {
    if (user) {
      folderAPI
        .getByUser(user.userId, 0, 100, "")
        .then((data) => {
          setFolders(data.content || []);
          if (data.content && data.content.length > 0) {
            setTargetFolderId(data.content[0].id);
          }
        })
        .catch((e) => console.error("Error fetching folders:", e));
    }
  }, [user]);

  const handleSaveVocab = async (e) => {
    e.preventDefault();
    if (!targetFolderId || !saveData) return;
    setSaveLoading(true);
    setSaveSuccess("");
    setError("");
    try {
      const { entry, meaning } = saveData;

      // Extract best audio URL
      let audioUrl = "";
      if (entry.phonetics && entry.phonetics.length > 0) {
        const p = entry.phonetics.find((x) => x.audio);
        if (p) audioUrl = p.audio;
      }

      // Extract ONLY the selected meaning to prevent massive duplication and 500 load errors
      const mappedMeanings = [
        {
          partOfSpeech: meaning.partOfSpeech || "",
          synonyms: meaning.synonyms || [],
          antonyms: meaning.antonyms || [],
          definitions: (meaning.definitions || []).map((d) => ({
            definition: d.definition || "",
            example: d.example || "",
          })),
        },
      ];

      await vocabAPI.create({
        word: word.trim(),
        phoneticText: editSavePhonetic.trim() || null,
        audioUrl: audioUrl || null,
        userDefinedMeaning: editSaveMeaning.trim(),
        userDefinedPartOfSpeech: meaning?.partOfSpeech || null,
        folderId: targetFolderId,
        meanings: mappedMeanings,
      });
      setSaveData(null);
      setSaveSuccess("Đã lưu từ vựng thành công!");
      setTimeout(() => setSaveSuccess(""), 3000);
    } catch (err) {
      setError(err.message || "Lỗi khi lưu từ vựng");
      setSaveData(null);
    } finally {
      setSaveLoading(false);
    }
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    if (!word.trim()) return;

    setLoading(true);
    setError("");
    setResults(null);
    setTranslation("");

    try {
      // Parallel: Dictionary API + Translation API
      const [dictRes, transRes] = await Promise.allSettled([
        fetch(`${DICT_API}/${encodeURIComponent(word.trim())}`).then((r) => {
          if (!r.ok) throw new Error("not found");
          return r.json();
        }),
        translateAPI.translate(word.trim()),
      ]);

      if (dictRes.status === "fulfilled") {
        setResults(dictRes.value);
      }

      if (transRes.status === "fulfilled") {
        // Remove surrounding quotes if present
        const t = String(transRes.value).replace(/^"|"$/g, "");
        setTranslation(t);
      }

      if (dictRes.status === "rejected" && transRes.status === "rejected") {
        setError("Không tìm thấy từ này trong từ điển");
      }
    } catch {
      setError("Đã có lỗi xảy ra khi tra từ");
    } finally {
      setLoading(false);
    }
  };

  const playAudio = (url) => {
    if (url) new Audio(url).play();
  };

  return (
    <div className="fade-in">
      <div className="page-header">
        <h1 className="page-title">📖 Từ điển</h1>
      </div>

      <form onSubmit={handleSearch} style={{ maxWidth: 600, marginBottom: 32 }}>
        <div style={{ display: "flex", gap: 12 }}>
          <div className="search-bar" style={{ flex: 1, maxWidth: "none" }}>
            <span className="search-icon">🔍</span>
            <input
              placeholder="Nhập từ tiếng Anh muốn tra..."
              value={word}
              onChange={(e) => setWord(e.target.value)}
              autoFocus
            />
          </div>
          <button
            type="submit"
            className="btn btn-primary"
            disabled={loading || !word.trim()}
          >
            {loading ? "⏳" : "🔎"} Tra từ
          </button>
        </div>
      </form>

      {error && (
        <div className="error-message">
          {error}{" "}
          <button className="btn-ghost btn-sm" onClick={() => setError("")}>
            ✕
          </button>
        </div>
      )}
      {saveSuccess && <div className="success-message">{saveSuccess}</div>}

      {loading && (
        <div className="loading">
          <span className="spinner"></span> Đang tra từ...
        </div>
      )}

      {(results || translation) && !loading && (
        <div style={{ maxWidth: 700 }}>
          {/* Translation */}
          {translation && (
            <div
              style={{
                background: "var(--primary-glow)",
                border: "1px solid rgba(99,102,241,0.3)",
                borderRadius: "var(--radius-md)",
                padding: "16px 20px",
                marginBottom: 24,
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: 12,
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <span style={{ fontSize: 24 }}>🇻🇳</span>
                <div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--text-muted)",
                      marginBottom: 4,
                    }}
                  >
                    DỊCH TIẾNG VIỆT
                  </div>
                  <div
                    style={{
                      fontSize: 18,
                      fontWeight: 600,
                      color: "var(--primary-light)",
                    }}
                  >
                    {translation}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Dictionary Results */}
          {results &&
            results.map((entry, eIdx) => (
              <div
                key={eIdx}
                style={{
                  background: "var(--bg-card)",
                  border: "1px solid var(--border)",
                  borderRadius: "var(--radius-lg)",
                  padding: 24,
                  marginBottom: 16,
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 16,
                    marginBottom: 20,
                  }}
                >
                  <div>
                    <h2
                      style={{
                        fontSize: 28,
                        fontWeight: 800,
                        color: "var(--primary-light)",
                      }}
                    >
                      {entry.word}
                    </h2>
                    {entry.phonetic && (
                      <span
                        style={{
                          color: "var(--text-muted)",
                          fontStyle: "italic",
                        }}
                      >
                        {entry.phonetic}
                      </span>
                    )}
                  </div>
                  {entry.phonetics &&
                    entry.phonetics.map(
                      (p, pIdx) =>
                        p.audio && (
                          <button
                            key={pIdx}
                            className="btn btn-ghost btn-sm"
                            onClick={() => playAudio(p.audio)}
                          >
                            🔊 {p.text || "Phát âm"}
                          </button>
                        ),
                    )}
                </div>

                {entry.meanings &&
                  entry.meanings.map((meaning, mIdx) => (
                    <div
                      key={mIdx}
                      style={{
                        marginBottom: 24,
                        paddingBottom: 16,
                        borderBottom:
                          mIdx < entry.meanings.length - 1
                            ? "1px dashed var(--border)"
                            : "none",
                      }}
                    >
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "space-between",
                          marginBottom: 16,
                        }}
                      >
                        <span
                          className="pos"
                          style={{
                            background: "var(--primary)",
                            color: "white",
                            padding: "4px 12px",
                            borderRadius: 4,
                            fontWeight: "bold",
                          }}
                        >
                          {meaning.partOfSpeech}
                        </span>
                        <button
                          className="btn btn-primary btn-sm"
                          onClick={() => {
                            setSaveData({ entry, meaning });
                            setEditSavePhonetic(entry.phonetic || "");
                            setEditSaveMeaning(translation || "");
                          }}
                        >
                          💾 Lưu theo nghĩa này
                        </button>
                      </div>

                      {meaning.definitions &&
                        meaning.definitions.slice(0, 4).map((def, dIdx) => (
                          <div
                            key={dIdx}
                            style={{
                              paddingLeft: 16,
                              borderLeft: "2px solid var(--border)",
                              marginBottom: 12,
                              marginLeft: 4,
                            }}
                          >
                            <p
                              style={{
                                color: "var(--text-primary)",
                                fontSize: 15,
                                marginBottom: 4,
                              }}
                            >
                              {dIdx + 1}. {def.definition}
                            </p>
                            {def.example && (
                              <p
                                style={{
                                  color: "var(--text-muted)",
                                  fontSize: 13,
                                  fontStyle: "italic",
                                }}
                              >
                                ➤ "{def.example}"
                              </p>
                            )}
                          </div>
                        ))}

                      {meaning.synonyms && meaning.synonyms.length > 0 && (
                        <div style={{ marginTop: 8 }}>
                          <span
                            style={{ fontSize: 12, color: "var(--text-muted)" }}
                          >
                            Đồng nghĩa:{" "}
                          </span>
                          {meaning.synonyms.slice(0, 6).map((s, sIdx) => (
                            <span
                              key={sIdx}
                              style={{
                                background: "var(--success-light)",
                                color: "var(--success)",
                                padding: "2px 8px",
                                borderRadius: 12,
                                fontSize: 12,
                                marginRight: 6,
                              }}
                            >
                              {s}
                            </span>
                          ))}
                        </div>
                      )}

                      {meaning.antonyms && meaning.antonyms.length > 0 && (
                        <div style={{ marginTop: 6 }}>
                          <span
                            style={{ fontSize: 12, color: "var(--text-muted)" }}
                          >
                            Trái nghĩa:{" "}
                          </span>
                          {meaning.antonyms.slice(0, 6).map((a, aIdx) => (
                            <span
                              key={aIdx}
                              style={{
                                background: "var(--danger-light)",
                                color: "var(--danger)",
                                padding: "2px 8px",
                                borderRadius: 12,
                                fontSize: 12,
                                marginRight: 6,
                              }}
                            >
                              {a}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
              </div>
            ))}
        </div>
      )}

      {!results && !translation && !loading && !error && (
        <div className="empty-state">
          <div className="empty-icon">📚</div>
          <h3>Tra từ tiếng Anh</h3>
          <p>
            Nhập từ bạn muốn tra để xem nghĩa, phiên âm, ví dụ và bản dịch tiếng
            Việt
          </p>
        </div>
      )}

      {saveData && (
        <div className="modal-overlay" onClick={() => setSaveData(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title">
                💾 Lưu từ vựng:{" "}
                <span style={{ color: "var(--primary-light)" }}>{word}</span>
              </h3>
              <button className="modal-close" onClick={() => setSaveData(null)}>
                ✕
              </button>
            </div>
            <form onSubmit={handleSaveVocab}>
              <div className="form-group">
                <label>Loại từ</label>
                <input
                  className="form-input"
                  value={saveData.meaning?.partOfSpeech || ""}
                  disabled
                  style={{ opacity: 0.7 }}
                />
              </div>
              <div className="form-group">
                <label>Phiên âm</label>
                <input
                  className="form-input"
                  value={editSavePhonetic}
                  onChange={(e) => setEditSavePhonetic(e.target.value)}
                  placeholder="ví dụ: /ˈhæp.i.nəs/"
                />
              </div>
              <div className="form-group">
                <label>Nghĩa (chọn gợi ý hoặc gõ từ mới)</label>
                <select
                  className="form-input"
                  style={{ marginBottom: 12, background: "var(--bg-card)" }}
                  onChange={(e) => {
                    if (e.target.value !== "") {
                      setEditSaveMeaning(e.target.value);
                    }
                  }}
                  defaultValue=""
                >
                  <option value="" disabled>
                    -- Chọn gợi ý nghĩa (Tùy chọn) --
                  </option>
                  {translation && (
                    <option value={translation}>
                      🇻🇳 [Google Dịch] {translation}
                    </option>
                  )}
                  {saveData.meaning?.definitions?.map((d, i) => (
                    <option key={i} value={d.definition || ""}>
                      🇬🇧 {d.definition}
                    </option>
                  ))}
                </select>
                <input
                  className="form-input"
                  value={editSaveMeaning}
                  onChange={(e) => setEditSaveMeaning(e.target.value)}
                  placeholder="Hoặc tự nhập nghĩa tiếng Việt / tiếng Anh..."
                  required
                  autoFocus
                />
              </div>
              <div className="form-group">
                <label>Lưu vào thư mục</label>
                <select
                  className="form-input"
                  value={targetFolderId}
                  onChange={(e) => setTargetFolderId(e.target.value)}
                  style={{ background: "var(--bg-card)" }}
                  required
                >
                  {folders.length === 0 && (
                    <option value="" disabled>
                      Bạn chưa có thư mục nào
                    </option>
                  )}
                  {folders.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setSaveData(null)}
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={
                    saveLoading || !targetFolderId || !editSaveMeaning.trim()
                  }
                >
                  {saveLoading ? "Đang lưu..." : "Lưu lại"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
