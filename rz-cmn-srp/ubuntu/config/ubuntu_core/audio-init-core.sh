#!/bin/bash
# Function to configure da7213 audio
set_config_da7213() {
	amixer -q cset name='Aux Switch' on
	amixer -q cset name='Mixin Left Aux Left Switch' on
	amixer -q cset name='Mixin Right Aux Right Switch' on
	amixer -q cset name='ADC Switch' on
	amixer -q cset name='Mixout Right Mixin Right Switch' off
	amixer -q cset name='Mixout Left Mixin Left Switch' off
	amixer -q cset name='Headphone Volume' 70%
	amixer -q cset name='Headphone Switch' on
	amixer -q cset name='Mixout Left DAC Left Switch' on
	amixer -q cset name='Mixout Right DAC Right Switch' on
	amixer -q cset name='DAC Left Source MUX' 'DAI Input Left'
	amixer -q cset name='DAC Right Source MUX' 'DAI Input Right'
	amixer -q sset 'Mic 1 Amp Source MUX' 'MIC_P'
	amixer -q sset 'Mic 2 Amp Source MUX' 'MIC_P'
	amixer -q sset 'Mixin Left Mic 1' on
	amixer -q sset 'Mixin Right Mic 2' on
	amixer -q sset 'Mic 1' 90% on
	amixer -q sset 'Mic 2' 90% on
	amixer -q sset 'Lineout' 80% on
	amixer -q set "Headphone" 100% on
	amixer -q set 'DVC In',0 10%
	amixer -q set 'Mixin PGA' 40% on
}

# Function to configure WM8978 audio
set_config_wm8978() {
	amixer -q set PCM 255
	amixer -q set "Headphone" 100% on
	amixer -q set "Speaker" 100% on
	amixer -q set 'L2/R2 Boost' 7
	amixer -q set 'Left Input Mixer L2' on
	amixer -q set 'Right Input Mixer R2' on
	amixer -q set 'Input PGA' 63
	amixer -q set 'PGA Boost (+20dB)' on
	amixer -q set 'Left Input Mixer MicN' off
	amixer -q set 'Right Input Mixer MicN' off
	amixer -q set 'ADC' 255
	amixer -q set 'ALC Enable' Both
	amixer -q set 'ALC Capture Target' 15
	amixer -q set 'ALC Capture Attack' 10
}

# Main function
main() {
	# Check if 'aplay' command is available
	if ! command -v aplay >/dev/null 2>&1; then
		echo "Warning: 'aplay' command not found, skipping audio device check"
		return 0
	fi

	# Get audio device name (content inside square brackets)
	DEVICE_NAME=$(aplay -l | grep -A 2 "^card 0:" | grep "device 0:" | awk -F' device 0: ' '{print $2}'|awk '{print $1}')

	# Check if device was not found
	if [ -z "$DEVICE_NAME" ]; then
		echo "Error: No audio device detected"
		return 0
	fi

	# If device was found
	case "$DEVICE_NAME" in
			*wm8978*)
				# WM8978 audio card detected
				set_config_wm8978
				;;
			*da7213*)
				# DA7213 audio card detected
				set_config_da7213
				;;
			*)
				# Other audio card detected
				# Do nothing
				;;
	esac
}

# Execute main function
main
