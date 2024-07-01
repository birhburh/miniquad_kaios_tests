#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 example_name"
    exit 1
fi

rm -f kaios_example/mq_js_bundle.js
rm -f kaios_example/example.wasm.js
rm -f kaios_example/icon56.png
rm -f kaios_example/manifest.webapp
rm -rf kaios_example/assets

./asmjs_build.sh $1

pushd kaios_example
npm install
npm run build
popd

cat >kaios_example/mq_js_bundle.js.new <<- EOM
    console.log("RUNNING mq_js_bundle.js!");
EOM
uglifyjs -b <kaios_example/mq_js_bundle.js | sed 's/"webgl"/"experimental-webgl"/' >>kaios_example/mq_js_bundle.js.new
cat <kaios_example/wrap_asmjs.js >>kaios_example/mq_js_bundle.js.new
mv kaios_example/mq_js_bundle.js.new kaios_example/mq_js_bundle.js

cat >kaios_example/example.wasm.js.new <<- EOM
    console.log("RUNNING example.wasm.js.new!");

    define(function(require, exports, module) {
        console.log("RUNNING INSIDE define!");
EOM
sed 's/^export var \([^ ]*\) /exports\.\1 /' <wasm2js_example/example.wasm.js | uglifyjs >>kaios_example/example.wasm.js.new
cat >>kaios_example/example.wasm.js.new <<- EOM
    });
EOM
mv kaios_example/example.wasm.js.new kaios_example/example.wasm.js

cp examples/$1/icon56.png kaios_example/
cp examples/$1/manifest.webapp kaios_example/
cp -r examples/$1/assets kaios_example/ || true

id=$(sed <examples/$1/manifest.webapp -n 's/.*"origin": "app:\/\/\(.*\)",/\1/p')
gdeploy stop $id 2>/dev/null || true

gdeploy uninstall $id 2>/dev/null || true
gdeploy install kaios_example

echo $id
gdeploy start $id
repeats=0
while true; do
    line=$(gdeploy evaluate $id "window.MyLogs.read()" | tail -n +3 | sed "s/Script run in the $id app context evaluated to: //")
    if [ "$line" = '{ type: '\''undefined'\'' }' ]; then
        sleep 0.1
        (( repeats++ ))
        if [ $repeats -gt 50 ]; then
            break
        fi
    else
        repeats=0
        echo $line
    fi
done
