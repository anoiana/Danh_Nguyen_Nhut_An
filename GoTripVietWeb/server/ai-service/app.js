const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");

const routes = require("./routes");
const errorHandler = require("./middlewares/errorHandler");

const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: "1mb" }));
app.use(morgan("dev"));

app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 120,
  })
);

app.get("/health", (req, res) => res.json({ ok: true, service: "ai-service" }));
app.use(routes);
app.use(errorHandler);

module.exports = app;
