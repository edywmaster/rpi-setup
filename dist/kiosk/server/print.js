const express = require("express")
const dotenv = require("dotenv")
const fs = require("fs")
const path = require("path")
const winston = require("winston")

const axios = require("axios")
const { exec } = require("child_process")

const app = express()
const cors = require("cors")

const devMode = process.env.NODE_ENV === "development"
const envFile = devMode ? ".env.local" : ".env"
dotenv.config({ path: envFile })

const PORT = process.env.PORT || 3000
const API_URL = process.env.API_URL

// Função para executar o script Python
function printPDF(filePath) {
  return new Promise((resolve, reject) => {
    const pythonScript = path.resolve(__dirname, "files/printer.py")
    const command = `python3 ${pythonScript} "${filePath}"`
    exec(command, (error, stdout, stderr) => {
      if (error) {
        return reject(new Error("Erro ao imprimir o arquivo PDF."))
      }
      if (stderr) {
        return reject(new Error(stderr))
      }
      resolve(stdout)
    })
  })
}

// Função para baixar um arquivo PDF
async function downloadPDF(url, outputPath) {
  try {
    const response = await axios({ method: "GET", url, responseType: "stream" })
    const fileDir = path.dirname(outputPath)
    if (!fs.existsSync(fileDir)) {
      fs.mkdirSync(fileDir, { recursive: true })
    }
    const writer = fs.createWriteStream(outputPath)
    response.data.pipe(writer)
    return new Promise((resolve, reject) => {
      writer.on("finish", resolve)
      writer.on("error", reject)
    })
  } catch (error) {
    throw new Error("Erro ao baixar o PDF.")
  }
}

app.use(
  cors({
    origin: "*",
    methods: ["GET"],
    allowedHeaders: ["Content-Type", "Authorization"]
  })
)

// Rota para baixar e imprimir um arquivo PDF
app.get("/badge/:id", async (req, res, next) => {
  const ID = parseInt(req.params.id, 10)
  if (isNaN(ID) || ID <= 0) {
    return res.status(400).json({ status: "error", message: "ID inválido." })
  }
  const filePath = "files/badge.pdf"
  const fileApiUrl = `${API_URL}/app/totem/badge/${ID}`
  try {
    await downloadPDF(fileApiUrl, filePath)
    await printPDF(filePath)
    res.json({ status: "success", message: "Arquivo recebido com sucesso.", file: filePath, url: fileApiUrl })
  } catch (error) {
    next(error)
  }
})

// Rota para imprimir um arquivo PDF
app.use((err, req, res, next) => {
  console.error("Erro interno:", err.message)
  res.status(500).json({ status: "error", message: "Erro interno no servidor." })
})

// Inicia o servidor
app.listen(PORT, () => {
  console.log(`Servidor rodando${devMode ? " (DEV MODE)" : ""} em http://localhost:${PORT}`)
})
