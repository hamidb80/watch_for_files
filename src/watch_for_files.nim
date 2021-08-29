import os, times,
  tables, json

type
  FilesLastEdit* = Table[string, Time] # { path: lastEdit }

  ChangeFeedVariants* = enum
    CFAdd, CFEdit, CFDelete

  ChangeFeed* = object
    kind*: ChangeFeedVariants
    path*: string

# ------------------------------------------

proc initFilesEditsImpl(storage: var FilesLastEdit, folder: string) =
  for finfo in walkDir folder:
    if finfo.kind == pcDir:
      initFilesEditsImpl(storage, finfo.path)
    else:
      storage[finfo.path] = (getFileInfo finfo.path).lastWriteTime

proc initFilesEdits*(folder: string): FilesLastEdit {.inline.} =
  result.initFilesEditsImpl(folder)

type WorkerArgs* = object
  folder*: string 
  tunnel*: ref Channel[ChangeFeed] 
  active*: ref bool
  timeout*: int 
  dbPath*: string
  save*: bool

proc run*(args: WorkerArgs)=

  var lastFilesInfo =
    if fileExists args.dbpath: parseJson(readfile args.dbPath).to FilesLastEdit
    else: FilesLastEdit()

  while true:
    let newFilesLastEdit = initFilesEdits args.folder
    var anyUpdate = false

    template update(feed): untyped =
      anyUpdate = true
      echo "yo"
      args.tunnel[].send feed
      echo "me"

    for path, _ in lastFilesInfo:
      if path notin newFilesLastEdit:
        update ChangeFeed(path: path, kind: CFdelete)

    for path, time in newFilesLastEdit:
      if path in lastFilesInfo:
        if lastFilesInfo[path] != newFilesLastEdit[path]:
          update ChangeFeed(path: path, kind: CFEdit)
      else:
        update ChangeFeed(path: path, kind: CFadd)

    lastFilesInfo = newFilesLastEdit

    if args.save and anyUpdate:
      writefile args.dbpath, $ %lastfilesInfo

    if not args.active[]:
      break

    sleep args.timeout
