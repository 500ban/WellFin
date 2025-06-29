const { Logging } = require('@google-cloud/logging');

let logging;
let logName;

// 開発環境ではコンソールログを使用
if (process.env.NODE_ENV === 'development') {
  const log = (severity, message, metadata = {}) => {
    const timestamp = new Date().toISOString();
    console.log(JSON.stringify({
      severity,
      message,
      metadata,
      timestamp
    }));
  };
  
  module.exports = { log };
} else {
  // 本番環境ではCloud Loggingを使用
  try {
    logging = new Logging();
    logName = 'wellfin-ai-functions';
  } catch (error) {
    console.error('Failed to initialize Cloud Logging:', error);
  }

  const log = (severity, message, metadata = {}) => {
    const logEntry = {
      severity: severity,
      message: message,
      metadata: metadata,
      timestamp: new Date().toISOString()
    };
    
    if (logging && logName) {
      logging.log(logName).write(logEntry).catch(error => {
        console.error('Failed to write to Cloud Logging:', error);
        console.log(JSON.stringify(logEntry));
      });
    } else {
      console.log(JSON.stringify(logEntry));
    }
  };
  
  module.exports = { log };
} 