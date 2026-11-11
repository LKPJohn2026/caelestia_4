#!/usr/bin/env python3
import calendar
import os
import sys
import json
import google.auth.transport.requests
import google.oauth2.service_account

def get_token(json_str):
    try:
        # Load the string into a dictionary
        info = json.loads(json_str)
        
        # Initialize credentials
        creds = google.oauth2.service_account.Credentials.from_service_account_info(info)
        scoped_creds = creds.with_scopes(['https://www.googleapis.com/auth/cloud-platform'])
        
        # Refresh to get the access token
        request = google.auth.transport.requests.Request()
        scoped_creds.refresh(request)

        token = scoped_creds.token
        expiry = int(calendar.timegm(scoped_creds.expiry.utctimetuple()))
        
        print(json.dumps({
            "token": token,
            "expiry": expiry
        }))

    except Exception as e:
        sys.stderr.write(f"Error: {str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    # caelestia4: the key comes from $SERVICE_KEY_CONTENT or stdin ("-" or no argument). An argument is still taken,
    # but any process can read another's arguments in /proc, and this is a private key.
    key = os.environ.pop("SERVICE_KEY_CONTENT", "")
    if not key:
        if len(sys.argv) >= 2 and sys.argv[1] != "-":
            key = sys.argv[1]
        elif len(sys.argv) >= 2 or not sys.stdin.isatty():
            key = sys.stdin.read()
    if not key.strip():
        sys.stderr.write("Usage: SERVICE_KEY_CONTENT='<json_string>' token_from_key.py, or the JSON on stdin\n")
        sys.exit(1)
    
    get_token(key)
