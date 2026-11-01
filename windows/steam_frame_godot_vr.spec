# -*- mode: python ; coding: utf-8 -*-

import os
import sys
import openvr

block_cipher = None

repo_root = os.path.abspath(os.path.join(SPECPATH, ".."))
openvr_dir = os.path.dirname(openvr.__file__)
openvr_dll = os.path.join(openvr_dir, "libopenvr_api_64.dll")

binaries = [
    (openvr_dll, "openvr"),
    (openvr_dll, "."),
]

a = Analysis(
    [os.path.join(SPECPATH, "steam_frame_godot_vr.py")],
    pathex=[repo_root, SPECPATH],
    binaries=binaries,
    datas=[],
    hiddenimports=[
        "openvr",
        "openvr.error_code",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="steam_frame_godot_vr",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
