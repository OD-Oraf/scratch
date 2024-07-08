#!/bin/bash

#1 1) For the input file addr.txt, display all lines containing is.
function exersize_1 {
  awk '/is/ {print}' addr.txt
}

: '
2) For the input file addr.txt, display the first field of lines not containing y.
Consider space as the field separator for this file.
'
function exersize_2() {
    awk '!/y/ {print $1}' addr.txt
}

function exersize_3() {
    awk 'NF <= 2 {print $0}' addr.txt
}

exersize_3
