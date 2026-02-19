'''Handles basic operations of backend server.'''

import subprocess
import os
import socket
import random
import json

class JServerInstance:
    def __init__(self, id: int):
        self.id = id
        self.process, self.ip_addr,self.port = launch_instance()
        self.status = 'running'
        self.clients = []

    def stop(self):
        '''Stops the server instance.'''
        self.status = 'stopped'

    def get_num_players(self):
        '''Returns the number of players currently connected to the server instance.'''
        return len(self.clients)

class JServer:
    def __init__(self):
        self.instances = []
        self.id_counter = 100

    def _next_id(self):
        '''Generates the next unique ID for a new server instance.'''
        self.id_counter += 1
        return self.id_counter

    def create_instance(self):
        '''Creates a new instance of the server.'''
        instance = JServerInstance(self._next_id())
        self.instances.append(instance)
        return instance.id

    def kill_instance(self, instance_id):
        '''Kills a specific server instance by ID.'''
        self.instances = [instance for instance in self.instances if instance.id != instance_id]
    
    def get_instance(self, instance_id):
        '''Retrieves a server instance by ID.'''
        for instance in self.instances:
            if instance.id == instance_id:
                return instance
        return None
    
    def get_all_instances(self):
        '''Returns a list of all server instance ids and number of players.'''
        return [(instance.id, instance.get_num_players()) for instance in self.instances]
    
    def quick_launch(self):
        '''Finds an instance with availability and returns its port.'''
        for instance in self.instances:
            if instance.get_num_players() < 4: # Assuming max 4 players per instance
                return (instance.ip_addr, instance.port)
        # If no instance has availability, create a new one
        new_instance_id = self.create_instance()
        new_instance = self.get_instance(new_instance_id)
        return (new_instance.ip_addr, new_instance.port)
    

def launch_instance():
    godot_path = "godot4"  # "godot" must be in PATH
    relative_instance_path = "~/Jesvilemys/"
    instance_path = os.path.expanduser(relative_instance_path)

    # Path to the scene you want to load (relative to project root)
    scene_path = "res://scenes/world.tscn"

    # Get the ip address
    with open("../config.json") as f:
        config = json.load(f)

    SERVER_IP = config["server_ip"]

    # Find a random open port
    port = random.randint(50000, 60000)
    while is_port_in_use(SERVER_IP, port):
        port = random.randint(50000, 60000)

    print(f"Launching: {godot_path} --headless --path {instance_path} {scene_path} -- --ip_addr={SERVER_IP}")

    # Launch headless Godot
    process = subprocess.Popen([
        godot_path,
        "--headless",            # Run without rendering (no window)
        "--path", instance_path, # Specify project path
        scene_path,               # Scene to load
        "--",
        f"--ip_addr={SERVER_IP}",
        f"--port={port}",
        "--server"
    ])
    return (process, SERVER_IP, port)

def is_port_in_use(host: str, port: int) -> bool:
    """Check if a TCP port on a given host is in use."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(2) # Set a timeout to avoid hanging indefinitely
        result = s.connect_ex((host, port))
        return result == 0
    
def init_server():
    '''Initializes the server.'''
    server = JServer()
    instance_id = server.create_instance()
    print(f"Created server instance with ID: {instance_id}")
    print("All instances:", server.get_all_instances())

    return server