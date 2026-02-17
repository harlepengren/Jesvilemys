import asyncio
import json
import websockets

SERVER_URL = "ws://192.168.1.202:8080"
DELAY_SECONDS = 5  # Simulate a slow client by waiting before reading the response

async def slow_client():
    print(f"Connecting to {SERVER_URL}...")
    async with websockets.connect(SERVER_URL) as websocket:
        print("Connected.")

        request = json.dumps({"action": "request_port"})
        await websocket.send(request)
        print(f"Sent request. Waiting {DELAY_SECONDS} seconds before reading response...")

        await asyncio.sleep(DELAY_SECONDS)

        response = await websocket.recv()
        print(f"Received response: {response}")

if __name__ == "__main__":
    asyncio.run(slow_client())