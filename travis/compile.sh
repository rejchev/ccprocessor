#!/bin/bash

SOURCES=$1
SOURCES_SM=$2
INCLUDES_SM=$SOURCES_SM'/include'
ERROR=1

cd $SOURCES

derictories=($(ls -d */))

for dir in "${derictories[@]}"; do
    module=$(basename -- "$dir")
    echo "Module name: ${module}"

    module_path=$SOURCES'/'$module
    echo "Module path: ${module_path}"

    module_path_bin=$module_path'/plugins'
    module_path_bin_debug=$module_path_bin'/disabled/'$module
    module_path_src=$module_path'/scripting'

    mkdir $module_path_bin
    mkdir -p $module_path_bin_debug

    cd $module_path_src

    source_list=(*.sp)
    echo "Source list: ${source_list}"

    cd $SOURCES

    for src in "${source_list[@]}"; do
        source=$module_path_src'/'$src
        echo "Module source: ${source}"

        source_file=$(basename -- "$source")
        echo "Module source name: ${source_file}"

        source_file_noext="${source_file%.*}"
        echo "Module source name no ext: ${source_file_noext}"

        bin=$module_path_bin'/'$source_file_noext'.smx'
        bin_debug=$module_path_bin_debug'/'$source_file_noext'.smx'
        
        $SOURCES_SM'/spcomp' $source -o2 -v2 -i=$INCLUDES_SM -o=$bin
        $SOURCES_SM'/spcomp' INCLUDE_DEBUG=1 $source -o2 -v2 -i=$INCLUDES_SM -o=$bin_debug

        if [ ! -e $bin ]; then
            echo "File ${bin} is not exists"
            exit $ERROR
        fi
    done
done