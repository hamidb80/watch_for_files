import os, times,
  tables, json

type
  FilesLastEdit = Table[string, Time] # { path: lastEdit }

  ChangeFeedVariants = enum
    CFAdd, CFEdit, CFDelete

  ChangeFeed = object
    kind: ChangeFeedVariants
    path: string

  Tunnel = Channel[ChangeFeed]

# ------------------------------------------

proc listFilesImpl(storage: var FilesLastEdit, folder: string) =
  for finfo in walkDir folder:
    if finfo.kind == pcDir:
      listFilesImpl(storage, finfo.path)
    else:
      storage[finfo.path] = (getFileInfo finfo.path).lastWriteTime

proc listFiles(folder: string): FilesLastEdit {.inline.} =
  result.listFilesImpl(folder)


proc run(
  folder: string, tunnel: var Tunnel,
  timeout = 500, dbPath = "", save = false
) {.thread.} =

  var lastFilesInfo =
    if fileExists dbpath: parseJson(readfile dbPath).to FilesLastEdit
    else: FilesLastEdit()

  while true:
    let newFilesLastEdit = listFiles folder

    for path, time in newFilesLastEdit:
      if path in lastFilesInfo:
        if lastFilesInfo[path] != newFilesLastEdit[path]:
          tunnel.send ChangeFeed(path: path, kind: CFEdit)
          debugEcho path, " >> edited"

      else:
        tunnel.send ChangeFeed(path: path, kind: CFadd)
        debugEcho path, " >> created"

    for path, _ in lastFilesInfo:
      if path notin newFilesLastEdit:
        tunnel.send ChangeFeed(path: path, kind: CFdelete)
        debugEcho path, " >> deleted"

    lastFilesInfo = newFilesLastEdit

    if save:
      writefile dbpath, $ %lastfilesInfo

    sleep timeout

# --------------------------------------

when isMainModule:
  if paramCount() == 0:
    quit "no inp file"

  var ch: Tunnel
  ch.open

  run paramStr(1), ch
