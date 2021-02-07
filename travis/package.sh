#!/bin/bash

SOURCES=$1
BUILD_NUMBER=$2

cd $SOURCES

derictories=($(ls -d */))

for dir in "${derictories[@]}"; do
    echo "Dir: ${dir}"

    module_name=$(basename -- "$dir")
    echo "Module name: ${module_name}"

    module=$SOURCES'/'$module_name
    echo "Module: ${module}"

    cd $module
    echo $PWD
    
    tar -czvf ${module_name}-${BUILD_NUMBER}.tar.gz *
    cp ${module_name}-${BUILD_NUMBER}.tar.gz ../

    cd ../
    echo $PWD
    rm -Rfv $dir
done