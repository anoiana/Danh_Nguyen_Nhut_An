const { QdrantClient } = require("@qdrant/js-client-rest");
const { QDRANT_URL, QDRANT_COLLECTION } = require("../../config/env");

const qdrant = new QdrantClient({ url: QDRANT_URL });

async function ensureCollection(vectorSize) {
  const collections = await qdrant.getCollections();
  const exists = collections.collections?.some(
    (c) => c.name === QDRANT_COLLECTION
  );
  if (exists) return;

  await qdrant.createCollection(QDRANT_COLLECTION, {
    vectors: { size: vectorSize, distance: "Cosine" },
  });
}

async function upsertPoints(points) {
  // points: [{ id, vector, payload }]
  await qdrant.upsert(QDRANT_COLLECTION, { points });
}

async function search(vector, topK = 5) {
  const res = await qdrant.search(QDRANT_COLLECTION, {
    vector,
    limit: topK,
    with_payload: true,
  });
  return res;
}

module.exports = {
  qdrant,
  ensureCollection,
  upsertPoints,
  search,
  QDRANT_COLLECTION,
};
