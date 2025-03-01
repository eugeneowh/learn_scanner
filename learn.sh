#! /bin/sh

#resetting variables
full=0
logs=logs.txt
target_port=-
wordlist=/usr/share/dirb/wordlists/common.txt

#getting flags
while getopts 't:p:l:u:fw:' flag
do
	case ${flag} in
		t) target_ip=${OPTARG};; #ip of target machine
		p) target_port=${OPTARG};; #port of target machine
		f) full=1;; #comprehensive scan (uses nmap -sC -sV -p- -T5)
		l) logs=${OPTARG};; #file to save all command logs to
		u) url=${OPTARG} ;; #specify url if ip addr is redirected
		w) wordlist=${OPTARG};; #specify wordlist to use for ffuf
		*) echo invalid flag ;;
	esac
done

echo target-ip: $target_ip
echo target-port: $target_port
echo full: $full
echo url: $url
echo saving files to $logs "\n"

#running nmap
echo ==================STARTING NMAP SCAN==================== "\n"
echo running nmap on $target_ip

if [ $full == 0 ]
	then #simple scan
		echo command: nmap -p$target_port $target_ip "\n" >> $logs #Command log
		nmap -p$target_port $target_ip 2>&1 | tee nmap_$target_ip
	else #full scan
		echo command: nmap -sC -sV -p$target_port -T5 $target_ip "\n" >> $logs #Command log
		nmap -sC -sV -p$target_port -T5 $target_ip 2>&1 | tee nmap_$target_ip
fi

echo nmap done

echo ==================CHECKING OPEN PORTS==================== "\n"

echo grep -i "open" nmap_$target_ip"\n" >> $logs #Command log
#filter out only open ports !!!Note that closed and filtered will not be checked
grep -i "open" nmap_$target_ip 2>&1 | tee open_ports_$target_ip 

echo ==================SCANNING EACH SERVICE==================== "\n"
#show each open port, and the service they are running
while read -r line; do
    port=$(echo $line | tr -s " " | cut -d"/" -f1)
    service=$(echo $line | tr -s " " | cut -d" " -f3)
	case $service in
		ftp)
		#do ftp scanning??
		echo hehe $port $service
		;;
		
		ssh)
		#do ssh scanning??
		echo good luck $port $service
		;;
		
		http)
		#do http scanning
  		#TODO check if user want to add url at this point after nmap (automate by inserting redirect url? -- need to ask user to add to /etc/hosts first)
  		#TODO do both subdomain fuzzing and directory fuzzing
		echo running ffuf http on $service with $wordlist
		echo url is $url
		[ $url=='' ] && addr=$target_ip || addr=$url
		echo $addr
		ffuf -u http://$url/FUZZ -w $wordlist || ffuf -u http://$target_ip/FUZZ -w $wordlist 2>&1 | tee ffuf_$target_ip
		;;

		https)
		#do http scanning
		echo running ffuf https on $service with $wordlist
		ffuf -u http://$url/FUZZ -w $wordlist || ffuf -u http://$target_ip/FUZZ -w $wordlist   2>&1 | tee ffuf_$target_ip
		;;
		
		*)
		#check service for new addition?
		echo ggnewshit idkkkkkkk $port $service
	esac
		
done < open_ports_$target_ip
