#!/bin/bash

export MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
export RELEASE_TAG_PREFIX="release"
export RELEASE_TITLE_PREFIX="[deploy] Release"
export LAST_ISSUE="[Release]"

# Get the latest from default branch
# ----------------------------------
getLatest() {
    git checkout "$MAIN_BRANCH"
    git pull origin "$MAIN_BRANCH"
    git fetch
}

# Constructs the changelog. These are all commits from the latest release
# the current going-to-be deploy SHA.
# -----------------------------------
getChangeLogSinceLatestRelease() {
  latest_release_hash=$(gh api -H "Accept: application/vnd.github+json" /repos/brajagopal-zettle/"$PROJECT_REPONAME"/releases | jq -r '.target_commitish')

  if [ -z "$latest_release_hash" ] || [ "$latest_release_hash" = "null" ]; then
    # First release, empty changelog
    echo ""
  else
    changelog=$(git --no-pager log \
                --pretty='* %h %at %an %ad - %s' \
                --no-merges \
                --author-date-order \
                --date=format:'%Y-%m-%d:%H:%M:%S' \
                "$latest_release_hash" | \
                sort -k2,1 --stable)
    echo "$changelog"
  fi
}

# The createIssue will add content to the Issue explain what the issue
# is about. It will add the changelog and link it to the git SHA.
# If an issue with open already exists, it will delete it
# and create a new one.
# ------------------------------------------------------------------------------
createIssue() {
    echo "Creating Issue."
    echo "-----------------------"
    changelog=$1

    # Show all commits in the changelog if the number of commits is less than 10
    # Otherwise show only the most recent.
    # If it's less than `num_recent`, then no need to post a PR comment for
    # the changelog.
    total_commits=$(echo -n "$changelog" | wc -l)
    num_recent=20
    changelog_summary_title="($num_recent most recent commits)"
    if [ "$total_commits" -eq "0" ] && [ "x$changelog" = "x" ]; then
        changelog_summary_title="(No commits, maybe it's the first time)"
        changelog_recent=$changelog
    elif [ "$total_commits" -le "$num_recent" ]; then
        changelog_summary_title="(all commits)"
        changelog_recent=$changelog
    else
        changelog_recent=$(echo "$changelog" | tail -$num_recent)
    fi

    # Get the current draft release tag and delete them all.
    current_issue=$(gh api -H "Accept: application/vnd.github+json" /repos/brajagopal-zettle/"$PROJECT_REPONAME"/issues | jq -r "[ .[] | select( .name | contains(\"$LAST_ISSUE\")) | .[].tag_name")

    # Delete all the draft releases
    if [[ -n $current_issue ]]; then
        printf '%s\n' "$current_issue" |
        while IFS= read -r tag; do
            echo "Deleting draft release with tag=$tag"
            gh release delete -y "$tag"
        done
    fi


    release_body=$(getReleaseBody)
    gh issue create --title "$LAST_ISSUE v$(date +%Y%m%d%H%M)" \
                    --body "$release_body"
                    --repo $PROJECT_REPONAME
}


# Main entry point
# ----------------
# validate
getLatest
set -x
changelog=$(getChangeLogSinceLatestRelease)
createIssue "$changelog"
set +x
echo "Done!"