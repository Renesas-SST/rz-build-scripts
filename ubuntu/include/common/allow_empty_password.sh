#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The script will allow user to ssh without password
# --------------------------------------------------------------------------#

: ${SSH_NO_PASS_LOGIN:=1}
# SSH server allows empty password user login
allow_empty_password_ssh() {
	if [ "$SSH_NO_PASS_LOGIN" -eq 1 ]; then
		if [[ ! -f "${ETC_PATH}/ssh/sshd_config" ]]; then
			echo "Configuration file ${ETC_PATH}/ssh/sshd_config not found"
			return 1
		else
			{
				echo "PermitRootLogin yes"
				echo "PasswordAuthentication yes"
				echo "PermitEmptyPasswords yes"
			} >> "${ETC_PATH}/ssh/sshd_config"
			echo "Now user can ssh to root and accounts with empty passwords."
		fi
	fi
	return 0
}