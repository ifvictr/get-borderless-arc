#!/bin/bash

ARC_PREFS_PATH=~/Library/Preferences/company.thebrowser.Browser.plist
FEATURE_FLAGS_KEY=com.launchDarkly.cachedUserEnvironmentFlags

PlistBuddy() {
	/usr/libexec/PlistBuddy "$@"
}

all_user_keys() {
	local output=$(PlistBuddy -c "Print $FEATURE_FLAGS_KEY" $ARC_PREFS_PATH | awk -F"= " '/^    [^ ]/ && !/}$/{print $1}')

	local keys=()
	while IFS= read -r line; do
		keys+=($line)
	done <<< "$output"

	echo ${keys[@]}
}

active_user_key() {
	local user_key

	local now=$(date -u +%s)
	local latest_update_at
	local keys=($(all_user_keys))
	for key in "${keys[@]}"; do
		local updated_at_iso=$(PlistBuddy -c "Print $FEATURE_FLAGS_KEY:$key:\lastUpdated" $ARC_PREFS_PATH)
		local updated_at=$(date -ujf "%Y-%m-%dT%H:%M:%SZ" "${updated_at_iso%.*}Z" +%s)

		# Use the first user to initialize values
		if [ $key == ${keys[0]} ]; then
			user_key=$key
			latest_update_at=$updated_at
			continue
		fi

		# If this user was updated more recently, save them
		if [ $(($now - $updated_at)) -lt $(($now - $latest_update_at)) ]; then
			user_key=$key
			latest_update_at=$updated_at
		fi
	done

	echo $user_key
}

mobile_key() {
	echo $(PlistBuddy -c "Print $FEATURE_FLAGS_KEY:$(active_user_key):environmentFlags" $ARC_PREFS_PATH | awk -F"= " '/^    [^ ]/ && !/}$/{print $1}')
}

echo "Started get-borderless-arc by ifvictr"

# Have the user close Arc if it's still open
pgrep -x Arc &> /dev/null
if [ $? -eq 0 ]; then
	read -p "Arc will need to be restarted to activate borderless mode. Press Return to continue…"

	killall Arc
	echo "│ Closed Arc"
fi

# Flush preferences cache first so our changes don't get overwritten
killall cfprefsd
echo "│ Flushed preferences cache"

# Enable the feature flag
PlistBuddy -c "Set $FEATURE_FLAGS_KEY:$(active_user_key):environmentFlags:$(mobile_key):featureFlags:hide-scrim-border-enabled:value YES" $ARC_PREFS_PATH
echo "│ Set feature flag hide-scrim-border-enabled to YES"

# Enable the feature itself
PlistBuddy -c "Set hideScrimBorderEnabled YES" $ARC_PREFS_PATH 2> /dev/null
if [ $? -ne 0 ]; then
	PlistBuddy -c "Add hideScrimBorderEnabled bool YES" $ARC_PREFS_PATH
	echo "│ Created a new entry for hideScrimBorderEnabled"
fi
echo "│ Set hideScrimBorderEnabled to YES"

open -a Arc
echo "│ Opened Arc"

echo "└ Done!"
echo
echo "**These changes will be reverted when Arc is closed, due to how it caches feature flags. When that happens, run this script again to reapply them.**"
