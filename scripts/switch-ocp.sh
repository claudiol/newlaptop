if [ ".$1" == "." ]; then
  echo "Need an ocp version"
  echo "e.g. $0 4.12"
  echo
  echo "Available:"
  AVAIL=$(ls -d ~/bin/ocp*)
  echo $AVAIL
  exit
fi

VERSION=$1

if [ -d ~/bin/ocp$VERSION ]; then
  export PATH=~/bin/ocp$VERSION:$PATH
  if [ -f ~/bin/oc ]; then
    rm -f ~/bin/oc
  fi
  if [ -f ~/oc_client/oc ]; then
    rm -rf ~/oc_client/oc
  fi
  ln -s ~/bin/ocp$VERSION/oc ~/bin/oc
  ln -s ~/bin/ocp$VERSION/oc ~/oc_client/oc
  echo "New path: $PATH"
else
  echo "Can't switch to unknown version $VERSION"
fi
