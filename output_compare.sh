rm output_compare.txt
make clean
cd /home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/
make clean
cd /home/tarunkan/EECS470/eecs470_grp7_f22/ 
echo -e "\e[1;32mRunning *.s tests\e[0;37m"
for file in test_progs/*.s; do 
	sed -i "/SOURCE = test_progs/c SOURCE = $file" Makefile
	sed -i "/SOURCE = test_progs/c SOURCE = $file" /home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/Makefile
	file=$(echo $file | cut -d'.' -f1)
	echo -e "\e[1;32mAssembling $file in Out_Of_Order pipeline\e[0;37m"
	make assembly
	echo -e "\e[1;32mRunning $file in Out_Of_Order pipeline\e[0;37m"
	make 
	echo -e "\e[1;32mGenerating mem.out for $file in Out_Of_Order pipeline\e[0;37m"
	grep '@@@' syn_program.out > mem.out
	cd /home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/
	echo -e "\e[1;32mAssembling $file in original pipeline\e[0;37m"
	make assembly
	echo -e "\e[1;32mRunning $file in original pipeline\e[0;37m"
	make 
	echo -e "\e[1;32mGenerating mem.out for $file in original pipeline\e[0;37m"
	grep '@@@' program.out > mem.out
	cd /home/tarunkan/EECS470/eecs470_grp7_f22/ 
	echo -e "\e[1;32mComparing writeback.out files\e[0;37m"
	if cmp -s "writeback.out" "/home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/writeback.out";
	then
		##if cmp -s "mem.out" "/home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/mem.out";
		##then
			echo -e "\e[1;32m$file test PASSED\e[0;37m" 
			echo "$file test PASSED" >> output_compare.txt
		##else
		##	echo -e "\e[1;31m$file test FAILED\e[0;37m" 
		##	echo "$file test FAILED" >> output_compare.txt
		##fi
	else
		echo -e "\e[1;31m$file test FAILED\e[0;37m" 
		echo "$file test FAILED" >> output_compare.txt
	fi
done
##echo -e "\e[1;32mRunning *.c tests\e[0;37m"
##for file in test_progs/*.c; do 
##	sed -i "/SOURCE = test_progs/c SOURCE = $file" Makefile
##	sed -i "/SOURCE = test_progs/c SOURCE = $file" /home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/Makefile
##	file=$(echo $file | cut -d'.' -f1)
##	echo -e "\e[1;32mAssembling $file in Out_Of_Order pipeline\e[0;37m"
##	make program
##	echo -e "\e[1;32mRunning $file in Out_Of_Order pipeline\e[0;37m"
##	make  
##	echo -e "\e[1;32mGenerating mem.out for $file in Out_Of_Order pipeline\e[0;37m"
##	grep '@@@' syn_program.out > mem.out
##	cd /home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/
##	echo -e "\e[1;32mAssembling $file in original pipeline\e[0;37m"
##	make program
##	echo -e "\e[1;32mRunning $file in original pipeline\e[0;37m"
##	make 
##	echo -e "\e[1;32mGenerating mem.out for $file in original pipeline\e[0;37m"
##	grep '@@@' program.out > mem.out
##	cd /home/tarunkan/EECS470/eecs470_grp7_f22/ 
##	echo -e "\e[1;32mComparing writeback.out files\e[0;37m"
##	if cmp -s "writeback.out" "/home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/writeback.out";
##	then
##		##if cmp -s "mem.out" "/home/tarunkan/EECS470/project3_src_bkp/eecs470_project3_src_bkp/mem.out";
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
