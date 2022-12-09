sed -i "s/N_IC_PREFETCH 2/N_IC_PREFETCH 3/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 3" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_3

sed -i "s/N_IC_PREFETCH 3/N_IC_PREFETCH 4/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 4" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_4

sed -i "s/N_IC_PREFETCH 4/N_IC_PREFETCH 5/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 5" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_5

sed -i "s/N_IC_PREFETCH 5/N_IC_PREFETCH 6/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 6" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_6

sed -i "s/N_IC_PREFETCH 6/N_IC_PREFETCH 7/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 7" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_7

sed -i "s/N_IC_PREFETCH 7/N_IC_PREFETCH 8/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 8" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_8

sed -i "s/N_IC_PREFETCH 8/N_IC_PREFETCH 12/g" sys_defs.svh
bash -x compare_copy.sh
python3 getcpi.py
mail -s "N_IC_PREFETCH 12" sumanthu@umich.edu < temp.txt
cp -r wb_saved wb_saved_pre_12