#!/usr/bin/env bash

EMOJI="\xE2\x9C\xA8 \xF0\x9F\x8C\xB2 \xE2\x9C\xA8"
SEP="*****"
CURRENT=$(poetry run version)
NAME=$(poetry run name)
COLOR="\e[1;31m"
CINPUT="\e[32m"
CWARN="\e[1;31m"
CINFO="\e[34m"
END="\e[0m"

COMMIT=0
PUSH=0
REPO=""
VERSION=""

echo "$EMOJI $NAME $CURRENT $EMOJI"

printf "$CINPUT Version (or bump): $END"
read input
if [ "$input" != "" ]; then
    VERSION=$input
fi

printf "$CINPUT Commit changes to git (y/[n]): $END"
read input
if [ "$input" == "y" ]; then
    COMMIT=1
fi

if [ "$COMMIT" == 1 ]; then
    printf "$CINPUT Push changes to github (y/[n]): $END"
    read input
    if [ "$input" == "y" ]; then
        PUSH=1
    fi
fi

printf "$CINPUT Publishing repo (or skip): $END"
read input
if [ "$input" != "" ]; then
    REPO=$input
fi

printf "\n$SEP updating version $SEP\n"
poetry version $VERSION
poetry run upver

STEPS=4

# formatting
printf "\n$SEP formatting code $SEP\n"

msg="$CINFO formatting for release $VERSION $END\n"
printf $msg
make format
if [ "$COMMIT" == 1 ]; then
    git add .
    git commit -m "$msg"
    echo "$?"
else
    printf "$CWARN skipping format commit$END\n"
fi

# update docs
printf "\n$SEP updating documentation $SEP\n"
msg="$CINFO updating docs for release $VERSION $END\n"
printf $msg
make docs

if [ "$COMMIT" == 1 ]; then
    git add .
    git commit -m "$msg"
else
    printf "$CWARN skipping document commit $END\n"
fi

# tagging
printf "\n$SEP Tagging branch $SEP\n"
if [ "$COMMIT" == 1 ]; then
    git tag $TAG
else
    printf "$CWARN skipping tagging $END\n"
fi

if [ "$PUSH" == 1 ]; then
    git push
    git push $TAG
fi


# releasing
printf "\n$SEP Publishing $SEP\n"


if [ "$REPO" != "" ]; then
    printf "$CWARN Are you sure you want to publish $NAME $VERSION to $REPO ([y]/n)$END"
    read input
    if [ "$input" == "n" ]; then
        REPO=""
    fi

    if [ "$REPO" != "" ]; then
        poetry publish -r $REPO --build
    fi
else
    printf "$CWARN skipping publishing, repo not specified $END\n"
fi