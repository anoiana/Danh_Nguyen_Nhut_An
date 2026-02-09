const ChatSession = require("../models/ChatSession.model");
const inventory = require("./inventory.client");
const locationClient = require("./location.client");

// Bạn phải tạo 2 file này theo bước trước:
// services/llm/openai.client.js  -> embedText(), generateAnswer()
// services/vector/qdrant.client.js -> search()
const { embedText, generateAnswer } = require("./llm/ollama.client");
const { search } = require("./vector/qdrant.client");

function normalize(str = "") {
  return String(str)
    .toLowerCase()
    .replace(/đ/g, "d")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // bỏ dấu
    .replace(/[^a-z0-9\s-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

async function detectLocationFromConversation(sessionMessages) {
  const text = normalize(
    (sessionMessages || [])
      .filter((m) => m.role === "user")
      .slice(-4)
      .map((m) => m.content)
      .join(" ")
  );

  if (!text) return null;

  const locations = await locationClient.listLocations(); // [{name, slug, _id}, ...]
  if (!Array.isArray(locations) || locations.length === 0) return null;

  // match theo slug trước (ổn định), rồi name
  for (const loc of locations) {
    const slug = normalize(loc.slug || "");
    if (slug && text.includes(slug)) return loc;
  }
  for (const loc of locations) {
    const name = normalize(loc.name || "");
    if (name && text.includes(name)) return loc;
  }

  return null;
}

function escapeRegExp(str = "") {
  return String(str).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function linkifyToursInAnswer(answer = "", tours = []) {
  let out = String(answer || "");

  for (const t of tours) {
    if (!t?.id || !t?.title) continue;

    const url = `/product/${t.id}`; // phải khớp với route FE bạn đang dùng
    const title = String(t.title);

    // 1) đổi dạng **Title** -> **[Title](/product/id)**
    const boldRe = new RegExp(
      `\\*\\*\\s*${escapeRegExp(title)}\\s*\\*\\*`,
      "g"
    );
    out = out.replace(boldRe, `**[${title}](${url})**`);

    // 2) đổi dạng Title (chưa link) -> **[Title](/product/id)**
    // tránh trường hợp đã nằm trong [Title](
    const plainRe = new RegExp(`(?<!\\[)${escapeRegExp(title)}(?!\\]\\()`, "g");
    out = out.replace(plainRe, `**[${title}](${url})**`);
  }

  return out;
}

function buildContext({ hits, events, sessionMessages, detectedLocation }) {
  const SCORE_THRESHOLD = 0.25; // thử 0.2 -> 0.35 tuỳ dữ liệu

  const filteredHits = (hits || []).filter(
    (h) => (h?.score ?? 0) >= SCORE_THRESHOLD
  );

  const topTours = filteredHits.map((h) => h?.payload).filter(Boolean);

  let filteredTopTours = topTours;

  if (detectedLocation?.name || detectedLocation?.slug) {
    const key = normalize(detectedLocation.name || detectedLocation.slug);

    const byLocation = topTours.filter((t) => {
      const hay = normalize(
        `${t.title || ""} ${t.location || ""} ${t.text || ""}`
      );
      return key && hay.includes(key);
    });

    if (byLocation.length > 0) filteredTopTours = byLocation;
  }

  const memory = (sessionMessages || [])
    .slice(-4) // giảm để nhanh hơn (mục 2)
    .map((m) => `${m.role}: ${m.content}`)
    .join("\n");

  const toursText = filteredTopTours
    .slice(0, 3) // giảm để nhanh hơn (mục 2)
    .map(
      (t, i) =>
        `#${i + 1}\n- id: ${t.id}\n- title: ${t.title}\n- location: ${
          t.location || "N/A"
        }\n- priceFrom: ${t.priceFrom || "N/A"}\n`
    )
    .join("\n");

  const eventsText = Array.isArray(events)
    ? events
        .slice(0, 5)
        .map((e, i) => `E${i + 1}: ${e.title || e.name || e._id || e.id}`)
        .join("\n")
    : "";

  return {
    topTours: filteredTopTours,
    contextText: `LỊCH SỬ (MEMORY):
    ${memory || "(trống)"}
    DANH SÁCH TOUR (TOP):
    ${toursText || "(không có tour phù hợp)"}
    EVENT ĐANG CHẠY:
    ${eventsText || "(không có hoặc không lấy được)"}`,
  };
}

async function chat({ sessionId, message }) {
  // 1) load/create session (Memory)
  let session = await ChatSession.findOne({ sessionId });
  if (!session) session = await ChatSession.create({ sessionId, messages: [] });

  // 2) lưu user msg
  session.messages.push({ role: "user", content: message });
  await session.save();

  const detectedLocation = await detectLocationFromConversation(
    session.messages
  );

  // 3) RAG: embed + vector search
  let hits = [];
  try {
    // build retrieval query từ ngữ cảnh gần nhất để search đúng hơn
    const recentUserMessages = (session.messages || [])
      .filter((m) => m.role === "user")
      .slice(-3)
      .map((m) => m.content)
      .join(" | ");

    const retrievalQuery = `${recentUserMessages} | ${message}`;

    const queryVec = await embedText(retrievalQuery);
    hits = await search(queryVec, 8); // tăng topK chút để có cơ hội lọc
  } catch (err) {
    console.error(
      "QDRANT_SEARCH_ERROR:",
      err?.response?.data || err?.message || err
    );
    hits = [];
  }

  // 4) events realtime (đừng để fail làm chết chat)
  const eventsSettled = await Promise.allSettled([inventory.getActiveEvents()]);
  const events =
    eventsSettled[0].status === "fulfilled" ? eventsSettled[0].value : [];

  // 5) build context cho LLM
  const { topTours, contextText } = buildContext({
    hits,
    events,
    sessionMessages: session.messages,
    detectedLocation,
  });

  // 6) gọi OpenAI để viết câu trả lời
  const system =
    "Bạn là tư vấn viên du lịch GoTripViet: thân thiện, chủ động, nói tự nhiên như người thật.\n" +
    "QUY TẮC CỨNG:\n" +
    "- TUYỆT ĐỐI KHÔNG bịa tour. Chỉ dùng tour có trong DANH SÁCH TOUR (TOP).\n" +
    "- Nếu không có tour phù hợp trong danh sách, hãy nói rõ và hỏi tối đa 2 câu để lấy thêm thông tin.\n" +
    "CÁCH TRẢ LỜI:\n" +
    "- Nếu đã đủ thông tin: tóm tắt nhu cầu 1 câu, rồi đưa 1-3 lý do vì sao các tour bên dưới phù hợp.\n" +
    "- TUYỆT ĐỐI KHÔNG tự nêu tên tour cụ thể trong phần trả lời. Chỉ nói: 'Mình gợi ý vài tour phù hợp bên dưới'.\n" +
    "- Không nhắc tới 'ngữ cảnh', 'TOP TOURS', 'MEMORY'. Trả lời tiếng Việt.\n" +
    "FORMAT:\n" +
    "- Khi liệt kê tour, dùng đúng Markdown list 1 lần:\n" +
    "  Ví dụ:\n" +
    "- Khi nhắc tour, chỉ in đậm đúng tên tour, KHÔNG in URL thô và CHỈ được dùng đúng tên trong 'DANH SÁCH TOUR (TOP)' (copy y nguyên), không được sáng tạo.\n" +
    "  Ví dụ: - **Tên tour** (kèm 1-2 lý do ngắn)";

  let answer = "";
  try {
    const safeContext = String(contextText || "").slice(0, 4000);
    answer = await generateAnswer({
      system,
      user: message,
      contextText: safeContext,
    });
  } catch (err) {
    console.error(
      "OLLAMA_GENERATE_ERROR:",
      err?.response?.data || err?.message || err
    );
    answer =
      "Mình đang gặp lỗi khi tạo câu trả lời. Bạn cho mình biết điểm đến + số ngày + ngân sách dự kiến để mình gợi ý nhanh nhé.";
  }

  // 7) suggestedTours cho UI
  const suggestedTours = topTours.slice(0, 3).map((t) => ({
    id: t.id,
    title: t.title,
    location: t.location,
    priceFrom: t.priceFrom,
    image: t.image,
  }));

  answer = linkifyToursInAnswer(answer, suggestedTours);
  answer = answer
    // gom các list rời kiểu "- item\n\n- item" thành 1 list liền
    .replace(/\n\s*\n(?=\s*[-*]\s)/g, "\n")
    // giảm blank line quá nhiều
    .replace(/\n{3,}/g, "\n\n");
  let finalAnswer = answer;

  // follow-up chỉ hỏi khi chưa đủ info/tour
  const followUpQuestions =
    suggestedTours.length === 0
      ? [
          "Bạn muốn đi đâu ?",
          "Bạn dự kiến đi mấy ngày ?",
          "Ngân sách của bạn khoảng bao nhiêu?",
        ]
      : [];

  const result = {
    answer:
      finalAnswer ||
      "Bạn cho mình thêm điểm đến / số ngày / ngân sách để mình gợi ý chính xác nhé.",
    suggestedTours,
    followUpQuestions,
  };

  // 8) lưu assistant msg (Memory)
  session.messages.push({ role: "assistant", content: result.answer });
  await session.save();

  return result;
}

module.exports = { chat };
