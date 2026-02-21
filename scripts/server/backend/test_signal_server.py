import asyncio
import json
import websockets
import ssl
import certifi

SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())

uri = "wss://jesvilemys.com:8080"

async def test_port_request():
    """Test requesting a port from the server."""
     
    print(f"Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri, ssl=SSL_CONTEXT) as websocket:
            print("Connected successfully!")
            
            # Test 1: Request a port
            print("\n--- Test 1: Requesting a port ---")
            request = {"action": "request_port"}
            await websocket.send(json.dumps(request))
            print(f"Sent: {request}")
            
            response = await websocket.recv()
            print(f"Received: {response}")
            
            data = json.loads(response)
            if data.get("status") == "success":
                allocated_port = data.get("port")
                print(f"✓ Successfully allocated port: {allocated_port}")
            else:
                print(f"✗ Error: {data.get('message')}")
            
            # Wait a moment
            await asyncio.sleep(1)
            
            # Test 2: Try to release the port
            if allocated_port:
                print("\n--- Test 2: Releasing the port ---")
                release_request = {
                    "action": "release_port",
                    "port": allocated_port
                }
                await websocket.send(json.dumps(release_request))
                print(f"Sent: {release_request}")
                
                response = await websocket.recv()
                print(f"Received: {response}")
                
                data = json.loads(response)
                if data.get("status") == "success":
                    print(f"✓ Successfully released port: {allocated_port}")
                else:
                    print(f"✗ Error: {data.get('message')}")
            
            # Test 3: Invalid action
            print("\n--- Test 3: Testing invalid action ---")
            invalid_request = {"action": "invalid_action"}
            await websocket.send(json.dumps(invalid_request))
            print(f"Sent: {invalid_request}")
            
            response = await websocket.recv()
            print(f"Received: {response}")
            
            # Test 4: Invalid JSON
            print("\n--- Test 4: Testing invalid JSON ---")
            await websocket.send("this is not json")
            print("Sent: this is not json")
            
            response = await websocket.recv()
            print(f"Received: {response}")
            
            print("\n✓ All tests completed!")
            
    except websockets.exceptions.WebSocketException as e:
        print(f"✗ WebSocket error: {e}")
    except ConnectionRefusedError:
        print(f"✗ Connection refused. Is the server running at {uri}?")
    except Exception as e:
        print(f"✗ Unexpected error: {e}")

async def test_multiple_clients():
    """Test multiple clients requesting ports simultaneously."""
    num_clients = 5
    
    print(f"\n\n--- Testing {num_clients} simultaneous clients ---")
    
    async def request_port(client_id):
        try:
            async with websockets.connect(uri, ssl=SSL_CONTEXT) as websocket:
                request = {"action": "request_port"}
                await websocket.send(json.dumps(request))
                
                response = await websocket.recv()
                data = json.loads(response)
                
                if data.get("status") == "success":
                    port = data.get("port")
                    print(f"Client {client_id}: Allocated port {port}")
                    return port
                else:
                    print(f"Client {client_id}: Error - {data.get('message')}")
                    return None
                    
        except Exception as e:
            print(f"Client {client_id}: Error - {e}")
            return None
    
    # Create multiple client tasks
    tasks = [request_port(i) for i in range(num_clients)]
    ports = await asyncio.gather(*tasks)
    
    # Check for duplicate ports
    valid_ports = [p for p in ports if p is not None]
    if len(valid_ports) == len(set(valid_ports)):
        print(f"✓ All {len(valid_ports)} ports are unique!")
    else:
        print(f"✗ Warning: Duplicate ports detected!")
    
    print(f"Allocated ports: {sorted(valid_ports)}")

async def test_connection_lifecycle():
    """Test that ports are released when connection closes."""
    
    print("\n\n--- Testing connection lifecycle ---")
    
    # Connect and get a port
    print("Client 1: Connecting and requesting port...")
    async with websockets.connect(uri, ssl=SSL_CONTEXT) as websocket:
        request = {"action": "request_port"}
        await websocket.send(json.dumps(request))
        response = await websocket.recv()
        data = json.loads(response)
        port1 = data.get("port")
        print(f"Client 1: Got port {port1}")
    
    print("Client 1: Disconnected (port should be released)")
    
    # Wait a moment
    await asyncio.sleep(0.5)
    
    # Connect again and see if we can get the same port
    print("Client 2: Connecting and requesting port...")
    async with websockets.connect(uri, ssl=SSL_CONTEXT) as websocket:
        request = {"action": "request_port"}
        await websocket.send(json.dumps(request))
        response = await websocket.recv()
        data = json.loads(response)
        port2 = data.get("port")
        print(f"Client 2: Got port {port2}")
    
    if port1 == port2:
        print(f"✓ Port {port1} was successfully recycled!")
    else:
        print(f"Port changed from {port1} to {port2} (also valid)")

async def main():
    """Run all tests."""
    print("=" * 60)
    print("WebSocket Port Server Test Suite")
    print("=" * 60)
    
    # Run basic tests
    await test_port_request()
    
    # Run multiple client test
    await test_multiple_clients()
    
    # Run lifecycle test
    await test_connection_lifecycle()
    
    print("\n" + "=" * 60)
    print("Test suite complete!")
    print("=" * 60)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\nTests interrupted by user")