#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys

sys.path.append(os.getcwd())

import atom_prepare
import atom_apm
import copy_configs
import stack_build

app_dir      = atom_prepare.prep_path('..')
backend_dir  = atom_prepare.prep_path('../build-config/backend')
frontend_dir = atom_prepare.prep_path('../luna-studio')


def build_app (backend_args, frontend_args, runner_args, dev_mode=False):
    try:
        stack_build.run(backend_args, frontend_args, runner_args)
        atom_prepare.run()
        atom_apm.run(dev_mode) # RENAME: LunaStudioInstallInAtom ?
        copy_configs.run()

    except subprocess.CalledProcessError:
        print("Status : FAIL")
        sys.exit(1)

def build_backend (backend_args):
    try:
        stack_build.create_bin_dirs()
        stack_build.build_backend(backend_args)
        stack_build.link_main_bin()
        stack_build.copy_std_lib()

    except subprocess.CalledProcessError:
        print("Status : FAIL")
        sys.exit(1)

def build_frontend (frontend_args, dev_mode=False):
    try:
        stack_build.create_bin_dirs()
        stack_build.build_ghcjs(frontend_args)
        atom_prepare.run()
        atom_apm.run(dev_mode)
        copy_configs.run()

    except subprocess.CalledProcessError:
        print("Status : FAIL")
        sys.exit(1)

def main ():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", help="Build backend only", action="store_true")
    parser.add_argument("--frontend", help="Build frontend only", action="store_true")
    parser.add_argument("--release", help="Build package in release mode", action="store_true")
    parser.add_argument("--backend-stack", help="Additional options passed to stack while building backend", action="append", dest="stack_backend_args", default=['--copy-bins', '--install-ghc'])
    parser.add_argument("--frontend-stack", help="Additional options passed to stack while building frontend", action="append", dest="stack_frontend_args", default=['--install-ghc'])
    parser.add_argument("--runner-stack", help="Additional options passed to stack while building runner", action="append", dest="stack_runner_args", default=['--copy-bins', '--install-ghc'])
    args = parser.parse_args()

    if args.backend:
        build_backend (args.stack_backend_args)
    elif args.frontend:
        build_frontend (args.stack_frontend_args, dev_mode=(not args.release)) # FIXME: "not ..." is not a proper way to handle this flag
    else: build_app (args.stack_backend_args, args.stack_frontend_args, args.stack_runner_args, not args.release)

main()