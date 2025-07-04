#!/bin/bash
# add-copy-buttons.sh

# Função para verificar se o arquivo já tem botões funcionais
has_copy_buttons() {
    local html_file="$1"
    
    # Verificar se existe tanto o CSS quanto o JavaScript dos botões
    if grep -q "code-container" "$html_file" && grep -q "copyCode" "$html_file" && grep -q "copy-button" "$html_file"; then
        return 0  # Tem botões
    else
        return 1  # Não tem botões
    fi
}

# Função para adicionar botões de copiar aos blocos de código
add_copy_buttons() {
    local html_file="$1"
    
    echo "Adicionando botões de copiar em: $html_file"
    
    # Usar Python diretamente com o CSS/JS inline
    python3 << EOF
import re
import os

html_file = "$html_file"

# CSS e JavaScript inline
css_js = '''
<style>
.code-container {
    position: relative;
    margin: 16px 0;
}
.copy-button {
    position: absolute;
    top: 8px;
    right: 8px;
    background: rgba(0, 0, 0, 0.7);
    color: #ffffff;
    border: none;
    padding: 4px 8px;
    border-radius: 3px;
    cursor: pointer;
    font-size: 10px;
    font-family: monospace;
    opacity: 0.8;
    transition: all 0.2s ease;
    z-index: 1000;
    user-select: none;
    font-weight: bold;
}
.copy-button:hover {
    opacity: 1;
    background: rgba(0, 0, 0, 0.9);
    transform: scale(1.05);
}
.copy-button.copied {
    background: rgba(76, 175, 80, 0.9);
    color: #ffffff;
}
</style>
<script>
function copyCode(button) {
    const container = button.parentElement;
    const codeBlock = container.querySelector("pre code") || container.querySelector("pre");
    const text = codeBlock.innerText || codeBlock.textContent;
    
    navigator.clipboard.writeText(text).then(() => {
        button.textContent = "✓ OK";
        button.classList.add("copied");
        
        setTimeout(() => {
            button.textContent = "COPY";
            button.classList.remove("copied");
        }, 1500);
    }).catch(err => {
        // Fallback para navegadores mais antigos
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.position = "fixed";
        textArea.style.left = "-9999px";
        document.body.appendChild(textArea);
        textArea.select();
        try {
            document.execCommand('copy');
            button.textContent = "✓ OK";
            button.classList.add("copied");
            setTimeout(() => {
                button.textContent = "COPY";
                button.classList.remove("copied");
            }, 1500);
        } catch (fallbackErr) {
            button.textContent = "ERR";
            setTimeout(() => {
                button.textContent = "COPY";
            }, 1500);
        }
        document.body.removeChild(textArea);
    });
}
</script>
'''

try:
    # Ler arquivo HTML
    with open(html_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Adicionar CSS/JS antes de </head>
    content = content.replace('</head>', css_js + '</head>')

    # Processar blocos <pre> preservando a estrutura interna
    def add_button_to_pre(match):
        pre_content = match.group(0)
        # Envolver o <pre> completo em um container e adicionar botão
        return f'<div class="code-container"><button class="copy-button" onclick="copyCode(this)">COPY</button>{pre_content}</div>'

    # Encontrar todos os blocos <pre>...</pre> (incluindo conteúdo multilinha)
    content = re.sub(r'<pre[^>]*>.*?</pre>', add_button_to_pre, content, flags=re.DOTALL)

    # Escrever arquivo modificado
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Processamento Python concluído com sucesso")

except Exception as e:
    print(f"Erro no processamento Python: {e}")
    exit(1)
EOF
    
    echo "Botões de copiar adicionados com sucesso!"
}

# Encontrar todos os arquivos index.html nos diretórios de codelabs
find_and_process() {
    local base_dir="${1:-./site/codelabs}"
    
    echo "Procurando arquivos index.html em: $base_dir"
    
    # Encontrar todos os arquivos index.html
    find "$base_dir" -name "index.html" -type f | while read -r html_file; do
        echo "Processando: $html_file"
        
        # Verificar se já tem botões funcionais
        if has_copy_buttons "$html_file"; then
            echo "  ✓ Botões já existem e funcionais - pulando: $html_file"
            continue
        fi
        
        echo "  ➕ Arquivo sem botões - adicionando: $html_file"
        
        # Criar backup se não existir
        if [ ! -f "$html_file.backup" ]; then
            cp "$html_file" "$html_file.backup"
        fi
        
        # Adicionar os botões
        add_copy_buttons "$html_file"
    done
    
    echo "Processamento concluído!"
}

# Executar processamento inteligente
find_and_process "$1"