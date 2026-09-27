#/bin/bash

SRC="../"
MODID="opcontainer"
PZVERSION="42"
MODNAME="Open-Container-Protection"

WORKDIR="./$MODNAME"

mkdir $WORKDIR
cp $SRC/workshop/workshop.txt $WORKDIR/
cp $SRC/common/$MODID.png $WORKDIR/preview.png

MODDIR="$WORKDIR/Contents/mods/$MODNAME"

mkdir -p $MODDIR
cp $SRC/README.md $MODDIR/
cp $SRC/LICENSE $MODDIR/
cp -r $SRC/$PZVERSION $MODDIR/
cp -r $SRC/common $MODDIR/

echo "Success."
