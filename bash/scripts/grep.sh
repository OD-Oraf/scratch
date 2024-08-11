#!/bin/bash

call_grep() {
  grep -Eir --color=auto "[A-Z]{2,4}$" ../
}


call_grep
