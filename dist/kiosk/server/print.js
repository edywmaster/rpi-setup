const express = require("express")
const dotenv = require("dotenv")
const fs = require("fs")
const path = require("path")
const winston = require("winston")
const axios = require("axios")
const { exec } = require("child_process")
const cors = require("cors")

const app = express()

// Load environment variables
const devMode = process.env.NODE_ENV === "development"
const envFile = devMode ? ".env.local" : ".env"
dotenv.config({ path: envFile })

const PORT = process.env.KIOSK_PRINT_PORT || process.env.PORT || 50001
const API_URL = process.env.KIOSK_APP_API || process.env.API_URL

// Configure logging
const logger = winston.createLogger({
  level: "info",
  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [
    new winston.transports.File({ filename: "/var/log/kiosk-print-server.log" }),
    new winston.transports.Console()
  ]
})

// Função para executar o script Python
function printPDF(filePath) {
  return new Promise((resolve, reject) => {
    const pythonScript = path.resolve(__dirname, "../utils/printer.py")
    const command = `python3 ${pythonScript} "${filePath}"`

    logger.info(`Executando comando de impressão: ${command}`)

    exec(command, { timeout: 45000 }, (error, stdout, stderr) => {
      if (error) {
        logger.error(`Erro ao imprimir: ${error.message}`)
        return reject(new Error("Erro ao imprimir o arquivo PDF."))
      }
      if (stderr) {
        logger.error(`Stderr da impressão: ${stderr}`)
        return reject(new Error(stderr))
      }

      logger.info(`Impressão concluída: ${stdout}`)
      resolve(stdout)
    })
  })
}

// Função para baixar um arquivo PDF
async function downloadPDF(url, outputPath) {
  try {
    logger.info(`Baixando PDF de: ${url}`)

    const response = await axios({
      method: "GET",
      url,
      responseType: "stream",
      timeout: 30000, // 30 seconds timeout
      maxContentLength: 10 * 1024 * 1024 // 10MB limit
    })

    const fileDir = path.dirname(outputPath)
    if (!fs.existsSync(fileDir)) {
      fs.mkdirSync(fileDir, { recursive: true })
    }

    const writer = fs.createWriteStream(outputPath)
    response.data.pipe(writer)

    return new Promise((resolve, reject) => {
      writer.on("finish", () => {
        logger.info(`PDF baixado com sucesso: ${outputPath}`)
        resolve()
      })
      writer.on("error", error => {
        logger.error(`Erro ao salvar PDF: ${error.message}`)
        reject(error)
      })
    })
  } catch (error) {
    logger.error(`Erro ao baixar PDF: ${error.message}`)
    throw new Error("Erro ao baixar o PDF.")
  }
}

// Função para validar sistema de impressão
function checkPrintSystem() {
  return new Promise((resolve, reject) => {
    const pythonScript = path.resolve(__dirname, "../utils/printer.py")
    const command = `python3 ${pythonScript} --check-cups`

    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(new Error("CUPS não está funcionando"))
      } else {
        resolve(stdout.trim())
      }
    })
  })
}

// Middleware
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type", "Authorization"]
  })
)

app.use(express.json())

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path} - ${req.ip}`)
  next()
})

// Health check endpoint
app.get("/health", async (req, res) => {
  try {
    const cupsStatus = await checkPrintSystem()
    res.json({
      status: "ok",
      service: "kiosk-print-server",
      version: "1.0.0",
      cups: cupsStatus,
      api_url: API_URL,
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    res.status(503).json({
      status: "error",
      message: "Sistema de impressão indisponível",
      error: error.message,
      timestamp: new Date().toISOString()
    })
  }
})

// Endpoint para listar impressoras
app.get("/printers", (req, res) => {
  const pythonScript = path.resolve(__dirname, "../utils/printer.py")
  const command = `python3 ${pythonScript} --list`

  exec(command, (error, stdout, stderr) => {
    if (error) {
      logger.error(`Erro ao listar impressoras: ${error.message}`)
      return res.status(500).json({
        status: "error",
        message: "Erro ao listar impressoras"
      })
    }

    res.json({
      status: "ok",
      output: stdout.trim(),
      timestamp: new Date().toISOString()
    })
  })
})

// Rota para baixar e imprimir um arquivo PDF
app.get("/badge/:id", async (req, res, next) => {
  const ID = parseInt(req.params.id, 10)

  logger.info(`Requisição de impressão recebida para ID: ${ID}`)

  if (isNaN(ID) || ID <= 0) {
    logger.warn(`ID inválido recebido: ${req.params.id}`)
    return res.status(400).json({ status: "error", message: "ID inválido." })
  }

  const filename = `badge_${ID}_${Date.now()}.pdf`
  const filePath = path.join(__dirname, "../tmp", filename)
  const fileApiUrl = `${API_URL}/app/totem/badge/${ID}`

  try {
    await downloadPDF(fileApiUrl, filePath)
    await printPDF(filePath)

    // Clean up downloaded file after printing
    setTimeout(() => {
      fs.unlink(filePath, err => {
        if (err) logger.warn(`Erro ao remover arquivo: ${err.message}`)
        else logger.info(`Arquivo temporário removido: ${filePath}`)
      })
    }, 5000) // Remove after 5 seconds

    logger.info(`Impressão concluída com sucesso para ID: ${ID}`)
    res.json({
      status: "success",
      message: "Badge impresso com sucesso.",
      id: ID,
      file: filename,
      api_url: fileApiUrl,
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    logger.error(`Erro na impressão para ID ${ID}: ${error.message}`)
    next(error)
  }
})

// Rota para testar impressão com arquivo local
app.post("/test-print", async (req, res, next) => {
  const { file_path } = req.body

  if (!file_path) {
    return res.status(400).json({
      status: "error",
      message: "Caminho do arquivo é obrigatório"
    })
  }

  try {
    await printPDF(file_path)

    logger.info(`Teste de impressão concluído: ${file_path}`)
    res.json({
      status: "success",
      message: "Teste de impressão realizado com sucesso.",
      file: file_path,
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    logger.error(`Erro no teste de impressão: ${error.message}`)
    next(error)
  }
})

// Rota para listar arquivos na fila de impressão
app.get("/queue", (req, res) => {
  const filesDir = path.join(__dirname, "../tmp")

  if (!fs.existsSync(filesDir)) {
    return res.json({ queue: [], count: 0 })
  }

  fs.readdir(filesDir, (err, files) => {
    if (err) {
      logger.error(`Erro ao listar fila: ${err.message}`)
      return res.status(500).json({ status: "error", message: "Erro ao acessar fila de impressão" })
    }

    const pdfFiles = files.filter(file => file.endsWith(".pdf"))
    const fileDetails = pdfFiles.map(file => {
      const fullPath = path.join(filesDir, file)
      const stats = fs.statSync(fullPath)
      return {
        name: file,
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime
      }
    })

    res.json({
      queue: fileDetails,
      count: pdfFiles.length,
      timestamp: new Date().toISOString()
    })
  })
})

// Rota para status da impressora
app.get("/printer-status", (req, res) => {
  const pythonScript = path.resolve(__dirname, "../utils/printer.py")
  const command = `python3 ${pythonScript} --status`

  exec(command, (error, stdout, stderr) => {
    if (error) {
      logger.error(`Erro ao verificar status: ${error.message}`)
      return res.status(500).json({
        status: "error",
        message: "Erro ao verificar status da impressora"
      })
    }

    res.json({
      status: "ok",
      printer_status: stdout.trim(),
      timestamp: new Date().toISOString()
    })
  })
})

// Error handler
app.use((err, req, res, next) => {
  logger.error(`Erro interno: ${err.message}`)
  res.status(500).json({
    status: "error",
    message: "Erro interno no servidor.",
    timestamp: new Date().toISOString()
  })
})

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    status: "error",
    message: "Endpoint não encontrado",
    available_endpoints: [
      "GET /health",
      "GET /printers",
      "GET /badge/:id",
      "POST /test-print",
      "GET /queue",
      "GET /printer-status"
    ],
    timestamp: new Date().toISOString()
  })
})

// Start server
const server = app.listen(PORT, "0.0.0.0", () => {
  logger.info(`Servidor de impressão rodando${devMode ? " (DEV MODE)" : ""} em http://0.0.0.0:${PORT}`)
  logger.info(`API URL configurada: ${API_URL}`)

  // Test print system on startup
  checkPrintSystem()
    .then(status => logger.info(`Sistema de impressão: ${status}`))
    .catch(error => logger.warn(`Aviso: ${error.message}`))
})

// Graceful shutdown
process.on("SIGTERM", () => {
  logger.info("Servidor de impressão sendo finalizado...")
  server.close(() => {
    process.exit(0)
  })
})

process.on("SIGINT", () => {
  logger.info("Servidor de impressão interrompido pelo usuário")
  server.close(() => {
    process.exit(0)
  })
})
