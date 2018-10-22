#!/bin/sh
cd ..
mkdir interview
cd interview
git init
git remote add origin https://github.com/ZZULI-TECH/interview.git
git fetch
git checkout gh-pages
cd ../interview
cd source
gitbook install
cd ..

