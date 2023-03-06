#!/usr/bin/env python3
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
---------------------------------------------------------------------
"""

import argparse
import logging
import os
import re
import sys

logging.basicConfig(
    level=logging.DEBUG,
    stream=sys.stdout,
    format="[%(asctime)s] %(levelname)8s: %(message)s"
)

def _parse_args() -> argparse.Namespace:
    """Parse the command line args

    Returns:
        argparse.Namespace: the created parser
    """
    example_text = '''example:
        ./ci-scripts/silentCN5G-NF.py --help
        ./ci-scripts/silentCN5G-NF.py --docker-compose-file DC_FILENAME --amf-silent'''

    parser = argparse.ArgumentParser(description='OAI 5G CORE NETWORK Utility tool',
                                    epilog=example_text,
                                    formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        '--docker-compose-file', '-dcf',
        action='store',
        help='Docker-compose File to modify',
    )

    parser.add_argument(
        '--amf-silent',
        action='store_true',
        default=False,
        help='Make AMF NF silent',
    )
    return parser.parse_args()

if __name__ == '__main__':
    # Parse the arguments
    args = _parse_args()

    cwd = os.getcwd()
    if not os.path.isfile(os.path.join(cwd, args.docker_compose_file)):
        logging.error(f'{args.docker_compose_file} does not exist')
        sys.exit(-1)

    lines = ''
    with open(os.path.join(cwd, args.docker_compose_file), 'r') as rfile:
        for line in rfile:
           lines += line
           if re.search('image: oaisoftwarealliance/oai-amf:', line) is not None and args.amf_silent:
               newLine = re.sub('image:', 'command:', line)
               newLine = re.sub('oaisoftwarealliance.*$', '["/openair-amf/bin/oai_amf", "-c", "/openair-amf/etc/amf.conf"]', newLine)
               lines += newLine

    with open(os.path.join(cwd, args.docker_compose_file), 'w') as wfile:
        wfile.write(lines)

    sys.exit(0)
