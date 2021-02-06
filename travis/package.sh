#!/bin/bash

SOURCES=$1
BUILD_NUMBER=$2

cd $SOURCES

derictories=($(ls -d */))

for dir in "${derictories[@]}"; do
    module=$SOURCES'/'$module
    module_name=$(basename -- "$dir")

    cd $module
    
    tar -czvf ${module_name}-${BUILD_NUMBER}.tar.gz *
    cp ${module_name}-${BUILD_NUMBER}.tar.gz ../

    cd ../
    rm -Rfv $dir
done