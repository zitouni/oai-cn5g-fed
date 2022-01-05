"""
Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
contributor license agreements.  See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The OpenAirInterface Software Alliance licenses this file to You under
the OAI Public License, Version 1.1  (the "License"); you may not use this file
except in compliance with the License.
You may obtain a copy of the License at

      http://www.openairinterface.org/?page_id=698

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
------------------------------------------------------------------------------
For more information about the OpenAirInterface (OAI) Software Alliance:
      contact@openairinterface.org

------------------------------------------------------------------------------
"""

from subprocess import PIPE,STDOUT
import time
import subprocess
import logging
import argparse
import re 
import markdown
from bs4 import BeautifulSoup, NavigableString, Tag


DOCUMENT_FOLDER = '../docs'
SLEEP_BETWEEN_COMMANDS = 5
SLEEP_BETWEEN_HEADERS = 30

filename = '../docs/DEPLOY_SA5G_BASIC_STATIC_UE_IP.md'


def subprocess_call(command,cwd=None):
    '''
    :command: list
    :cwd str current working directory
    return resp dict
    '''
    print(command)
    try:
        if cwd is not None:
            process = subprocess.run(command,cwd=cwd,stdout=PIPE, stderr=STDOUT,check=True)
        else:
            process = subprocess.run(command,stdout=PIPE, stderr=STDOUT,check=True)
    except Exception as e:
        reason = "Exception <<{}>> while executing the command {}".format(str(e),command)
        resp = {'status':1,'reason':reason}
        return resp
    if process.returncode == 0:
        resp = {'status':0,'output':""}
        if process.stdout is not None:
            out=process.stdout.decode()
            resp = {'status':0,'output':out}
    else:
        if process.stdout is not None:
            out=process.stdout.decode()
            resp = {'status':1,'reason':out}
        elif process.stderr is not None:
            error=process.stderr.decode()
            resp = {'status':1,'reason':error}
        else:
            resp = {'status':1,'reason':'Undetermine'}
    return resp

with open(filename, 'r') as f:
    text = f.read()
    html = markdown.markdown(text)

soup = BeautifulSoup(html, 'html.parser')

for header in soup.find_all('h2'):
    print(header.get_text())
    nextNode = header
    while True:
        nextNode = nextNode.nextSibling
        if nextNode is None:
            break
        if isinstance(nextNode, NavigableString):
            pass
        if isinstance(nextNode, Tag):
            if nextNode.name == "h2":
                break
            text = nextNode.get_text()
            if text.split('\n')[0] == 'shell':
                commands = re.findall(r"docker-compose-host \$: (.*)",text)
                for command in commands:
                    print("Executing the command %s" %(command))
                    output = subprocess_call(command=command.split(' '),cwd='../docker-compose')
                    print("Output of the command %s" %(output))
                    time.sleep(SLEEP_BETWEEN_COMMANDS)
    time.sleep(SLEEP_BETWEEN_HEADERS)





