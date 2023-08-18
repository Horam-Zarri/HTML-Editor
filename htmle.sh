declare -a TAGS
FILE=""

function validate_input {
	if [[ -z "$FILE" ]]; then 
        	echo "No file specified."
        	exit 6
  	fi
  
  	if ! [[ -e "$FILE" && -r "$FILE" && -f "$FILE" ]]; then
		echo "The file specified either doesn't exist or does not have read access."
        	exit 7                                  
	fi                                              
                                                  
	if ! [[ "$FILE" =~ \.[hH][tT][mM][lL]$ ]]; then 
		echo "The specified file is not in HTML format."
        	exit 8
	fi

}

function extract_args {
	TAGS=($(cat "$FILE" | sed ':a;N;$!ba;s/\n/ /g' | grep -osP '<.*?>'))
}

function count_args {

	let local start_tags_count=0
	let local end_tags_count=0

	local -A start_tags
	local -A end_tags

	for (( i=0; i<${#TAGS[@]}; i++ )); do
		if [[ ${TAGS[$i]} != "<!"* ]]; then
			if [[ ${TAGS[$i]} == "</"* ]]; then
				let end_tags_count++
				tag=${TAGS[$i]}
				tag=${tag#<}
				tag=${tag%>}
				((end_tags[$tag]++))

			elif [[ ${TAGS[$i]} == "<"* ]]; then
				let start_tags_count++
				tag=${TAGS[$i]}
				tag=${tag#<}
				tag=${tag%>}
				((start_tags[$tag]++))
	
			fi
		fi
	done

	echo -e "\e[48;2;10;0;71m"

	echo -e "\n\n\n\e[38;2;255;68;153mStart Tags ---------------------------------\e[97m\n\nTotal: $start_tags_count\n"

	unset start_tags[0]
	unset end_tags[0]

	echo -e "\e[38;2;0;255;210m"

	for tag in "${!start_tags[@]}"; do
		echo $tag: "${start_tags[$tag]}"
	done

	echo -e "\n\n\n\e[38;2;255;68;153mEnd Tags -----------------------------------\e[97m\n\nTotal: $end_tags_count\n"

	echo -e "\e[38;2;0;255;210m"

	for tag in "${!end_tags[@]}"; do
		echo $tag: "${end_tags[$tag]}"
	done

	
	echo -e "\e[0m\n"
}

function edit_mode {

	local TMP="temp"$RANDOM$RANDOM".html"

	cp "$FILE" "$TMP"
	let line_count=$(wc -l "$TMP")

	local -a LINES
	mapfile -t LINES < "$TMP"

	
	tput clear
	cat "$TMP"
	echo -n '|'

	let local display_lines=$(tput lines)
	let display_lines-=5
	let local display_cols=$(tput cols)
	let display_cols-=10

	let ROW=0
	let COL=8
	let PAGE=0

	tput clear
	tput setab '10;0;71'
	tput setaf 2
	cat -n "$TMP" | head -n $display_lines
	tput cup 0 8
	tput setab '10;0;71'
	tput setaf 2


	while read -n1 char; do

		let local xs=$((ROW + 1))
		let xs+=$((display_lines * PAGE))
		let local ys=$((COL - 7))

		if [[ $char == $'\e' ]]; then
			read -rsn2 char 
  			case $char in 
				'[A') if [[ $ROW -gt 0 ]]; then 
					let ROW--
					let COL=8
				else 
					let PAGE--
					let ROW=$((display_lines - 1))
					let COL=8
					fi;;
				'[B')if [[ $((ROW + 1)) -ne $display_lines ]]; then
					let ROW++
					let COL=8
				else 
					let PAGE++
					let ROW=0
					let COL=8
					fi;;
				'[C')
					let local line_index=$((PAGE*display_lines+ROW))
					let local cols=$((6 + ${#LINES[$line_index]}))
					if [[ $COL -lt $cols ]]; then
						let COL++
					fi;;
    				'[D') if [[ $COL -gt 8 ]]; then
					let COL--
					fi;;
				'[3') ;;
    				*) exit 0;;
			esac
		else
			if [ $(printf "%d" \'$char) -eq 127 ]; then
				if [[ $COL -gt 7 ]]; then
					sed -i "${xs}s/.//${ys}" "$TMP"
					if [[ $COL -ne 8 ]]; then
						let COL--
					fi
				fi
			elif [ $(printf "%d" \'$char) -eq 14 ]; then
				sed -i "${xs} s/.\{${ys}\}/&\n/" "$TMP"
				let ROW++
				let COL=8
			elif [ $(printf "%d" \'$char) -eq 18 ]; then
				rm "$FILE"
				cp "$TMP" "$FILE"
				rm "$TMP"
				exit 0
			elif [ $(printf "%d" \'$char) -eq 15 ]; then
				rm "$TMP"
				exit 0
			elif [[ $char == "" ]]; then
				local whitespace=' '
				let local yss1=$((ys-1))
				sed -i "${xs} s/.\{${yss1}\}/&${whitespace}/" "$TMP"
				let COL++
			else
				if ! [[ $COL -eq $display_cols ]]; then
					let local yss2=$((ys-1))
					sed -i "${xs} s/.\{${yss2}\}/&${char}/" "$TMP"
					let COL++
				fi
			fi
		fi

		let local line_index=$((PAGE*display_lines+ROW))


		tput clear
		mapfile -t LINES < "$TMP" 
		let local pageplus=$((PAGE + 1))
		cat -n "$TMP" | head -n $((display_lines * $pageplus)) | tail -n $display_lines
		
		tput setab '10;0;71'
		tput setaf 2


		tput cup $ROW $COL
	done
}


let count_arg=0
let edit_arg=0

getopts 'ceh' OPTION


case $OPTION in 
	c) let count_arg=1;;
	e) let edit_arg=1;;
	h) echo -e "Usage: <Option> FILE\n\nOptions:\n  -c : Counts the HTML tags present in file\n  -e : Launch editor mode\n  -h : Help page (current)"
	exit 0;;
	?) echo -e "Usage: <Option> FILE\nUse -h for manuals"
	exit 55;;
esac


shift $((OPTIND - 1))
FILE="$1"

validate_input
extract_args

if [[ $count_arg -eq 1 ]]; then
	count_args
fi

if [[ $edit_arg -eq 1 ]]; then
	edit_mode
fi








