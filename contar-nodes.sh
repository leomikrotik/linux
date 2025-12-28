#!/bin/bash

# Script de Monitoramento de Nodes PNETLab/QEMU
# Autor: Assistente Claude
# Descrição: Lista e monitora processos QEMU em execução

echo "=========================================="
echo "  Monitor de Nodes PNETLab/QEMU"
echo "=========================================="
echo ""

# Conta quantos processos QEMU estão rodando
total_nodes=$(ps aux | grep -E 'qemu.*system' | grep -v grep | wc -l)

echo "Total de Nodes em Execução: $total_nodes"
echo ""

if [ $total_nodes -eq 0 ]; then
    echo "Nenhum node está em execução no momento."
    exit 0
fi

echo "=========================================="
echo "  Detalhes dos Nodes"
echo "=========================================="
echo ""

# Formato: PID | Nome | CPU% | MEM% | RAM(MB) | Tempo
printf "%-8s %-30s %-8s %-8s %-12s %-10s\n" "PID" "Nome do Node" "CPU%" "MEM%" "RAM(MB)" "Tempo"
echo "--------------------------------------------------------------------------------"

# Lista cada processo QEMU com informações detalhadas
ps aux | grep -E 'qemu.*system' | grep -v grep | while read line; do
    # Extrai informações do ps
    pid=$(echo $line | awk '{print $2}')
    cpu=$(echo $line | awk '{print $3}')
    mem=$(echo $line | awk '{print $4}')
    time=$(echo $line | awk '{print $10}')
    
    # Calcula memória em MB
    mem_kb=$(ps -p $pid -o rss= 2>/dev/null)
    if [ ! -z "$mem_kb" ]; then
        mem_mb=$((mem_kb / 1024))
    else
        mem_mb=0
    fi
    
    # Tenta extrair o nome do node do comando
    cmd=$(ps -p $pid -o cmd= 2>/dev/null)
    node_name=$(echo "$cmd" | grep -oP '(?<=-name )[^ ]+' | head -1)
    
    # Se não encontrar nome, tenta pegar do UUID ou mostra "Unknown"
    if [ -z "$node_name" ]; then
        node_name=$(echo "$cmd" | grep -oP '(?<=-uuid )[^ ]+' | head -1)
        if [ -z "$node_name" ]; then
            node_name="Node_$pid"
        fi
    fi
    
    # Trunca nome longo
    if [ ${#node_name} -gt 30 ]; then
        node_name="${node_name:0:27}..."
    fi
    
    printf "%-8s %-30s %-8s %-8s %-12s %-10s\n" "$pid" "$node_name" "$cpu%" "$mem%" "${mem_mb}MB" "$time"
done

echo ""
echo "=========================================="
echo "  Resumo de Recursos"
echo "=========================================="

# Calcula totais
total_cpu=$(ps aux | grep -E 'qemu.*system' | grep -v grep | awk '{sum+=$3} END {printf "%.2f", sum}')
total_mem=$(ps aux | grep -E 'qemu.*system' | grep -v grep | awk '{sum+=$4} END {printf "%.2f", sum}')
total_ram_kb=$(ps aux | grep -E 'qemu.*system' | grep -v grep | awk '{getline; sum+=$6} END {print sum}')
total_ram_mb=$((total_ram_kb / 1024))

echo "CPU Total Utilizada: ${total_cpu}%"
echo "Memória Total Utilizada: ${total_mem}%"
echo "RAM Total Utilizada: ${total_ram_mb}MB"
echo ""

# Informações do sistema
echo "=========================================="
echo "  Informações do Sistema"
echo "=========================================="
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memória Livre: $(free -h | awk 'NR==2{print $4}')"
echo ""