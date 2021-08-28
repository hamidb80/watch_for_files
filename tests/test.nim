import unittest, os,
  tables, sequtils

import watch_for_files

func keysInTable[K, V](keys: openArray[string], t: Table[K, V]): bool =
  keys.allIt it in t
  

test "list files":
  check [
    "temp\\f1.txt",
    "temp\\f2.txt",
    "temp\\depth\\f3.txt",
  ].keysInTable initFilesEdits "./temp"
