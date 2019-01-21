#!/bin/bash

pyenv global system 3.6.7
pip3 install setuptools
shopt -s nullglob
abifiles=( ./artifacts/*.development.json )
[ "${#abifiles[@]}" -lt "1" ] && echo "ABI Files for development environment not found" && exit 1
python3 setup.py sdist bdist_wheel
twine upload dist/*
