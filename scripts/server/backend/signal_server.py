import asyncio
import json
import websockets
from typing import Set
import server
import ssl

class PortAllocator:
    def __init__(self):
        self.jserver = server.init_server()  # Initialize the JServer instance
    
    def allocate_port(self):
        '''Return port and IP address of an available server instance.'''
        ip_addr, port = self.jserver.quick_launch()  # Ensure we have an instance with an allocated port
        
        return (ip_addr, port)

# Global port allocator
port_allocator = PortAllocator()

async def handle_client(websocket):
    """Handle incoming WebSocket connections."""
    client_address = websocket.remote_address
    print(f"Client connected from {client_address}")
    print(f"Headers: {websocket.request.headers}")
    
    allocated_port = None
    
    try:
        print("Ready to read messages")
        async for message in websocket:
            print(f"Received message: {message}")
            try:
                # Parse incoming JSON message
                data = json.loads(message)
                print(f"Received message from {client_address}: {data}")
                action = data.get("action")
                
                if action == "request_port":
                    # Allocate a port
                    allocated_ip, allocated_port = port_allocator.allocate_port()
                    
                    # Send response
                    response = {
                        "status": "success",
                        "ip_addr": allocated_ip,
                        "port": allocated_port
                    }
                    await websocket.send(json.dumps(response))
                    print(f"Allocated port {allocated_port} to {client_address}")
                
                
                else:
                    # Unknown action
                    response = {
                        "status": "error",
                        "message": f"Unknown action: {action}"
                    }
                    await websocket.send(json.dumps(response))
                    
            except json.JSONDecodeError:
                print("Invalid JSON received")
                error_response = {
                    "status": "error",
                    "message": "Invalid JSON format"
                }
                await websocket.send(json.dumps(error_response))
            
            except Exception as e:
                print(f"Error handling message from {client_address}: {e}")
                error_response = {
                    "status": "error",
                    "message": str(e)
                }
                await websocket.send(json.dumps(error_response))
                print(f"Error handling message: {e}")
    
    finally:
        print(f"Client {client_address} disconnected")

async def main():
    """Start the WebSocket server."""
    host = "0.0.0.0"  # Listen on all interfaces
    port = 8080
    
    # Create SSL context
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(
        certfile="keys/fullchain.pem",  # or cert.pem
        keyfile="keys/privkey.pem"
    )

    print(f"Starting WSS server on {host}:{port}")
    
    async with websockets.serve(handle_client, host, port, ssl=ssl_context):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutting down server...")