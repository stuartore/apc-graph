#!/bin/bash

if [[ ! $(whereis graphviz) ]];then
	lsb_os=$(grep -o '^ID=.*$' /etc/os-release | cut -d'=' -f2)

	if [[ ${lsb_os} =~ "ubuntu" ]];then
		sudo apt install graphviz libxml2 -y
	elif [[ ${lsb_os} =~ "manjaro" ]] || [[ ${lsb_os} == "arch" ]];then
		sudo pacman -Sy graphviz libxml2 --noconfirm
	elif [[ ${lsb_os} =~ "fedora" ]];then
		sudo yum install -y graphviz libxml2
	elif [[ ${lsb_os} =~ "solus" ]];then
		sudo eopkg it graphviz libxml2
	fi
fi

# dot -Tpng test.txt -o test.png

str_to_arr(){
	OLD_IFS="$IFS"
	IFS="$2"
	str_to_arr_result=($1)
	IFS="$OLD_IFS"
}

recover_txt(){
	cat>test.txt<<EOF
digraph regexp { 
	#Generate
}
EOF
}
handle_routes(){
	route_list_arg0="$(xmllint --xpath '//audioPolicyConfiguration/modules/module/routes/route[@type="mix"]/@sink' audio_policy_configuration.xml | sed 's/"//g' | sed 's/ sink=//g' | sed ':a;N;$!ba;s/\n/!/g')"

	str_to_arr "${route_list_arg0}" '!'

	for route in "${str_to_arr_result[@]}"
	do
		cmd_get_route_source="xmllint --xpath 'string(//audioPolicyConfiguration/modules/module/routes/route[@sink=\"$route\"]/@sources)' audio_policy_configuration.xml"
		route_sources_str="$(eval $cmd_get_route_source)"

		echo "[$route]: ${route_sources_str}"

		str_to_arr "${route_sources_str}" ','
		for route_source in "${str_to_arr_result[@]}"
		do
			echo "$route_source -> $route"
			graphviz_new_line="\"$route_source\" -> \"$route\";"
			sed -i '/#Generate/a '"$graphviz_new_line"'' test.txt
			#echo "$route <- $route_source"
		done
		echo '-----------------'
	done
	dot -Tpng test.txt -o test.png
}

recover_txt
handle_routes
