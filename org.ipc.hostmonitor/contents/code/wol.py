#!/usr/bin/env python3
import socket
import sys

mac = sys.argv[1]
mac_bytes = bytes.fromhex(mac.replace(":", ""))
magic = b"\xff" * 6 + mac_bytes * 16
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
s.sendto(magic, ("255.255.255.255", 9))
s.close()
