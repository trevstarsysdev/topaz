#!/usr/bin/env python
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
import os

SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))
TOPAZ_ROOT = os.path.dirname(os.path.dirname(SCRIPT_PATH))
PREAMBLE = '''# This file is auto-generated by update_chromium_web_sources.py
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

chromium_web_sources = [
'''

POSTAMBLE = ''']
'''

def main():
    topaz_to_fidl_path = os.path.join('third_party', 'chromium', 'fidl', 'chromium.web')
    fidl_gn_path_prefix = '//topaz/' + topaz_to_fidl_path
    fidl_path = os.path.join(TOPAZ_ROOT, topaz_to_fidl_path)

    gni_path = os.path.join(SCRIPT_PATH, 'chromium_web_sources.gni')
    with open(gni_path, 'w') as f:
        f.write(PREAMBLE)
        for fidl in sorted(os.listdir(fidl_path)):
            f.write('  "%s/%s",\n' % (fidl_gn_path_prefix, fidl))
        f.write(POSTAMBLE)
    return 0

if __name__ == '__main__':
    sys.exit(main())
