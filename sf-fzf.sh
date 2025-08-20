#!/usr/bin/env bash

sf_fzf() {
	list_templates() {
		local search_dir="${PWD}"
		local directories=()
		while IFS= read -r -d '' dir; do
			directories+=("$dir")
		done < <(find "${search_dir}" -maxdepth 2 -mindepth 2 -type d -print0 2>/dev/null)

		local template_options=()
		for dir in "${directories[@]}"; do
			# Remove the search directory prefix to get relative path
			local rel_dir="${dir#${search_dir}/}"
			local top_dir="$(dirname "$rel_dir")"
			case "$top_dir" in
			reconciliation_texts | account_templates | shared_parts | export_files)
				local template=$(path_into_option_str "$rel_dir")
				template_options+=("$template")
				;;
			*)
				continue
				;;
			esac
		done

		printf '%s\n' "${template_options[@]}"
	}

	path_into_option_str() {
		local template_path="$1"
		template_path="${template_path#./}"
		local template_type_dir="${template_path%%/*}"
		case "$template_type_dir" in
		"reconciliation_texts") template_type_dir="reconciliation" ;;
		"account_templates") template_type_dir="account-template" ;;
		"shared_parts") template_type_dir="shared-part" ;;
		"export_files") template_type_dir="export-file" ;;
		esac
		echo "($template_type_dir) ${template_path#*/}"
	}

	select_templates() {
		local selected_templates
		selected_templates=$(list_templates)
		# Prompt the user to select a directory using fzf
		selected_templates=$(echo "$selected_templates" | fzf --prompt="Select a template:" --multi)
		# If user cancels or no selection is made, exit
		[[ -z "$selected_templates" ]] && return 1

		echo "$selected_templates"
	}

	check_sf_command() {
		local command="$1"

		if [[ -z "$command" ]]; then
			echo "Error: Command not provided."
			return 1
		fi
		case "$command" in
		create | update | import) ;;
		*)
			echo "Error: Invalid command. Valid commands are 'create', 'update', or 'import'."
			return 1
			;;
		esac
	}

	run_sf_command() {
		local command="$1"

		local selected_templates
		selected_templates=$(select_templates) || return 1

		# Check if selection is empty before processing
		[[ -z "$selected_templates" ]] && return 1

		# Convert the selected string into an array
		selected_templates_array=()
		while read -r item; do
			selected_templates_array+=("$item")
		done <<<"$selected_templates"

		for selected_dir in "${selected_templates_array[@]}"; do
			local template_type="${selected_dir#*(}"    # Remove the leading '('
			local template_type="${template_type%%)*}"  # Remove everything after the first ')'
			local template_handle="${selected_dir#*) }" # Remove everything up to and including the first ') '

			echo "silverfin get-${template_type}-id" "$template_handle"
			echo "silverfin ${command}-${template_type}" "$template_handle"
		done
	}

	# Entry point
	if [[ $# -eq 0 ]]; then
		# No arguments provided, select templates
		select_templates
	else
		check_sf_command "$1" || return 1
		# Arguments provided, treat the first argument as the command
		run_sf_command "$1"
	fi
}

sf_fzf "$@"
