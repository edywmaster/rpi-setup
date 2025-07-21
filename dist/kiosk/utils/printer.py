#!/usr/bin/env python3
"""
Kiosk Print System - Python Printer Script
Handles PDF printing via CUPS on Raspberry Pi
Version: 1.0.0
"""

import sys
import os
import subprocess
import logging
from pathlib import Path
import argparse
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/kiosk-printer.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def get_default_printer():
    """Get the default printer from CUPS"""
    try:
        result = subprocess.run(['lpstat', '-d'], capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        
        if 'no system default destination' in output.lower():
            logger.warning("Nenhuma impressora padrão configurada")
            return None
            
        # Extract printer name from "system default destination: printer_name"
        if ':' in output:
            printer_name = output.split(':')[-1].strip()
            logger.info(f"Impressora padrão encontrada: {printer_name}")
            return printer_name
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao obter impressora padrão: {e}")
        return None
    
    return None

def list_available_printers():
    """List all available printers"""
    try:
        result = subprocess.run(['lpstat', '-p'], capture_output=True, text=True, check=True)
        printers = []
        
        for line in result.stdout.split('\n'):
            if line.startswith('printer '):
                printer_name = line.split()[1]
                printers.append(printer_name)
        
        logger.info(f"Impressoras disponíveis: {printers}")
        return printers
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao listar impressoras: {e}")
        return []

def check_cups_service():
    """Check if CUPS service is running"""
    try:
        result = subprocess.run(['systemctl', 'is-active', 'cups'], capture_output=True, text=True)
        return result.returncode == 0
    except Exception as e:
        logger.error(f"Erro ao verificar CUPS: {e}")
        return False

def print_pdf(file_path, printer_name=None, copies=1):
    """Print PDF file using CUPS lp command"""
    
    # Check CUPS service
    if not check_cups_service():
        raise RuntimeError("Serviço CUPS não está em execução")
    
    # Validate file exists
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Arquivo não encontrado: {file_path}")
    
    # Validate file is PDF
    if not file_path.lower().endswith('.pdf'):
        raise ValueError("Apenas arquivos PDF são suportados")
    
    # Check file size (limit to 10MB)
    file_size = os.path.getsize(file_path)
    if file_size > 10 * 1024 * 1024:  # 10MB
        raise ValueError(f"Arquivo muito grande: {file_size / 1024 / 1024:.1f}MB (máximo: 10MB)")
    
    logger.info(f"Iniciando impressão: {file_path} ({file_size} bytes)")
    
    # Get printer to use
    if not printer_name:
        printer_name = get_default_printer()
        
        if not printer_name:
            # Try to get first available printer
            available_printers = list_available_printers()
            if available_printers:
                printer_name = available_printers[0]
                logger.info(f"Usando primeira impressora disponível: {printer_name}")
            else:
                raise RuntimeError("Nenhuma impressora configurada no sistema")
    
    # Build lp command
    cmd = ['lp']
    
    if printer_name:
        cmd.extend(['-d', printer_name])
    
    if copies > 1:
        cmd.extend(['-n', str(copies)])
    
    # Add print options for better PDF handling
    cmd.extend([
        '-o', 'fit-to-page',           # Scale to fit page
        '-o', 'sides=one-sided',       # Single-sided printing
        '-o', 'media=A4',              # Paper size
        '-o', 'orientation-requested=3', # Portrait orientation
        '-o', 'print-quality=4'        # Best quality
    ])
    
    cmd.append(file_path)
    
    try:
        logger.info(f"Executando comando: {' '.join(cmd)}")
        start_time = time.time()
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
        
        # lp returns job ID on success
        job_info = result.stdout.strip()
        elapsed_time = time.time() - start_time
        
        logger.info(f"Impressão enviada com sucesso em {elapsed_time:.2f}s: {job_info}")
        
        return {
            'status': 'success',
            'job_info': job_info,
            'printer': printer_name,
            'file': file_path,
            'copies': copies,
            'file_size': file_size,
            'elapsed_time': elapsed_time
        }
        
    except subprocess.TimeoutExpired:
        error_msg = "Timeout na impressão (30s)"
        logger.error(error_msg)
        raise RuntimeError(error_msg)
    except subprocess.CalledProcessError as e:
        error_msg = f"Erro na impressão: {e.stderr.strip() if e.stderr else str(e)}"
        logger.error(error_msg)
        raise RuntimeError(error_msg)

def check_printer_status(printer_name=None):
    """Check printer status"""
    try:
        if printer_name:
            cmd = ['lpstat', '-p', printer_name]
        else:
            cmd = ['lpstat', '-p']
            
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        status_info = result.stdout.strip()
        logger.info(f"Status da impressora: {status_info}")
        
        return status_info
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Erro ao verificar status: {e}")
        return None

def check_print_queue(printer_name=None):
    """Check print queue status"""
    try:
        if printer_name:
            cmd = ['lpstat', '-o', printer_name]
        else:
            cmd = ['lpstat', '-o']
            
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            queue_info = result.stdout.strip()
            if queue_info:
                logger.info(f"Fila de impressão: {queue_info}")
                return queue_info
            else:
                logger.info("Fila de impressão vazia")
                return "Fila vazia"
        else:
            return "Erro ao verificar fila"
            
    except Exception as e:
        logger.error(f"Erro ao verificar fila: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description='Kiosk Print System - PDF Printer')
    parser.add_argument('file_path', nargs='?', help='Caminho para o arquivo PDF')
    parser.add_argument('-p', '--printer', help='Nome da impressora (opcional)')
    parser.add_argument('-c', '--copies', type=int, default=1, help='Número de cópias')
    parser.add_argument('-s', '--status', action='store_true', help='Verificar status da impressora')
    parser.add_argument('-l', '--list', action='store_true', help='Listar impressoras disponíveis')
    parser.add_argument('-q', '--queue', action='store_true', help='Verificar fila de impressão')
    parser.add_argument('--check-cups', action='store_true', help='Verificar serviço CUPS')
    
    args = parser.parse_args()
    
    try:
        if args.check_cups:
            if check_cups_service():
                print("✅ Serviço CUPS está em execução")
                return 0
            else:
                print("❌ Serviço CUPS não está em execução")
                return 1
        
        if args.list:
            printers = list_available_printers()
            if printers:
                print("Impressoras disponíveis:")
                for printer in printers:
                    print(f"  - {printer}")
                    
                # Also show default printer
                default = get_default_printer()
                if default:
                    print(f"\nImpressora padrão: {default}")
            else:
                print("Nenhuma impressora encontrada")
            return 0
        
        if args.status:
            status = check_printer_status(args.printer)
            if status:
                print(status)
            return 0
            
        if args.queue:
            queue = check_print_queue(args.printer)
            if queue:
                print(queue)
            return 0
        
        if not args.file_path:
            parser.print_help()
            return 1
        
        # Print the PDF
        result = print_pdf(args.file_path, args.printer, args.copies)
        
        print(f"✅ Impressão concluída:")
        print(f"   Arquivo: {result['file']}")
        print(f"   Impressora: {result['printer']}")
        print(f"   Cópias: {result['copies']}")
        print(f"   Tamanho: {result['file_size']} bytes")
        print(f"   Tempo: {result['elapsed_time']:.2f}s")
        print(f"   Job: {result['job_info']}")
        
        return 0
        
    except Exception as e:
        logger.error(f"Erro: {e}")
        print(f"❌ Erro: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
