import os, times,
  tables, json

type
  FilesLastEdit* = Table[string, Time] # { path: lastEdit }

  ChangeFeedVariants* = enum
    CFCreate, CFEdit, CFDelete

  ChangeFeed* = tuple
    path: string
    kind: ChangeFeedVariants

# ------------------------------------------

proc initFilesEditsImpl(storage: var FilesLastEdit, folder: string) =
  for finfo in walkDir folder:
    if finfo.kind == pcDir:
      initFilesEditsImpl(storage, finfo.path)
    else:
      storage[finfo.path] = (getFileInfo finfo.path).lastWriteTime

proc initFilesEdits*(folder: string): FilesLastEdit {.inline.} =
  result.initFilesEditsImpl(folder)

proc run*(
  folder: string, tunnel: ptr Channel[ChangeFeed], active: ptr bool,
  timeInterval: int, dbPath: string = "", save: bool = false
) =
  var lastFilesInfo =
    if fileExists dbpath: parseJson(readfile dbPath).to FilesLastEdit
    else: FilesLastEdit()

  while true:
    let newFilesLastEdit = initFilesEdits folder
    var anyUpdate = false

    template update(feed): untyped =
      anyUpdate = true
      tunnel[].send feed

    for path, time in lastFilesInfo:
      if path in newFilesLastEdit:
        if time != newFilesLastEdit[path]:
          update (path, CFEdit)
      else:
        update (path, CFdelete)

    for path, _ in newFilesLastEdit:
      if path notin lastFilesInfo:
        update (path, CFCreate)

    lastFilesInfo = newFilesLastEdit

    if save and anyUpdate:
      writefile dbpath, $ %lastfilesInfo

    if not active[]:
      break

    sleep timeInterval
