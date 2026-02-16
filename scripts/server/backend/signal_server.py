import asyncio
import websockets
import json

# Store connected clients
clients = {}

async def handle_client(websocket):
    client_id = id(websocket)
    clients[client_id] = websocket
    print(f"Client {client_id} connected. Total clients: {len(clients)}")
    
    try:
        async for message in websocket:
            data = json.loads(message)
            print(f"Received from {client_id}: {data.get('type', 'unknown')}")
            
            # Broadcast signaling data to all other clients
            for cid, client in clients.items():
                if cid != client_id:
                    try:
                        await client.send(message)
                    except:
                        pass
                        
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        del clients[client_id]
        print(f"Client {client_id} disconnected. Total clients: {len(clients)}")

async def main():
    print("WebRTC Signaling Server starting on ws://localhost:9080")
    async with websockets.serve(handle_client, "0.0.0.0", 9080):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())