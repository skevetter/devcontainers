#!/bin/bash

set -eo pipefail

main() {
  echo "Starting post-create setup in $(pwd)"

  printf '' | sudo tee "/usr/local/etc/vscode-dev-containers/first-run-notice.txt" > /dev/null

  echo "Post-create setup complete!"
}

main "$@"
