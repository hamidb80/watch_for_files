import unittest, os, threadpool, times,
  tables, sequtils, sets
import watch_for_files

# -------------------------------------------

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

# -------------------------------------------

suite "change feed":
  var
    ch: Channel[ChangeFeed]
    active = true
  ch.open
  spawn run("./temp", unsafeAddr ch, unsafeAddr active, 100)

  template getNewChanges: untyped {.dirty.} =
    var changes: seq[ChangeFeed]
    repeatFor 1000, 10:
      let (available, feed) = ch.tryRecv
      if available:
        changes.add feed

  test "file create":
    writefile "./temp/f1.txt", ""
    createDir "./temp/depth"
    writefile "./temp/depth/f2.txt", ""

    getNewChanges
    check changes.toHashSet == [
      ("temp\\f1.txt", CFcreate),
      ("temp\\depth\\f2.txt", CFcreate)
    ].toHashSet

  test "file rename":
    moveFile "./temp/f1.txt", "./temp/f1.moved"

    getNewChanges
    check changes.toHashSet == [
      ("temp\\f1.txt", CFdelete),
      ("temp\\f1.moved", CFcreate)
    ].toHashSet

  test "file edit":
    writefile "./temp/depth/f2.txt", "hey"

    getNewChanges
    check changes.toHashSet == [("temp\\depth\\f2.txt", CFedit)].toHashSet

  test "file delete":
    removeFile "./temp/f1.moved"
    removeFile "./temp/depth/f2.txt"
    removeDir "./temp/depth"

    getNewChanges
    check changes.toHashSet == [
      ("temp\\f1.moved", CFDelete),
      ("temp\\depth\\f2.txt", CFDelete)
    ].toHashSet


  active = false
  ch.close
  sync()
