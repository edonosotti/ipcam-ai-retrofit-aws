import os
import shutil
import json
import glob
import boto3

from shovel import task
from shutil import copytree, ignore_patterns
from contextlib import closing
from zipfile import ZipFile, ZIP_DEFLATED
from pip._internal import main as pipmain

SELF_PATH = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(os.path.dirname(SELF_PATH), 'config')
LOG_PATH = os.path.join(os.path.dirname(SELF_PATH), 'log')
DEPLOY_PACKAGE_DIR = '.deploy'
DEPLOY_PACKAGE_PATH = os.path.join(os.path.dirname(SELF_PATH), DEPLOY_PACKAGE_DIR)
TEMP_ZIP_FILE = os.path.join(os.path.dirname(DEPLOY_PACKAGE_PATH), "%s.zip" % (DEPLOY_PACKAGE_DIR))

def info(description):
    print(description)

def error(description, code=1):
    print("ERROR: %s" % (description))
    exit(code)

def cleanup():
    if os.path.isdir(DEPLOY_PACKAGE_PATH):
        shutil.rmtree(DEPLOY_PACKAGE_PATH, True)
    if os.path.isdir(DEPLOY_PACKAGE_PATH):
        error("Cannot overwrite existing deploy package.")

def copy_files():
    copytree(SELF_PATH, DEPLOY_PACKAGE_PATH, ignore=ignore_patterns('*.pyc', '__pycache__', '.*'))

def add_dependencies():
    pipmain([
        'install',
        '-r', os.path.join(DEPLOY_PACKAGE_PATH, 'requirements.txt'),
        '-t', DEPLOY_PACKAGE_PATH
    ])

def zip_files():
    with closing(ZipFile(TEMP_ZIP_FILE, "w", ZIP_DEFLATED)) as zippack:
        for root, dirs, files in os.walk(DEPLOY_PACKAGE_PATH):
            for f in files:
                zippablepath = os.path.join(root, f)
                zdest = zippablepath[len(DEPLOY_PACKAGE_PATH)+len(os.sep):]
                zippack.write(zippablepath, zdest)
    if not os.path.isfile(TEMP_ZIP_FILE):
        error("Could not create ZIP file: %s" % (TEMP_ZIP_FILE))

@task
def package(option=''):
    info("Packaging...")
    cleanup()
    copy_files()
    add_dependencies()
    if not option or option != 'nozip':
        zip_files()
    info("Package was successfully created.")
