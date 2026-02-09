const router = require("express").Router();
const aiController = require("../controllers/ai.controller");

router.post("/chat", aiController.chat);

module.exports = router;
