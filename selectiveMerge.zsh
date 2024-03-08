# Check whether we are on a given branch in a Git repo
checkBranch() {
    # read the command-line argument, which is the desired branch
    desired_branch="$1"

    # Get the name of the current Git branch
    current_branch=$(git branch --show-current)

    # Check if the current branch is the desired branch
    if [ "$current_branch" != "$desired_branch" ]; then
        echo "You are not on the '$desired_branch' branch. You are on '$current_branch'."
        return 1
    fi
}

# Merge branch except files specified in .publishignore
selectiveMerge() {
    # Read the command-line argument, which is the branch to merge into
    branch="$1"

    # Ensure the branch argument is either 'main' or 'publish'
    if [ "$branch" != "main" ] && [ "$branch" != "publish" ]; then
        echo "Invalid branch specified. Only 'main' or 'publish' are allowed."
        return 1
    fi

    # Check if inside a Git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "This is not a Git repository."
        return 1
    fi

    # Make sure the repository is clean
    if [ -n "$(git status --porcelain)" ]; then
        echo "Please commit your changes before proceeding."
        return 1
    fi

    # Check if renv library is up to date
    is_synchronized=$(Rscript -e 'options(renv.verbose = FALSE); cat(renv::status()$synchronized)')
    if [ "$is_synchronized" != "TRUE" ]; then
        echo "Please synchronize renv before proceeding."
        return 1
    fi

    # Create a temporary file
    temp_publishignore=$(mktemp)

    # Add additional files to the temporary file
    echo "renv.lock" >> "$temp_publishignore"
    echo ".publishignore" >> "$temp_publishignore"

    if [ "$branch" = "main" ]; then
        # Make sure we are on the publish branch
        checkBranch publish
        if [ $? -ne 0 ]; then
          return 1
        fi

        # Switch to the main branch
        git checkout main

        # Append the contents of .publishignore to the temporary file
        if [ -f .publishignore ]; then
            cat .publishignore >> "$temp_publishignore"
        else
            echo ".publishignore file not found."
            rm "$temp_publishignore"
            return 1
        fi

        # Merge in the changes from publish, but do not commit yet
        git merge --no-commit --no-ff publish > /dev/null 2>&1

        # Restore files/directories in .publishignore
        echo "Restoring files from .publishignore..."
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [ -z "$line" ] || [[ $line == \#* ]]; then
                continue
            fi

            if git ls-tree HEAD "$line" > /dev/null 2>&1; then
                type=$(git ls-tree HEAD "$line" | awk '{print $2}')
                if [ "$type" = "blob" ]; then
                    # If it's a file, check it out directly
                    git checkout HEAD -- "$line"
                elif [ "$type" = "tree" ]; then
                    # If it's a directory, checkout each file within it
                    git checkout HEAD -- "$line"/
                fi
            fi
        done < "$temp_publishignore"
    elif [ "$branch" = "publish" ]; then
        # Make sure we are on the main branch
        checkBranch main
        if [ $? -ne 0 ]; then
          return 1
        fi

        # Append the contents of .publishignore to the temporary file
        if [ -f .publishignore ]; then
            cat .publishignore >> "$temp_publishignore"
        else
            echo ".publishignore file not found."
            rm "$temp_publishignore"
            return 1
        fi

        # Switch to the publish branch
        git rev-parse --verify publish >/dev/null 2>&1 && git checkout publish || git checkout -b publish

        # Merge in the changes from main, but do not commit yet
        git merge --no-commit --no-ff main > /dev/null 2>&1

        # Read .publishignore and remove specified files/directories
        echo "Removing files from .publishignore..."
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Check if the line is not empty and not a comment
            if [[ -n $line && ! $line =~ ^#.* ]]; then
                # Check if the file/directory exists
                if [ -e "$line" ]; then
                    # Perform git rm operation
                    git rm -rf "$line" > /dev/null 2>&1
                fi
            fi
        done < "$temp_publishignore"
    fi

    # Synchronize renv
    echo "Synchronizing renv..."
    Rscript -e 'options(renv.verbose = FALSE); renv::snapshot()' > /dev/null 2>&1

    # Commit the merge
    echo "Committing changes..."
    git add --all
    git commit -m "Merge branch publish with exceptions from .publishignore" > /dev/null 2>&1

    # Print message to user
    echo "Merge complete."

    # Check if the renv library is up to date
    is_synchronized=$(Rscript -e '
    options(renv.verbose = FALSE)
    cat(renv::status()$synchronized)')
    if [ "$is_synchronized" != "TRUE" ]; then
        echo "renv is not synchronized. Please run renv::status() and follow the instructions."
    fi

    # Remove the temporary file
    rm "$temp_publishignore"
}
