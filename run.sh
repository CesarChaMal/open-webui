#!/bin/bash

set -e

detect_os() {
    UNAME_OUT="$(uname -s)"

    case "${UNAME_OUT}" in
        Linux*)
            if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
                echo "🧠 Detected: WSL (Windows Subsystem for Linux)"
                OS_TYPE="WSL"
            elif grep -qEi "(Pop!_OS|pop-os)" /etc/os-release &> /dev/null; then
                echo "🐧 Detected: Pop!_OS"
                OS_TYPE="LINUX"
            else
                echo "🐧 Detected: Generic Linux (e.g., Ubuntu)"
                OS_TYPE="LINUX"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "🪟 Detected: Git Bash on Windows"
            OS_TYPE="GITBASH"
            ;;
        Darwin*)
            echo "🍏 Detected: macOS (unsupported)"
            OS_TYPE="MAC"
            ;;
        *)
            echo "❓ Unknown OS type: ${UNAME_OUT}"
            OS_TYPE="UNKNOWN"
            ;;
    esac
}

uninstall_ollama() {
    echo "🔴 Uninstalling old Ollama..."

    if [[ "$OS_TYPE" == "GITBASH" ]]; then
        echo "⚠️ Detected Git Bash. Skipping service stop and user deletion."
        echo "🛠️ Only cleaning binaries..."
        which ollama >/dev/null 2>&1 && sudo rm -f $(which ollama)
        return
    fi

    if [[ "$OS_TYPE" == "WSL" ]]; then
        echo "⚠️ Detected WSL. systemctl is not available. Skipping service stop."
        # Kill any Ollama processes directly
        pgrep ollama | xargs -r sudo kill -9 2>/dev/null || true
    else
        echo "🛠️ Stopping and disabling Ollama service (Linux)..."
        sudo systemctl stop ollama 2>/dev/null || true
        sudo systemctl disable ollama 2>/dev/null || true
        pgrep ollama | xargs -r sudo kill -9 2>/dev/null || true
    fi

    echo "🗑️ Removing Ollama files and user..."
    sudo rm -f /etc/systemd/system/ollama.service || true
    sudo rm -f $(which ollama) 2>/dev/null || true
    sudo rm -rf /usr/share/ollama || true
    sudo userdel ollama 2>/dev/null || true

    echo "✅ Ollama uninstalled successfully."
}

install_ollama() {
    echo "🟢 Installing Ollama..."

    curl -fsSL https://ollama.com/install.sh | sh

    echo "🔍 Checking for NVIDIA driver and CUDA toolkit..."

    DRIVER_FOUND=false
    CUDA_FOUND=false

    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "✅ NVIDIA drivers detected (nvidia-smi found)."
        DRIVER_FOUND=true
    else
        echo "⚠️ NVIDIA drivers not detected (missing nvidia-smi)."
    fi

    if command -v nvcc >/dev/null 2>&1; then
        echo "✅ CUDA toolkit detected (nvcc found)."
        CUDA_FOUND=true
    else
        echo "⚠️ CUDA toolkit not detected (missing nvcc)."
    fi

    if [[ "$DRIVER_FOUND" == false || "$CUDA_FOUND" == false ]]; then
        echo "ℹ️ To manually install NVIDIA drivers and CUDA toolkit, follow:"
        echo "🔗 https://developer.nvidia.com/cuda-downloads"
    else
        echo "🎯 GPU environment looks ready!"
    fi
}

stop_ollama_service() {
    echo "🛑 Checking and stopping systemd Ollama service if active..."

    if systemctl is-active --quiet ollama; then
        echo "🔴 Ollama system service is active. Stopping and disabling..."
        sudo systemctl stop ollama
        sudo systemctl disable ollama
        echo "✅ Ollama service stopped and disabled."
    else
        echo "✅ Ollama service is not active."
    fi
}

kill_ollama_processes() {
    echo "🔎 Searching for running Ollama serve processes..."
    OLLAMA_PIDS=$(ps aux | grep '[o]llama' | grep serve | awk '{print $2}')

    if [ -n "$OLLAMA_PIDS" ]; then
        echo "🔪 Killing ollama serve processes: $OLLAMA_PIDS"
        sudo kill -9 $OLLAMA_PIDS
        sleep 2
        echo "✅ Killed existing Ollama serve processes."
    else
        echo "✅ No running Ollama serve processes found."
    fi

    echo "🔪 Killing any running Ollama serve processes..."
    if lsof -i :11434 >/dev/null 2>&1; then
        echo "⚠️ Port 11434 is in use. Trying to kill the process..."
        PID_TO_KILL=$(lsof -t -i :11434)
        if [ -n "$PID_TO_KILL" ]; then
            echo "🔪 Killing PID $PID_TO_KILL holding port 11434..."
            kill -9 "$PID_TO_KILL"
            sleep 2
        fi
    fi
}

start_ollama() {
    echo "🟢 Starting Ollama services..."

    stop_ollama_service
    kill_ollama_processes

    # Final check to confirm port is free
    if lsof -i :11434 >/dev/null 2>&1; then
        echo "❌ Port 11434 is STILL occupied even after trying to free it. Aborting start!"
        lsof -i :11434
        exit 1
    else
        echo "✅ Port 11434 is free."
    fi

    echo "🚀 Starting Ollama using nohup (ollama serve)..."
    nohup ollama serve > ollama_start.log 2>&1 &
    echo "✅ Ollama serve started successfully."

    echo "🕐 Waiting a few seconds for Ollama to boot..."
    sleep 5

    run_ollama_commands

    echo "✅ All Ollama setup commands completed."
}

run_ollama_commands() {
    echo "🛠️ Running Ollama post-start commands..."
    commands=(
        "ollama list"
        "ollama run mistral"
        "ollama run deepseek-coder"
        "ollama run llava"
        "ollama run wizard-vicuna-uncensored"
    )
    for cmd in "${commands[@]}"; do
        echo ">>> Executing: $cmd"
        eval $cmd
    done
}

install_python_packages() {
    echo "📦 Installing Python packages..."
    pip install -U aiohttp pyngrok uvicorn blinker kaleido openai cohere tiktoken python-dotenv fastapi peewee passlib jwt chromadb langchain langchain-community
    cd backend
    pip install -r requirements.txt
    cd ../
}

install_nodejs() {
    echo "🟢 Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
    node -v
    npm -v
}

setup_webui() {
    echo "🌐 Setting up Ollama WebUI..."

    if [ ! -f ".env" ]; then
        if [ -f "example.env" ]; then
            echo "📝 .env not found, copying example.env to .env..."
            cp -RPp example.env .env
        else
            echo "⚠️ Neither .env nor example.env found! Please make sure you cloned ollama-webui or added the correct files."
        fi
    else
        echo "✅ .env file already exists, skipping copy."
    fi

    echo "🧹 Cleaning node_modules and reinstalling packages..."
    rm -rf node_modules package-lock.json

    echo "📦 Installing Node.js packages..."
    npm install

    echo "🏗️ Building WebUI frontend with Vite..."
    npm run build
}

run_ollama_setup_py() {
    echo "⚙️ Running Ollama setup (Python)..."
    touch ollama_start.log
    python3 ollama_setup.py > ollama_start.log 2>&1
}

start_backend_server() {
    echo "🛑 Checking if port 8080 is already in use..."
    if lsof -i :8080 &>/dev/null; then
        echo "🛑 Port 8080 in use. Killing process..."
        lsof -ti :8080 | xargs kill -9
        sleep 2
    fi

    echo "🚀 Starting Uvicorn backend server..."
    cd "$(dirname "$0")"
    cd backend
    PROJECT_ROOT=$(pwd)

    # Force creation of log file explicitly (fully qualified path)
    touch "$PROJECT_ROOT/uvicorn.log"

    nohup bash -c "cd \"$PROJECT_ROOT\" && uvicorn open_webui.main:app --reload --host 0.0.0.0 --port 8080 --forwarded-allow-ips '*'" >> "$PROJECT_ROOT/uvicorn.log" 2>&1 &
    sleep 1  # short initial wait

    # Wait until uvicorn.log exists or timeout
    MAX_WAIT=20
    while [ ! -f "$PROJECT_ROOT/uvicorn.log" ] && [ $MAX_WAIT -gt 0 ]; do
        echo "⌛ Waiting for uvicorn.log to be created..."
        sleep 1
        MAX_WAIT=$((MAX_WAIT - 1))
    done

    if [ ! -f "$PROJECT_ROOT/uvicorn.log" ]; then
        echo "❌ uvicorn.log still missing after timeout!"
    else
        echo "✅ Backend server started successfully (uvicorn.log present)"
    fi

    cd ..
}

run_webui_setup_py() {
    echo "⚙️ Running WebUI and Ngrok setup (Python)..."
    python3 webui_setup.py
}

update_env_file() {
    local env_file=".env"

    OLLAMA_IP="localhost"
    OLLAMA_HOST="http://$OLLAMA_IP:11434"
    OLLAMA_API="http://$OLLAMA_IP:11434/api"

    # Update the .env file
    sed -i "/^OLLAMA_HOST=/c\OLLAMA_HOST=$OLLAMA_HOST" "$env_file"
    sed -i "/^OLLAMA_API_BASE_URL=/c\OLLAMA_API_BASE_URL=$OLLAMA_API" "$env_file"

    echo "✅ Updated .env:"
    echo " - OLLAMA_HOST=$OLLAMA_HOST"
    echo " - OLLAMA_API_BASE_URL=$OLLAMA_API"
}

check_logs() {
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    echo -e "${GREEN}✅ All Done! Dumping logs:${NC}"
    echo "----------------------------------"

    if [ -f "ollama_start.log" ]; then
        echo -e "${YELLOW}📄 ollama_start.log:${NC}"
        tail -n 100 ollama_start.log
        echo "----------------------------------"
    else
        echo "⚠️ ollama_start.log not found."
    fi

    if [ -f "backend/uvicorn.log" ]; then
        echo -e "${YELLOW}📄 uvicorn.log:${NC}"
        tail -n 100 backend/uvicorn.log
        echo "----------------------------------"
    elif [ -f "backend/nohup.out" ]; then
        echo -e "${YELLOW}📄 nohup.out (fallback for uvicorn logs):${NC}"
        tail -n 100 backend/nohup.out
        echo "----------------------------------"
    else
        echo "⚠️ Neither uvicorn.log nor nohup.out found."
    fi

    if [ -f "ngrok.log" ]; then
        echo -e "${YELLOW}📄 ngrok.log:${NC}"
        tail -n 100 ngrok.log
        echo "----------------------------------"
    else
        echo "⚠️ ngrok.log not found."
    fi

    echo -e "${GREEN}🌍 Your Ngrok public URL should be printed above.${NC}"
}

final_message() {
    echo "✅ All Done! Check nohup.out, ollama_start.log, uvicorn.log, and ngrok.log if needed."

    # Show Ngrok Public URL
    if [ -f ".env" ]; then
        NGROK_URL=$(grep "^NGROK_URL=" .env | cut -d'=' -f2-)
        if [ ! -z "$NGROK_URL" ]; then
            echo "🌍 Your Public URL: $NGROK_URL"
        else
            echo "⚠️ Ngrok URL not found in .env!"
        fi
    fi

    # Show internal access link
    if [[ "$OS_TYPE" == "WSL" ]]; then
        ACCESS_IP=$(hostname -I | awk '{print $1}')
        echo "🌐 Internal access from Windows: http://$ACCESS_IP:8000"
    else
        echo "🌐 Access locally via: http://localhost:8000"
    fi
}

### MAIN ###
detect_os
#uninstall_ollama
#install_ollama
#start_ollama
install_python_packages
#install_nodejs
#setup_webui
run_ollama_setup_py
start_backend_server
update_env_file
check_logs
final_message
run_webui_setup_py
