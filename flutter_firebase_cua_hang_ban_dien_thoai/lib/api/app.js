const express = require('express');
const cors = require('cors');
const emailRoutes = require('./routes');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api', emailRoutes);

app.listen(5000, () => console.log('Backend is running on port 5000'));
