import asyncio
import os
import signal
import socket
import aiohttp

async def stop_existing_ollama():
    """Stop any running Ollama service or processes before starting a new one."""
    try:
        proc = await asyncio.create_subprocess_exec('systemctl', 'is-active', '--quiet', 'ollama')
        status = await proc.wait()
        if status == 0:
            print("🔴 Ollama system service is active. Stopping and disabling...")

            stop_proc = await asyncio.create_subprocess_exec('sudo', 'systemctl', 'stop', 'ollama')
            await stop_proc.wait()

            disable_proc = await asyncio.create_subprocess_exec('sudo', 'systemctl', 'disable', 'ollama')
            await disable_proc.wait()

            print("✅ Ollama service stopped and disabled.")
    except Exception as e:
        # Likely not a Linux systemd environment or no permissions
        print(f"⚠️ Could not check or stop systemd service: {e}")

    # Then kill any manually started serve processes
    try:
        proc = await asyncio.create_subprocess_exec('pkill', '-f', 'ollama serve')
        await proc.wait()
        print("🔪 Killed any existing 'ollama serve' processes.")
    except Exception as e:
        print(f"⚠️ Failed to kill existing 'ollama serve' processes: {e}")
    await asyncio.sleep(2)

async def kill_process_on_port(port):
    """Kill process listening on the given port."""
    try:
        proc = await asyncio.create_subprocess_exec(
            'lsof', '-t', f'-i:{port}',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()
        if stdout:
            pids = stdout.decode().strip().split('\n')
            for pid in pids:
                print(f"🔪 Killing process on port {port}: PID {pid}")
                os.kill(int(pid), signal.SIGKILL)
            await asyncio.sleep(2)
    except Exception as e:
        print(f"⚠️ Failed to kill process on port {port}: {e}")

async def is_port_free(port):
    """Check if the port is free."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) != 0

async def wait_for_server(port, timeout=30):
    """Wait until the server on the given port is responsive."""
    url = f"http://localhost:{port}/"
    async with aiohttp.ClientSession() as session:
        for _ in range(timeout):
            try:
                async with session.get(url) as response:
                    if response.status == 200:
                        print(f"✅ Ollama server is ready on port {port}.")
                        return True
            except Exception:
                pass
            print(f"⌛ Waiting for Ollama server to be ready on port {port}...")
            await asyncio.sleep(1)
    print(f"❌ Ollama server did not become ready within {timeout} seconds.")
    return False

async def start_ollama():
    """Start ollama serve in the background."""
    print("🛑 Checking if port 11434 is in use...")
    if not await is_port_free(11434):
        await kill_process_on_port(11434)

    if not await is_port_free(11434):
        print("❌ Port 11434 is STILL occupied after trying to free it. Aborting.")
        return False
    else:
        print("✅ Port 11434 is free.")

    print("🚀 Starting Ollama using nohup (ollama serve)...")
    process = await asyncio.create_subprocess_shell(
        "nohup ollama serve > ollama_start.log 2>&1 &",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    await process.communicate()
    print("✅ Ollama serve command issued successfully.")

    # Actively wait for the server to be ready
    server_ready = await wait_for_server(11434)
    return server_ready

async def run_ollama_commands():
    """Run post-startup Ollama commands."""
    commands = [
        ['ollama', 'list'],
        ['ollama', 'run', 'mistral'],
        ['ollama', 'run', 'deepseek-coder'],
        ['ollama', 'run', 'llava'],
        ['ollama', 'run', 'wizard-vicuna-uncensored'],
    ]

    for cmd in commands:
        print('>>> Executing:', ' '.join(cmd))
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()
        if stdout:
            print(stdout.decode())
        if stderr:
            print(stderr.decode())

async def main():
    await stop_existing_ollama()
    started = await start_ollama()
    if started:
        await run_ollama_commands()
    else:
        print("❌ Ollama did not start correctly, skipping running commands.")

if __name__ == "__main__":
    asyncio.run(main())
