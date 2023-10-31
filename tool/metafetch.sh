#!/bin/bash
# metafetch.sh
# fetch rpi metadata
# release 3.3.2

FETCHER=https://github.com/
GITFETCHER=git@github.com:
BRANCH=kirkstone
DEFLAYER=$HOME/yocto_$BRANCH/metadata
DEFBUILD=$HOME/yocto_$BRANCH/rpi4

erreur() { echo $* && exit 0 || kill $$; }

usage() {    # print options and quit

    printf "
usage:
\t $0 <options>
    option        \t purpose                 \t default
    -h            \t print this              \t usage
    -g            \t switch to git protocol  \t https protocol
    -r <branch>   \t branch                  \t $BRANCH
    -l <layerdir> \t metadata directory      \t $DEFLAYER
    -b <buildir>  \t build directory         \t $DEFBUILD
"
    erreur
}

confirm() {    # get confirmation or quit

    read -p "please confirm (y/n) " choix
    [ "$choix" == "y" ] && echo 1 || echo 0
}

while getopts ":l:b:r:hg" option; do    # parce command-line options

    case $option in

        l ) LAYER=$OPTARG;;
        b ) BUILD=$OPTARG;;
        r ) BRANCH=$OPTARG;;
        g ) FETCHER=$GITFETCHER;;
        h ) usage $0;;
        * ) usage $0;;
    esac
done

# check system path
[ -n "$LAYER" ] || LAYER=$DEFLAYER
[ -n "$BUILD" ] || BUILD=$DEFBUILD
[ -d $LAYER ] || mkdir -p $LAYER || erreur $? cannot create $LAYER
[ -d $BUILD ] || mkdir -p $BUILD || erreur $? cannot create $BUILD
LAYER=$(realpath $LAYER) && printf "\nmetadata:\t $LAYER\n" || erreur $? cannot find $LAYER
BUILD=$(realpath $BUILD) && printf "build:\t\t $BUILD\n" || erreur $? cannot find $BUILD
printf "branch:\t\t $BRANCH\nprotocol:\t $FETCHER\n\n"

declare -A REPO
REPO=(    # associative array of git repositories
    [yoctoproject/poky.git]=$LAYER/poky
    [openembedded/meta-openembedded.git]=$LAYER/oe
    [agherzan/meta-raspberrypi]=$LAYER/rpi/meta-raspberrypi
    [kaloyanski/meta-thc.git]=$LAYER/thc/meta-thc
    [TripleHelixConsulting/rpiconf.git]=$BUILD/conf
)

[ $(confirm) = 0 ] && erreur $? $0 interrupt || echo $0 continue

for repo in ${!REPO[@]}; do    # clone repositories

    git clone -b $BRANCH $FETCHER$repo ${REPO[$repo]}
done

# adjust bibtbake layer configuration
sed -i s#/home/yocto/layer#$LAYER#g $BUILD/conf/bblayers.conf || erreur sed $?

# bitbake environment
OEINIT=oe-init-build-env
cd $LAYER/poky && pwd || erreur $? cannot find $LAYER/poky
[ -x $OEINIT ] && . ./$OEINIT $BUILD || erreur $? cannot find $OEINIT

bitbake-layers show-layers

printf "\n\t how to start a new build\n\n"

echo cd $LAYER/poky
echo . ./$OEINIT $BUILD
echo bitbake core-image-x11
echo