const router = require("express").Router();
router.use("/ai", require("./ai.routes"));
router.use("/ai/admin", require("./admin.routes"));
module.exports = router;
