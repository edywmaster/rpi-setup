import subprocess
import logging
import os
from logging.handlers import RotatingFileHandler


def listar_impressoras():
    """
    Lista as impressoras disponíveis no sistema e retorna a primeira encontrada.
    """
    try:
        # Comando lpstat para listar impressoras
        command = ["lpstat", "-p"]
        
        # Executa o comando e captura a saída
        result = subprocess.run(command, check=True, text=True, capture_output=True)
        
        # Filtra o nome da primeira impressora (suporte para múltiplos idiomas)
        lines = result.stdout.strip().splitlines()
        for line in lines:
            if line.startswith("printer") or line.startswith("impressora"):
                # A linha começa com "printer <nome>" ou "impressora <nome>"
                return line.split()[1]
        
        print(f"Impressora não encontrada.", flush=True)
        return None

    except subprocess.CalledProcessError as e:
        print(f"Erro ao executar 'lpstat -p': {e}", flush=True)
        return None
    except Exception as e:
        print(f"Erro inesperado ao listar impressoras: {e}", flush=True)
        return None


def imprimir_arquivo(arquivo, nome_impressora):
    if not os.path.exists(arquivo):
        print(f"Arquivo não encontrado", flush=True)
        return

    try:
        comando_impressao = ["lp", "-d", nome_impressora, arquivo]
        resultado = subprocess.run(comando_impressao, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        if resultado.returncode == 0:
            print(f"Arquivo '{arquivo}' enviado '{nome_impressora}'.", flush=True)
        else:
            print(f"Erro arquivo '{arquivo}' impressora '{nome_impressora}': {resultado.stderr}", flush=True)

    except Exception as e:
        print(f"Erro ao tentar imprimir o arquivo '{arquivo}': {e}", flush=True)


if __name__ == "__main__":
    # Nome do arquivo a ser impresso
    arquivo_para_imprimir = "files/badge.pdf"
    # Obtém a primeira impressora disponível
    impressora_destino = listar_impressoras()

    if impressora_destino:
        imprimir_arquivo(arquivo_para_imprimir, impressora_destino)
    else:
        print(f"Impressora indisponível", flush=True)