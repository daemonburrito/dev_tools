#!/bin/bash

set -e

APPSTORE_REPO_URL=git@github.com:famigo/AppStore.git
APPSTORE_CO_PATH=AppStore
BASE_PATH=/mnt/famigo/
VENV_NAME=venv-appstore
VENV_PATH=${BASE_PATH}/${VENV_NAME}
VERSION_FILE=version

echo "AppStore venv and code packaging script"
echo "Will build/update virtualenvironment, checkout master of AppStore, and package them in a debian"
echo "The base path is set in the script where code and venv will reside as ${BASE_PATH}"
echo "Virtualenvs need to maintain their paths, they do not relocate well and in fact break some subpackages if you attempt to do so"
echo
echo

if [ ! -d $VENV_BASE_PATH ] ; then
	echo "Base path (${BASE_PATH}) doesn't exist, attempting to create."
	mkdir -p ${BASE_PATH}
fi

echo "Checking out or updating AppStore repository"
if [ ! -d $APPSTORE_CO_PATH ] ; then
	git clone $APPSTORE_REPO_URL $APPSTORE_CO_PATH
else
	pushd $APPSTORE_CO_PATH > /dev/null
	git pull
	popd > /dev/null
fi

echo "Updating or creating the virtual environment"
if [ ! -d $VENV_PATH ] ; then
	virtualenv --distribute --no-site-packages ${VENV_PATH}
	echo "Since I'm creating a new virtualenv, install django-profiler as it cannot be installed after Django is or it breaks."
	source ${VENV_PATH}/bin/activate
	pip install django-profiler==1.1
	deactivate
fi

source ${VENV_PATH}/bin/activate
pushd ${APPSTORE_CO_PATH} > /dev/null
for req in $(find . -name "requirements*.txt") ; do
	sed -i 's#netaddr==0.7.10#netaddr==0.7.3#g' ${req}
	pip install -r ${req}
	git checkout ${req}
done
popd > /dev/null

echo "Environment successfully built in ${VENV_PATH}"

echo -n "Bumping version... "

increment_version ()
{
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    [ ${#new} -gt $len ] && carry=1 || carry=0
    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
  done
  new="${part[*]}"
  echo -e "${new// /.}"
} 

# Incrementing the version has to be done *before* any of the copies below
increment_version $(cat $VERSION_FILE) > $VERSION_FILE
#cat $VERSION_FILE | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}' > version
cat $VERSION_FILE
PACKAGE_DIR=appstore-$(cat $VERSION_FILE)
dch -v "$(cat $VERSION_FILE)-1" "New version, Jenkins Build: $BUILD_NUMBER"

echo "Setting up packaging environment"
rm -rf $PACKAGE_DIR && mkdir -p $PACKAGE_DIR
pushd $PACKAGE_DIR > /dev/null
rsync -avh --delete ../debian .
rsync -avh --delete ${VENV_PATH} .
rsync -avh --delete ../${APPSTORE_CO_PATH} .
debuild -us -uc
popd > /dev/null

