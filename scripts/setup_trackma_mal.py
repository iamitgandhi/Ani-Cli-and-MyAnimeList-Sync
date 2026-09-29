#!/usr/bin/env python3
"""
Setup Trackma with a MyAnimeList (MAL) account via OAuth PKCE.

Features:
1. Generates an OAuth 2.0 PKCE challenge
2. Opens browser automatically for MAL authorization
3. Accepts the authorization redirect code
4. Registers and sets the account as default in Trackma
"""

import sys
import os
import glob
import webbrowser
from urllib.parse import urlparse, parse_qs

# Locate Trackma installation (support pipx and standard user site-packages)
search_paths = [
    *glob.glob(os.path.expanduser("~/.local/share/pipx/venvs/trackma/lib/python*/site-packages")),
    os.path.expanduser("~/.local/lib/python3*/site-packages"),
]

for p in search_paths:
    if os.path.isdir(p) and p not in sys.path:
        sys.path.insert(0, p)

try:
    from trackma.accounts import AccountManager
    from trackma import utils
except ImportError:
    print("Error: Trackma library could not be imported.")
    print("Ensure Trackma is installed (e.g., via `pipx install trackma`).")
    sys.exit(1)


def main():
    print("=" * 60)
    print("  Trackma + MyAnimeList (MAL) OAuth PKCE Setup Helper")
    print("=" * 60)
    print()

    # Generate PKCE code verifier
    code_verifier = utils.oauth_generate_pkce()

    # Build the OAuth URL with the PKCE challenge
    mal_info = utils.available_libs.get('mal')
    if not mal_info:
        print("Error: MAL library configuration not found in Trackma.")
        sys.exit(1)

    auth_url = mal_info[3] % code_verifier

    print("Step 1: Opening your browser for MyAnimeList authorization...")
    print()
    print("If the browser does not open automatically, visit this URL:")
    print("-" * 60)
    print(auth_url)
    print("-" * 60)
    print()

    try:
        webbrowser.open(auth_url)
        print("✓ Browser opened successfully!")
    except Exception:
        print("Notice: Could not launch browser automatically. Please open the URL above.")

    print()
    print("Step 2: Log in to MAL and click 'Allow' / 'Authorize'.")
    print("        MAL will redirect to a page with a URL like:")
    print("        https://myanimelist.net/...?code=XXXXXXXX")
    print()
    pin = input("Paste the entire redirect URL (or just the code): ").strip()

    if "code=" in pin:
        parsed = urlparse(pin)
        codes = parse_qs(parsed.query).get("code", [])
        if codes:
            pin = codes[0]

    if not pin:
        print("Error: No authorization code was provided. Aborting.")
        sys.exit(1)

    print()
    username = input("Enter your MyAnimeList username: ").strip()
    if not username:
        print("Error: Username cannot be empty.")
        sys.exit(1)

    extra = {"code_verifier": code_verifier}

    print()
    print(f"Step 3: Registering account '{username}' with Trackma...")

    try:
        am = AccountManager()
        am.add_account(username, pin, "mal", extra)
        am.set_default(1)
        print(f"✓ Account '{username}' successfully registered and set as default!")
        print()
        print("=" * 60)
        print("  Setup complete! Trackma is now authenticated with MAL.")
        print("=" * 60)
    except Exception as e:
        print(f"Error during registration: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
