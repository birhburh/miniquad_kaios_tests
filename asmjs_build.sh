#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 example_name"
    exit 1
fi

example_name=$1

# weird solution but it uses right miniquad after that
rm -f Cargo.lock

# based on this
# https://doc.rust-lang.org/cargo/guide/cargo-home.html
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo/}
miniquad_parts=$(cargo tree -p miniquad -f '{p}' 2>/dev/null | head -1)
miniquad_parts=( $(echo $miniquad_parts | cut -d' ' -f2-3 | sed 's/(.*#\(.*\))/\1/') )
miniquad_hash=${miniquad_parts[1]}
miniquad_ver=${miniquad_parts[0]##*v}

status=0
ls -1 $CARGO_HOME/git/db | grep miniquad -q || status=$?
if [ $status -eq 0 ]; then
    for dir in $CARGO_HOME/git/db/miniquad*; do
        hash=$(cat $dir/FETCH_HEAD | cut -f 1)
        if [[ $hash =~ ^"$miniquad_hash" ]]; then
            dir_hash=$(basename $dir | cut -d'-' -f2)
            for dir in $CARGO_HOME/git/checkouts/miniquad-$dir_hash/*; do
                subdir_hash=$(basename $dir)
                if [[ $miniquad_hash =~ ^"$subdir_hash" ]]; then
                    miniquad_path=$CARGO_HOME/git/checkouts/miniquad-$dir_hash/$subdir_hash
                fi
            done
        fi
    done
fi

status=0
ls -1 $CARGO_HOME/registry/src/*/* | grep miniquad -q || status=$?
if [ -z "$miniquad_path" ] && [ $status -eq 0 ]; then
    for dir in $CARGO_HOME/registry/src/*/miniquad*; do
        ver=$(basename $dir | cut -d'-' -f 2)
        if [[ $ver == $miniquad_ver ]]; then
            miniquad_path=$dir
        fi
    done
fi

echo Path to gl.js: ${miniquad_path:-../miniquad}/js/gl.js
ls ${miniquad_path:-../miniquad}/js/gl.js
cat ${miniquad_path:-../miniquad}/js/gl.js > wasm2js_example/mq_js_bundle.js
cat >> wasm2js_example/mq_js_bundle.js <wasm2js_example/load_asmjs.js

uglifyjs -b <wasm2js_example/mq_js_bundle.js >wasm2js_example/mq_js_bundle.js.new && mv wasm2js_example/mq_js_bundle.js.new wasm2js_example/mq_js_bundle.js

cargo build --example=$example_name --target=wasm32-unknown-unknown --release
# install binaryen's wasm2js (or just build it and add to PATH)
wasm2js target/wasm32-unknown-unknown/release/examples/$example_name.wasm -o wasm2js_example/example.wasm.js
# osx have bsd-s sed so yeah
sed "s/import \* as env from 'env';/var env = importObject.env;/" wasm2js_example/example.wasm.js >wasm2js_example/example.wasm.js.temp && mv wasm2js_example/example.wasm.js.temp wasm2js_example/example.wasm.js
