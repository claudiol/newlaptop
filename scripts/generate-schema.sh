#!/bin/sh
virtualenv ~/.virtualenvs/openapi2json
source ~/.virtualenvs/openapi2json/bin/activate
pip3 install openapi2jsonschema
curl -L https://github.com/instrumenta/openapi2jsonschema/commit/eeed25046b189924fe835ab784eadbb241ae574c.diff | patch -d ~/.virtualenvs/openapi2json/lib/python3.10/site-packages/openapi2jsonschema -p2
curl -L https://github.com/instrumenta/openapi2jsonschema/pull/58/commits/7a208e9becae9c66bccb4c89869bb24f634a42af.diff | patch -d ~/.virtualenvs/openapi2json/lib/python3.10/site-packages/openapi2jsonschema -p2

