import asyncio
import websockets
import json

async def test_client(client_name):
    uri = "ws://192.168.1.202:9080"
    
    try:
        async with websockets.connect(uri) as websocket:
            print(f"[{client_name}] Connected to {uri}")
            
            # Send a test message
            test_message = {
                "type": "test",
                "from": client_name,
                "message": f"Hello from {client_name}"
            }
            await websocket.send(json.dumps(test_message))
            print(f"[{client_name}] Sent: {test_message}")
            
            # Listen for messages for 10 seconds
            try:
                async with asyncio.timeout(10):
                    while True:
                        message = await websocket.recv()
                        data = json.loads(message)
                        print(f"[{client_name}] Received: {data}")
            except asyncio.TimeoutError:
                print(f"[{client_name}] Test timeout reached")
                
    except Exception as e:
        print(f"[{client_name}] Error: {e}")

async def run_multiple_clients():
    # Run multiple clients simultaneously to test broadcasting
    await asyncio.gather(
        test_client("Client1"),
        test_client("Client2"),
        test_client("Client3")
    )

if __name__ == "__main__":
    print("Starting WebSocket test clients...")
    asyncio.run(run_multiple_clients())