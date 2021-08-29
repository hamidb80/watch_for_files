import unittest, os, threadpool, times,
  tables, sequtils, sets

import watch_for_files

func keysInTable[K, V](keys: openArray[string], t: Table[K, V]): bool =
  keys.allIt it in t

template repeatFor(timeout, delay: int, body: untyped): untyped =
  let startTime = getTime()

  while (getTime() - startTime).inMilliseconds < timeout:
    body
    sleep delay

# test "list files":
#   check [
#     "temp\\f1.txt",
#     "temp\\f2.txt",
#     "temp\\depth\\f3.txt",
#   ].keysInTable initFilesEdits "./temp"


# suite "change feed":
#   var
#     ch: ref Channel[ChangeFeed]
#     active: ref bool
    
#   new active
#   new ch
#   active[] = true

#   ch[].open

#   var t: Thread[WorkerArgs]
#   createThread(t, run, WorkerArgs(
#     folder:"./temp", 
#     tunnel: ch, 
#     active: active,
#     timeout: 500,
#     dbPath: "",
#     save: false
#   ))

#   test "file create":
#     writefile "./temp/f1.txt", ""
#     createDir "./temp/depth"
#     writefile "./temp/depth/f2.txt", ""

#     var changes: seq[ChangeFeed]

#     repeatFor 1000, 150:
#       let (available, feed) = ch[].tryRecv
#       if available:
#         changes.add feed

#     check (changes.mapIt it.path).toHashSet == [
#       ".\\temp\\f1.txt",
#       ".\\temp\\depth\\f2.txt",
#     ].toHashSet
#     echo changes

#   active[] = false
#   ch[].close
#   sync()


var
  ch: ref Channel[ChangeFeed]
  active: ref bool
  
new active
new ch
active[] = true

ch[].open

var t: Thread[WorkerArgs]
createThread(t, run, WorkerArgs(
  folder:"./temp", 
  tunnel: ch, 
  active: active,
  timeout: 500,
  dbPath: "",
  save: false
))

writefile "./temp/f1.txt", ""
createDir "./temp/depth"
writefile "./temp/depth/f2.txt", ""

var changes: seq[ChangeFeed]

repeatFor 1000, 150:
  let (available, feed) = ch[].tryRecv
  if available:
    changes.add feed

echo (changes.mapIt it.path)

active[] = false
ch[].close
sync()
