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

str_to_arr(){
	OLD_IFS="$IFS"
	IFS="$2"
	str_to_arr_result=($1)
	IFS="$OLD_IFS"
}

write_txt(){
	cat>${graphviz_name}.txt<<EOF
digraph regexp {
	rankdir=RL;
	node[shape=box,style=filled,color=lightblue,nodesep=4.0];
	graph [ overlap=false ];

	## map body
	${graphviz_lines_add}
}
EOF
}

handle_routes(){
	# audio_policy_configuration.xml
	adp_source=$1
	graphviz_name=$2
	if [[ ! $1 ]];then echo "[ - ] No input audio_policy_configuration.xml" && exit;fi
	if [[ $graphviz_name == "" ]];then graphviz_name='audio_graphviz';fi

	# Gnerate lines.txt
	cat>lines.txt<<LINESEOF
#Generated lines
LINESEOF

	route_list_arg0="$(xmllint --xpath '//audioPolicyConfiguration/modules/module/routes/route[@type="mix"]/@sink' $adp_source | sed 's/"//g' | sed 's/ sink=//g' | sed ':a;N;$!ba;s/\n/!/g')"

	str_to_arr "${route_list_arg0}" '!'

	for route in "${str_to_arr_result[@]}"
	do
		cmd_get_route_source="xmllint --xpath 'string(//audioPolicyConfiguration/modules/module/routes/route[@sink=\"$route\"]/@sources)' $adp_source"
		route_sources_str="$(eval $cmd_get_route_source)"

		#echo "[$route]: ${route_sources_str}"

		str_to_arr "${route_sources_str}" ','
		for route_source in "${str_to_arr_result[@]}"
		do
			#echo "$route_source -> $route"
			graphviz_new_line="\"$route_source\" -> \"$route\";"
			sed -i '$a '"$graphviz_new_line"'' lines.txt
			
			#echo "$route <- $route_source"
		done
		#echo '-----------------'
	done
	graphviz_lines_add="$(cat lines.txt | uniq)"
	write_txt
	rm -f lines.txt
	dot -Tpng ${graphviz_name}.txt -o ${graphviz_name}.png
	echo "[ + ] Generated at ${graphviz_name}.png "
}

handle_routes $1 $2
