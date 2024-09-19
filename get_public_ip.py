#!/usr/bin/env python
import requests
import json

def get_public_ip():
    ip = requests.get('https://ipinfo.io/ip').text.strip()
    return {"public_ip": ip}

if __name__ == "__main__":
    result = get_public_ip()
    print(json.dumps(result))  # Ensure output is a JSON string