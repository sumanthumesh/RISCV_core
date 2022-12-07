rm output_compare.txt
make clean
rm wb_saved/*
echo -e "\e[1;32mRunning *.s tests\e[0;37m"
for file in test_progs/*.s; do 
	sed -i "/SOURCE = test_progs/c SOURCE = $file" Makefile
	#sed -i "/SOURCE = test_progs/c SOURCE = $file" ~/Downloads/project-v-open/Makefile
	#echo -e "\e[1;32mAssembling $file in Out_Of_Order pipeline\e[0;37m"
	#make assembly SOURCE=${file}
	make assembly
	file=$(echo $file | cut -d'.' -f1)
	echo -e "\e[1;32mRunning $file in Out_Of_Order pipeline\e[0;37m"
	make 
	echo -e "\e[1;32mGenerating mem.out for $file in Out_Of_Order pipeline\e[0;37m"
	grep '@@@' program.out > mem.out
	#cd ~/Downloads/project-v-open/
	#echo -e "\e[1;32mAssembling $file in original pipeline\e[0;37m"
	#make assembly
	#echo -e "\e[1;32mRunning $file in original pipeline\e[0;37m"
	#make 
	#echo -e "\e[1;32mGenerating mem.out for $file in original pipeline\e[0;37m"
	#grep '@@@' program.out > mem.out
	#cd ~/Downloads/eecs470_grp7_f22/ 
	#fileArr=(${file~~/~})
	readarray -d / -t fileArr <<< "$file"
	test_name=$(echo "${fileArr[1]}" | sed 's/\n//')
	echo -e "\e[1;32mComparing writeback.out with ./ground_truths/writeback_${test_name}.out \e[0;37m"
	DIFF=$(diff writeback.out ./ground_truths/writeback_${test_name}.out)
	#echo $DIFF >> output_compare.txt
	if [[ $DIFF -eq "" ]]
	then
		echo -e "\e[1;32m$file test PASSED\e[0;37m" 
		echo "$file test PASSED" >> output_compare.txt
	else
		echo -e "\e[1;31m$file test FAILED\e[0;37m" 
		echo "$file test FAILED" >> output_compare.txt
		##echo $DIFF >> output_compare.txt
	fi
	mv writeback.out wb_saved/writeback_${test_name}.out
	
	grep '@@@' program.out > mem_actual.out
	grep '@@@' ground_truths/program_${test_name}.out > mem_expected.out
	echo -e "\e[1;32mComparing mem_actual.out with mem_expected.out \e[0;37m"
	DIFF=$(diff mem_actual.out mem_expected.out)
	if [[ $DIFF -eq "" ]]
	then
		echo -e "\e[1;32m$file test PASSED\e[0;37m" 
		echo "$file test PASSED" >> output_compare.txt
	else
		echo -e "\e[1;31m$file test FAILED\e[0;37m" 
		echo "$file test FAILED" >> output_compare.txt
		##echo $DIFF >> output_compare.txt
	fi
	mv program.out wb_saved/program_${test_name}.out


done
##echo -e "\e[1;32mRunning *.c tests\e[0;37m"
##for file in test_progs/*.c; do 
##	sed -i "/SOURCE = test_progs/c SOURCE = $file" Makefile
##	sed -i "/SOURCE = test_progs/c SOURCE = $file" ~/EECS470/project3_src_bkp/eecs470_project3_src_bkp/Makefile
##	file=$(echo $file | cut -d'.' -f1)
##	echo -e "\e[1;32mAssembling $file in Out_Of_Order pipeline\e[0;37m"
##	make program
##	echo -e "\e[1;32mRunning $file in Out_Of_Order pipeline\e[0;37m"
##	make  
##	echo -e "\e[1;32mGenerating mem.out for $file in Out_Of_Order pipeline\e[0;37m"
##	grep '@@@' syn_program.out > mem.out
##	cd ~/EECS470/project3_src_bkp/eecs470_project3_src_bkp/
##	echo -e "\e[1;32mAssembling $file in original pipeline\e[0;37m"
##	make program
##	echo -e "\e[1;32mRunning $file in original pipeline\e[0;37m"
##	make 
##	echo -e "\e[1;32mGenerating mem.out for $file in original pipeline\e[0;37m"
##	grep '@@@' program.out > mem.out
##	cd ~/EECS470/eecs470_grp7_f22/ 
##	echo -e "\e[1;32mComparing writeback.out files\e[0;37m"
##	if cmp -s "writeback.out" "~/EECS470/project3_src_bkp/eecs470_project3_src_bkp/writeback.out";
##	then
##		##if cmp -s "mem.out" "~/EECS470/project3_src_bkp/eecs470_project3_src_bkp/mem.out";
##		##then
##			echo -e "\e[1;32m$file test PASSED\e[0;37m" 
##			echo "$file test PASSED" >> output_compare.txt
##		##else
##		##	echo -e "\e[1;31m$file test FAILED\e[0;37m" 
##		##	echo "$file test FAILED" >> output_compare.txt
##		##fi
##	else
##		echo -e "\e[1;31m$file test FAILED\e[0;37m" 
##		echo "$file test FAILED" >> output_compare.txt
##	fi
##done
