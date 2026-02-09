const router = require("express").Router();
const serviceAuth = require("../middlewares/serviceAuth.middleware");
const { reindexTours } = require("../services/reindex.service");

router.post("/reindex", serviceAuth, async (req, res, next) => {
  try {
    const result = await reindexTours();
    res.json(result);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
