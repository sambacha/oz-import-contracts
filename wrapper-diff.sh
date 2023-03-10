#!/usr/bin/env bash

# Simple wrapper to use patdiff with git, as external diff tool
# You may enable it with
# $ export GIT_EXTERNAL_DIFF=$(where patdiff-git-wrapper.sh)
# OR
# $ git config --global diff.external $(where patdiff-git-wrapper.sh)

# Script called with these parameters:
# path old-file old-hex old-mode new-file new-hex new-mode [new-path] [info]
path="$1"
old_file="$2"
old_hex="$3"
old_mode="$4"
new_file="$5"
new_hex="$6"
new_mode="$7"

if [[ $# -eq 9 ]]; then
    new_path="$8"
    info="$9"
else
    new_path="$path"
    info=""
fi

m=$(printf '\e[1m')

echo "${m}patdiff -git a/$path b/$new_path"

if [[ $old_hex = . ]]; then
    cat <<EOF
${m}new file mode $new_mode
EOF
    path_a=/dev/null
    path_b="b/$new_path"
    index="index 0000000..${new_hex:0:7}"
elif [[ $new_hex = . ]]; then
    cat <<EOF
${m}deleted file mode $old_mode
EOF
    path_a="a/$path"
    path_b="/dev/null"
    index="index ${old_hex:0:7}..0000000"
elif [[ $old_mode = "$new_mode" ]]; then
    path_a="a/$path"
    path_b="b/$new_path"
    index="index ${old_hex:0:7}..${new_hex:0:7} $new_mode"
else
    cat <<EOF
${m}old mode $old_mode
${m}new mode $new_mode
EOF
    path_a="a/$path"
    path_b="b/$new_path"
    index="index ${old_hex:0:7}..${new_hex:0:7}"
fi

# In case of moves, the "index ..." line is part of $info
if [[ -n "$info" ]]; then
    index=""
    printf "%s" "$info" | sed "s/^/$m/"
fi

if [[ $(file -b "$old_file") = data && $(file -b "$new_file") = data ]]; then
    echo "Binary files $path_a and $path_b differ"
else
    # process the output of patdiff to:
    # - not displaying the index line if the output of patdiff is empty
    # - change the style of the "--- ..." and "+++ ..." lines
    "${BASH_SOURCE%/*}/patdiff" -alt-old " $path_a" -alt-new " $path_b" "$old_file" "$new_file" | \
        sed "1,2 s/^/$m/" | sed "1 s/^/$m$index"$'\\\n'"/"
    # git expect non-zero only in case of error. Patdiff, just like
    # diff, returns 1 if the files are different
    ret=${PIPESTATUS[0]}
    [ "$ret" -le 1 ] || exit "$ret"
fi
