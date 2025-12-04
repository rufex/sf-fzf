#!/usr/bin/env bash

sf_fzf() {
	list_templates() {
		local filter_type="$1"
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
				# Filter by type if specified
				if [[ -n "$filter_type" ]]; then
					case "$filter_type" in
					"shared-parts-only")
						[[ "$top_dir" != "shared_parts" ]] && continue
						;;
					"exclude-shared-parts")
						[[ "$top_dir" == "shared_parts" ]] && continue
						;;
					esac
				fi
				local template
				template=$(path_into_option_str "$rel_dir")
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
		local prompt="${1:-Select a template:}"
		local filter_type="$2"
		local selected_templates
		selected_templates=$(list_templates "$filter_type")
		# Prompt the user to select a directory using fzf
		selected_templates=$(echo "$selected_templates" | fzf --prompt="$prompt" --multi)
		# If user cancels or no selection is made, exit
		[[ -z "$selected_templates" ]] && return 1

		echo "$selected_templates"
	}

	select_action() {
		local action
		action=$(printf "import\ncreate\nupdate\nadd-shared-part\nremove-shared-part\n" | fzf --prompt="Select an action:")
		[[ -z "$action" ]] && return 1
		echo "$action"
	}

	run_sf_command() {
		local command="$1"

		local selected_templates
		selected_templates=$(select_templates "Select templates:") || return 1

		# Return if no selection made
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

			local flag
			case "$template_type" in
			"reconciliation") flag="--handle" ;;
			"shared-part") flag="--shared-part" ;;
			"account-template" | "export-file") flag="--name" ;;
			esac

			silverfin "${command}"-"${template_type}" "$flag" "$template_handle"
		done
	}

	run_shared_part_operation() {
		local operation="$1"
		local action_verb="${2:-$operation}"

		# Step 1: Select shared parts
		local shared_parts
		shared_parts=$(select_templates "Select shared parts to ${action_verb}:" "shared-parts-only") || return 1

		# Check if selection is empty
		[[ -z "$shared_parts" ]] && return 1

		# Step 2: Select target templates (excluding shared parts)
		local target_templates
		target_templates=$(select_templates "Select target templates:" "exclude-shared-parts") || return 1

		# Check if selection is empty
		[[ -z "$target_templates" ]] && return 1

		# Convert shared parts to array
		shared_parts_array=()
		while read -r item; do
			shared_parts_array+=("$item")
		done <<<"$shared_parts"

		# Convert target templates to array
		target_templates_array=()
		while read -r item; do
			target_templates_array+=("$item")
		done <<<"$target_templates"

		# Execute operation for each combination
		for target in "${target_templates_array[@]}"; do
			local target_type="${target#*(}"
			local target_type="${target_type%%)*}"
			local target_handle="${target#*) }"

			local target_flag
			case "$target_type" in
			"reconciliation") target_flag="--handle" ;;
			"account-template") target_flag="--account-template" ;;
			"export-file") target_flag="--export-file" ;;
			esac

			for shared_part in "${shared_parts_array[@]}"; do
				local sp_handle="${shared_part#*) }"

				silverfin "${operation}" --shared-part "$sp_handle" "$target_flag" "$target_handle"
			done
		done
	}

	run_add_shared_part() {
		run_shared_part_operation "add-shared-part" "add"
	}

	run_remove_shared_part() {
		run_shared_part_operation "remove-shared-part" "remove"
	}

	# Entry point
	if [[ $# -eq 0 ]]; then
		# No arguments provided, show action menu
		local action
		action=$(select_action) || return 1

		case "$action" in
		import | create | update)
			run_sf_command "$action"
			;;
		add-shared-part)
			run_add_shared_part
			;;
		remove-shared-part)
			run_remove_shared_part
			;;
		esac
	else
		# Arguments provided, treat the first argument as the command
		local command="$1"
		case "$command" in
		import | create | update)
			run_sf_command "$command"
			;;
		add-shared-part)
			run_add_shared_part
			;;
		remove-shared-part)
			run_remove_shared_part
			;;
		*)
			echo "Error: Invalid command. Valid commands are 'import', 'create', 'update', 'add-shared-part', or 'remove-shared-part'."
			return 1
			;;
		esac
	fi
}

sf_fzf "$@"
