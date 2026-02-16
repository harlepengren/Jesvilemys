import asyncio
import json
import websockets
from typing import Set

class PortAllocator:
    def __init__(self, start_port: int = 7000, end_port: int = 8000):
        self.start_port = start_port
        self.end_port = end_port
        self.allocated_ports: Set[int] = set()
        self.current_port = start_port
    
    def allocate_port(self) -> int:
        """Allocate the next available port."""
        # Find next available port
        while self.current_port in self.allocated_ports:
            self.current_port += 1
            if self.current_port > self.end_port:
                self.current_port = self.start_port
        
        port = self.current_port
        self.allocated_ports.add(port)
        self.current_port += 1
        
        return port
    
    def release_port(self, port: int):
        """Release a port back to the pool."""
        if port in self.allocated_ports:
            self.allocated_ports.remove(port)
            print(f"Released port {port}")

# Global port allocator
port_allocator = PortAllocator()

async def handle_client(websocket):
    """Handle incoming WebSocket connections."""
    client_address = websocket.remote_address
    print(f"Client connected from {client_address}")
    
    allocated_port = None
    
    try:
        async for message in websocket:
            try:
                # Parse incoming JSON message
                data = json.loads(message)
                action = data.get("action")
                
                if action == "request_port":
                    # Allocate a port
                    allocated_port = port_allocator.allocate_port()
                    
                    # Send response
                    response = {
                        "status": "success",
                        "port": allocated_port
                    }
                    await websocket.send(json.dumps(response))
                    print(f"Allocated port {allocated_port} to {client_address}")
                
                elif action == "release_port":
                    # Release a previously allocated port
                    port_to_release = data.get("port")
                    if port_to_release:
                        port_allocator.release_port(port_to_release)
                        response = {
                            "status": "success",
                            "message": f"Port {port_to_release} released"
                        }
                        await websocket.send(json.dumps(response))
                
                else:
                    # Unknown action
                    response = {
                        "status": "error",
                        "message": f"Unknown action: {action}"
                    }
                    await websocket.send(json.dumps(response))
                    
            except json.JSONDecodeError:
                error_response = {
                    "status": "error",
                    "message": "Invalid JSON format"
                }
                await websocket.send(json.dumps(error_response))
            
            except Exception as e:
                error_response = {
                    "status": "error",
                    "message": str(e)
                }
                await websocket.send(json.dumps(error_response))
                print(f"Error handling message: {e}")
    
    finally:
        # Clean up: release the port when client disconnects
        if allocated_port:
            port_allocator.release_port(allocated_port)
        print(f"Client {client_address} disconnected")

async def main():
    """Start the WebSocket server."""
    host = "0.0.0.0"  # Listen on all interfaces
    port = 8080
    
    print(f"Starting WebSocket server on {host}:{port}")
    print(f"Allocating ports in range {port_allocator.start_port}-{port_allocator.end_port}")
    
    async with websockets.serve(handle_client, host, port):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutting down server...")