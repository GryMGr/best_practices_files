#!/bin/bash

set -e

[ -z "${GITHUB_PAT}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "master" ] && exit 0

# see https://github.com/travis-ci/travis-ci/issues/1701
function travis-branch-commit() {
    local head_ref branch_ref
    head_ref=$(git rev-parse HEAD)
    if [[ $? -ne 0 || ! $head_ref ]]; then
        err "failed to get HEAD reference"
        return 1
    fi
    branch_ref=$(git rev-parse "$TRAVIS_BRANCH")
    if [[ $? -ne 0 || ! $branch_ref ]]; then
        err "failed to get $TRAVIS_BRANCH reference"
        return 1
    fi
    if [[ $head_ref != $branch_ref ]]; then
        msg "HEAD ref ($head_ref) does not match $TRAVIS_BRANCH ref ($branch_ref)"
        msg "someone may have pushed new commits before this build cloned the repo"
        return 0
    fi
    if ! git checkout "$TRAVIS_BRANCH"; then
        err "failed to checkout $TRAVIS_BRANCH"
        return 1
    fi

    if ! git add --all .; then
        err "failed to add modified files to git index"
        return 1
    fi
    # make Travis CI skip this build
    if ! git commit -m "Travis CI update $TRAVIS_BUILD_NUMBER [ci skip]"; then
        err "failed to commit updates"
        return 1
    fi
    # add to your .travis.yml: `branches\n  except:\n  - "/\\+travis\\d+$/"\n`
    #local git_tag=travis+$TRAVIS_BUILD_NUMBER
    #if ! git tag "$git_tag" -m "Generated tag from Travis CI build $TRAVIS_BUILD_NUMBER"; then
    #    err "failed to create git tag: $git_tag"
    #    return 1
    #fi
    local remote=origin
    if [[ $GITHUB_PAT ]]; then
        remote=https://$GITHUB_PAT@github.com/$TRAVIS_REPO_SLUG
    fi
    if [[ $TRAVIS_BRANCH != master ]]; then
        msg "not pushing updates to branch $TRAVIS_BRANCH"
        return 0
    fi
    if ! git push --quiet --follow-tags "$remote" "$TRAVIS_BRANCH" > /dev/null 2>&1; then
        err "failed to push git changes"
        return 1
    fi
}

function msg() {
    echo "travis-commit: $*"
}

function err() {
    msg "$*" 1>&2
}

travis-branch-commit 


#git config --global user.email "xie@yihui.name"
#git config --global user.name "Yihui Xie"

#git clone -b gh-pages https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}.git book-output
#cd book-output
#cp -r ../_book/* ./
#git add --all *
#git commit -m"Update the book" || true
#git push -q origin gh-pages
