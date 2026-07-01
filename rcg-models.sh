#!/bin/bash
# List HuggingFace cached models with sizes and offer to delete them.
set -euo pipefail

HUB_DIR="${HF_HOME:-$HOME/.cache/huggingface}/hub"
[ -d "$HUB_DIR" ] || { echo "No HF cache at $HUB_DIR"; exit 0; }

mapfile -t entries < <(
    find "$HUB_DIR" -maxdepth 1 -mindepth 1 -type d -name 'models--*' \
        -exec du -sb {} \; | sort -rn
)
[ ${#entries[@]} -gt 0 ] || { echo "No models cached in $HUB_DIR"; exit 0; }

printf "\n%4s  %10s  %s\n" "#" "SIZE" "MODEL"
printf "%4s  %10s  %s\n" "----" "----------" "------------------------------"
total=0
for i in "${!entries[@]}"; do
    bytes=${entries[$i]%%$'\t'*}
    path=${entries[$i]#*$'\t'}
    name=$(basename "$path" | sed 's/^models--//; s/--/\//')
    printf "%4d  %10s  %s\n" "$((i+1))" "$(numfmt --to=iec --suffix=B "$bytes")" "$name"
    total=$((total + bytes))
done
printf "%4s  %10s  %s\n" "----" "----------" "------------------------------"
printf "%4s  %10s  %s\n\n" "" "$(numfmt --to=iec --suffix=B "$total")" "Total (${#entries[@]} models)"

read -rp "Delete which? (numbers, ranges like 1-3, 'all', or Enter to skip): " sel
[ -z "$sel" ] && exit 0

declare -a to_del
if [ "$sel" = "all" ]; then
    for e in "${entries[@]}"; do to_del+=("${e#*$'\t'}"); done
else
    for tok in $sel; do
        if [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
            for ((n=${BASH_REMATCH[1]}; n<=${BASH_REMATCH[2]}; n++)); do
                [ "$n" -ge 1 ] && [ "$n" -le ${#entries[@]} ] \
                    && to_del+=("${entries[$((n-1))]#*$'\t'}")
            done
        elif [[ $tok =~ ^[0-9]+$ ]] && [ "$tok" -ge 1 ] && [ "$tok" -le ${#entries[@]} ]; then
            to_del+=("${entries[$((tok-1))]#*$'\t'}")
        fi
    done
fi
[ ${#to_del[@]} -gt 0 ] || { echo "Nothing selected."; exit 0; }

echo
echo "Will delete:"
for p in "${to_del[@]}"; do
    printf "  %s  %s\n" \
        "$(du -sh "$p" | cut -f1)" \
        "$(basename "$p" | sed 's/^models--//; s/--/\//')"
done
read -rp "Confirm? [y/N] " yn
[[ $yn =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }

# Container may have written files as root — detect and escalate if needed
RM=(rm -rf --)
for p in "${to_del[@]}"; do
    if [ ! -O "$p" ] || find "$p" ! -user "$USER" -print -quit 2>/dev/null | grep -q .; then
        echo "Note: some files not owned by $USER (likely written by root inside container)."
        echo "Will use 'sudo rm -rf' for the deletes."
        RM=(sudo rm -rf --)
        break
    fi
done

for p in "${to_del[@]}"; do
    "${RM[@]}" "$p"
    echo "Deleted: $(basename "$p" | sed 's/^models--//; s/--/\//')"
done
