#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

OS_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${OS_ROOT}/hack/common.sh"

cd "${OS_ROOT}"

echo "===== Verifying Generated Conversions ====="
echo "Building gendeepcopy binary..."
if ! buildout=`"${OS_ROOT}/hack/build-go.sh" cmd/gendeepcopy 2>&1`
then
  echo "FAILURE: Building gendeepcopy binary failed:"
  echo "$buildout"
  exit 1
else
  echo "$buildout" | sed 's/^/   /'
fi

gendeepcopy="${OS_ROOT}/_output/local/bin/$(os::build::host_platform)/gendeepcopy"

echo "   Verifying gendeepcopy binary..."
if [[ ! -x "$gendeepcopy" ]]; then
  {
    echo "FAILURE: It looks as if you don't have a compiled conversion binary."
    echo "If you are running from a clone of the git repo, please run:"
    echo "'./hack/build-go.sh cmd/gendeepcopy'."
  } >&2
  exit 1
fi

APIROOT_REL="pkg/api"
APIROOT="${OS_ROOT}/${APIROOT_REL}"
TMP_APIROOT_REL="_output/verify-generated-deep-copies"
TMP_APIROOT="${OS_ROOT}/${TMP_APIROOT_REL}/${APIROOT_REL}"

echo "Generating fresh deep copies..."
if ! output=`${OS_ROOT}/hack/update-generated-deep-copies.sh ${TMP_APIROOT_REL} 2>&1`
then
  echo "FAILURE: Generating fresh deep copies failed:"
  echo "$output"
  exit 1
fi

rsync -au "${APIROOT}" "${TMP_APIROOT}/.."

echo "Diffing current deep copies against freshly generated deep copies..."
ret=0
diff -Nauprq -I 'Auto generated by' "${APIROOT}" "${TMP_APIROOT}" || ret=$?
rm -rf "${TMP_APIROOT}"
if [[ $ret -eq 0 ]]
then
  echo "SUCCESS: Current deep copies up to date."
else
  echo "FAILURE: Current deep copies out of date. Please run hack/update-generated-deep-copies.sh"
  exit 1
fi

# ex: ts=2 sw=2 et filetype=sh
