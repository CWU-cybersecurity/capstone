import os
import socket

def receive_key():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        port = 12345 # target port number here
        host = '' # inaddr_any
        serv_sock.bind((host, port))
        serv_sock.listen(2)
        conn,addr = serv_sock.accept()
        while True:
            with conn:
                data = conn.recv(128)
                if data:
                    print(f"received key: {data}")
                    with open("keyfile.key", "wb") as keyfile:
                        keyfile.write(data)
                else:
                    print("failed to receive keyfile")
        

if __name__ == "__main__":
    receive_key()

