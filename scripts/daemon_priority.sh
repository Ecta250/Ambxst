#!/usr/bin/env bash

# Kill notification daemons that may conflict
for daemon in dunst mako swaync; do
	if pgrep -x "$daemon" >/dev/null; then
		echo "Stopping $daemon..."
		pkill -x "$daemon"
	fi
done

# EasyEffects
if command -v easyeffects >/dev/null; then
	if ! pgrep -x easyeffects >/dev/null; then
		echo "Starting EasyEffects..."
		nohup easyeffects --gapplication-service >/dev/null 2>&1 &
	else
		echo "EasyEffects already running, skipping."
	fi
else
	echo "Warning: easyeffects not found in PATH"
fi
