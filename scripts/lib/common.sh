#!/usr/bin/env bash

atomic_publish_directory() {
  local source_dir=$1
  local destination=$2

  node - "$source_dir" "$destination" <<'NODE'
const fs = require('fs');
const source = process.argv[2];
const destination = process.argv[3];

if (fs.existsSync(destination)) {
  console.error('destination appeared before atomic publication; refusing to replace it');
  process.exit(73);
}

try {
  fs.renameSync(source, destination);
} catch (error) {
  console.error(`atomic publication failed: ${error.code || 'UNKNOWN'}`);
  process.exit(74);
}
NODE
}
