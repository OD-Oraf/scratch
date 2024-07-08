#!/bin/bash

#https://github.com/learnbyexample/learn_gnuawk/blob/master/exercises/Exercises.md



#Sum of a row
#awk '{sum += $2} END {print sum}' ../files/dept_mark.txt

#Format file by including colum names at the top
#awk -F"," 'BEGIN{printf "Col1\tCol2\tCol3\n"} {print $1"\t"$2"\t"$3} END{print "Done"}' ../files/data.txt

