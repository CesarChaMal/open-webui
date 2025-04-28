import os
import asyncio
import time
import requests
from dotenv import load_dotenv
from pyngrok import ngrok, conf

load_dotenv()

async def wait_for_backend(url, timeout=30):
    print(f"🛠️ Waiting for backend {url} to become ready...")
    start = time.time()
    while time.time() - start < timeout:
        try:
            response = requests.get(url)
            if response.status_code == 200:
                print("✅ Backend is up!")
                return True
        except requests.exceptions.RequestException:
            pass
        await asyncio.sleep(1)
    print("⚠️ Backend did not become ready in time.")
    return False

async def ngrok_watchdog(public_url):
    print(f"👀 Starting ngrok watchdog for {public_url}...")

    while True:
        try:
            # Check ngrok local API
            response = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=5)
            tunnels_info = response.json()
            active_urls = [tunnel['public_url'] for tunnel in tunnels_info.get('tunnels', [])]

            if public_url not in active_urls:
                print(f"❌ Tunnel {public_url} missing from active tunnels, reconnecting...")
                return False  # trigger reconnection

            # Optionally, ping the public URL
            response = requests.get(public_url, timeout=5)
            if response.status_code != 200:
                print(f"⚠️ Unexpected status {response.status_code} from {public_url}, reconnecting...")
                return False

        except Exception as e:
            print(f"❌ Error during ngrok watchdog check: {e}. Reconnecting...")
            return False

        await asyncio.sleep(15)

async def create_ngrok_tunnel():
    ngrok_token = os.getenv('NGROK_AUTHTOKEN')
    if not ngrok_token:
        print("NGROK_AUTHTOKEN is not set in .env!")
        return None

    ngrok.set_auth_token(ngrok_token)

    # Save ngrok logs inside the project folder
    log_file_path = os.path.join(os.getcwd(), "ngrok.log")

    ngrok_config = conf.PyngrokConfig(
        log_event_callback=lambda event: open(log_file_path, "a").write(str(event) + "\n")
    )

    max_retries = 5
    retry_delay = 5  # seconds

    for attempt in range(max_retries):
        try:
            tunnel = ngrok.connect(8080, "http", pyngrok_config=ngrok_config)
            print(f"✅ Tunnel established: {tunnel.public_url}")
            return tunnel
        except Exception as e:
            print(f"⚠️ Attempt {attempt + 1} failed: {e}")
            await asyncio.sleep(retry_delay)
    print("❌ Failed to establish tunnel after multiple attempts.")
    return None

async def main():
    backend_ready = await wait_for_backend("http://localhost:8080")
    if not backend_ready:
        print("❌ Backend is not ready! Exiting without creating Ngrok tunnel.")
        return

    tunnel = await create_ngrok_tunnel()
    if not tunnel:
        return

    public_url = tunnel.public_url

    # Update .env
    env_path = ".env"
    with open(env_path, "r") as file:
        lines = file.readlines()
    lines = [line for line in lines if not line.startswith("NGROK_URL=")]
    lines.append(f"NGROK_URL={public_url}\n")
    with open(env_path, "w") as file:
        file.writelines(lines)

    print(f"🌍 Your Public URL: {public_url}")

    if backend_ready:
        os.system("curl http://localhost:11434 | pygmentize -l console || true")
        os.system("curl http://localhost:8080 | pygmentize -l console || true")
        os.system(f"curl {public_url} | pygmentize -l console || true")
    else:
        print("❌ Skipping curl commands because backend isn't responding.")


    # Update .env with new URL
    with open(env_path, "r") as file:
        lines = file.readlines()
    lines = [line for line in lines if not line.startswith("NGROK_URL=")]
    lines.append(f"NGROK_URL={public_url}\n")
    with open(env_path, "w") as file:
        file.writelines(lines)

    # Start watchdog
    while True:
        tunnel_ok = await ngrok_watchdog(public_url)
        if not tunnel_ok:
            print("♻️ Reconnecting tunnel...")
            try:
                ngrok.disconnect(public_url)
            except Exception as e:
                print(f"⚠️ Could not disconnect cleanly: {e}")
            tunnel = await create_ngrok_tunnel()
            if not tunnel:
                print("❌ Could not recreate tunnel. Exiting...")
                break
    #         public_url = tunnel.public_url

if __name__ == "__main__":
    asyncio.run(main())
