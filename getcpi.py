import os
import csv

def print_cpi(cpi_data):
    for v in cpi_data:
        print(f"{v[0]}, {v[1]}")

c_progs = ['graph.c', 'sort_search.c', 'insertionsort.c', 'mergesort.c', 'backtrack.c', 'basic_malloc.c', 'omegalul.c', 'outer_product.c', 'quicksort.c', 'bfs.c', 'priority_queue.c', 'alexnet.c', 'fc_forward.c', 'dft.c', 'matrix_mult_rec.c']
s_progs = ['rv32_fib_long.s', 'rv32_copy.s', 'rv32_btest2.s', 'rv32_halt.s', 'rv32_btest1.s', 'rv32_mult.s', 'rv32_saxpy.s', 'rv32_evens_long.s', 'haha.s', 'rv32_fib.s', 'rv32_copy_long.s', 'mult_no_lsq.s', 'rv32_evens.s', 'sampler.s', 'rv32_insertion.s', 'rv32_parallel.s', 'rv32_fib_rec.s']



cpi_data_c = []
cpi_data_s = []
for name in s_progs:
    print(f"Checking program_{name[:-2]}.out")
    cpi_found = False
    if not os.path.exists(f"wb_saved/program_{name[:-2]}.out"):
        cpi_data_s.append([name,"NA"])
        continue
    with open(f"wb_saved/program_{name[:-2]}.out") as f:
        lines = f.readlines()
        for line in lines:
            if("CPI" in line):
                cpi_found = True
                words = line.split(' ')
                cpi_data_s.append([name,words[-2]])
    if not cpi_found:
        cpi_data_s.append([name,"NA"])
cpi_data_s=sorted(cpi_data_s,key=lambda l:l[0], reverse=False)
print("\n")
print_cpi(cpi_data_s)
for name in c_progs:
    print(f"Checking program_{name[:-2]}.out")
    cpi_found = False
    if not os.path.exists(f"wb_saved/program_{name[:-2]}.out"):
        cpi_data_c.append([name,"NA"])
        continue
    with open(f"wb_saved/program_{name[:-2]}.out") as f:
        lines = f.readlines()
        for line in lines:
            if("CPI" in line):
                cpi_found = True
                words = line.split(' ')
                cpi_data_c.append([name,words[-2]])
    if not cpi_found:
        cpi_data_c.append([name,"NA"])
#print(cpi_data_c)
#print(cpi_data_s)
cpi_data_c=sorted(cpi_data_c,key=lambda l:l[0], reverse=False)
print("\n")
print_cpi(cpi_data_c)

with open("temp.txt","w") as f:
    f.writelines("---------------\n")
    f.writelines(".s\n")
    f.writelines("---------------\n")
    for r in cpi_data_s:
        f.writelines(r[0]+'\n')
    f.writelines("---------------\n")
    f.writelines("CPI\n")
    f.writelines("---------------\n")
    for r in cpi_data_s:
        f.writelines(r[1]+'\n')
    f.writelines("---------------\n")
    f.writelines(".c\n")
    f.writelines("---------------\n")
    for r in cpi_data_c:
        f.writelines(r[0]+'\n')
    f.writelines("---------------\n")
    f.writelines("CPI\n")
    f.writelines("---------------\n")
    for r in cpi_data_c:
        f.writelines(r[1]+'\n')