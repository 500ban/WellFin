const express = require('express');
const router = express.Router();

// 各ルートの読み込み
router.use('/analyze-task', require('./analyze-task'));
router.use('/optimize-schedule', require('./optimize-schedule'));
router.use('/recommendations', require('./recommendations'));
router.use('/vertex-ai-test', require('./vertex-ai-test'));

module.exports = router; 